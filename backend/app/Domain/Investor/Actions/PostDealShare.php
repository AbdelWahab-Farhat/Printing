<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Queries\PeriodShares;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Collection;

/**
 * Writes one figure, already reduced to the investors' share, into their ledgers — and makes sure
 * it is the only figure standing for that source.
 *
 * **Extracted so two roads can share one hand on the ledger.** A deal earns in two entirely
 * different ways now — a delivered order's profit ({@see PostDealEarningsForOrder}) and the
 * margin the press pays when it buys plain stock off the shelf
 * ({@see PostDealStockPurchases}) — and each computes its own amount from its own facts. What
 * neither may own privately is *how a figure becomes rows*: the largest-remainder split across
 * shares, the idempotent comparison against what already stands, and the correction written as a
 * reversal plus a fresh sequence. Two copies of that is two behaviours the day somebody fixes one.
 *
 * **Idempotent by comparison rather than by hope.** The same source posted twice computes the
 * same figures and writes nothing the second time. A source whose figure has *changed* — a
 * restated line, an order re-delivered after an edit — reverses every standing row and writes
 * the new ones under the next sequence, so the ledger keeps both the wrong answer and its
 * correction, which is the rule every money table in this application follows.
 *
 * **And zero is a figure like any other.** A source whose amount has fallen to nothing — a
 * restated line that no longer draws on this deal, a correction that cancels the margin exactly —
 * reverses every standing row and writes none. Returning early on a zero would leave the first
 * payment standing for a source that owes nothing, which is the one shape of this bug that pays a
 * man for goods he still has on the shelf.
 *
 * The caller holds the deal's row lock; the partial unique index behind
 * `(investor, deal, source_type, source_id, source_sequence)` is the database's own backstop for
 * the day a future one forgets.
 */
final class PostDealShare
{
    public function __construct(
        private readonly PeriodForEntry $periodFor,
        private readonly PeriodShares $periodShares,
        private readonly FundDeal $fund,
    ) {}

    /**
     * @param  string  $investorsAmount  the investors' share, signed — negative is a loss
     * @param  string  $sourceType  an `AuditSubject` value: what produced this figure
     * @param  int  $sourceId  the id of that thing
     * @return list<InvestorWalletEntry>
     */
    public function __invoke(
        InvestorDeal $deal,
        string $investorsAmount,
        string $sourceType,
        int $sourceId,
        string $correctionNote,
    ): array {
        // **فترةُ المصدر لا فترةُ اللحظة** — الشريحة ٢. طلبيةُ ٢٨ سبتمبر التي تُسلَّم في ٢
        // أكتوبر ربحُها لسبتمبر، وهو نصُّ قرار المالك: «كل طلبية في سبتمبر هي ل سبتمبر». وتُقرأ
        // مرّةً للدفعة كلِّها: كلُّ صفوفها من مصدرٍ واحد، فلا فترةَ تختلف بينها. وهي كذلك ما
        // تُقرأ به نسبُ القسمة حين تكون الصفقةُ هي الصندوق.
        $periodId = $this->periodFor->bySource($sourceType, $sourceId);
        $weights = $this->weightsFor($deal, $periodId);

        if ($weights === []) {
            return [];
        }

        $amounts = Money::allocate($investorsAmount, array_values($weights));

        $standing = InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->whereIn('type', [WalletEntryType::Profit->value, WalletEntryType::Loss->value])
            ->whereDoesntHave('reversedBy')
            ->get()
            ->keyBy('investor_id');

        $target = [];

        foreach (array_keys($weights) as $index => $investorId) {
            $target[$investorId] = $amounts[$index] ?? '0.00';
        }

        if ($this->matches($standing, $target)) {
            return [];
        }

        $sequence = 1 + (int) InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->max('source_sequence');

        foreach ($standing as $entry) {
            $this->reverse($entry, $correctionNote);
        }

        $written = [];

        foreach ($target as $investorId => $amount) {
            if (bccomp($amount, '0', 2) === 0) {
                continue;
            }

            $isLoss = bccomp($amount, '0', 2) < 0;

            $entry = new InvestorWalletEntry([
                'amount' => $isLoss ? substr($amount, 1) : $amount,
                'occurred_at' => now(),
            ]);

            $entry->investor_id = $investorId;
            $entry->investor_deal_id = $deal->getKey();
            $entry->type = $isLoss ? WalletEntryType::Loss : WalletEntryType::Profit;
            $entry->source_type = $sourceType;
            $entry->source_id = $sourceId;
            $entry->source_sequence = $sequence;
            $entry->investment_period_id = $periodId;
            $entry->save();

            $written[] = $entry;
        }

        return $written;
    }

    /**
     * بأيّ نسبٍ يُقسَّم هذا المبلغ — وهما طريقان لا واحد.
     *
     * **الصندوق** يقسم بنسب **فترته** ({@see PeriodShares}): وحداتُ من كان شريكاً يوم أُغلقت
     * نافذةُ اكتتابها. وهو نصُّ ما طلبه المالك — «كل مستثمرين ونسبة الربح الحالية ونسبتهم
     * الحالية مربوطة بكل فترة» — ولا يمكن أن يأتي من `investor_deal_shares`: تلك صفوفٌ تُكتب
     * مرّةً وتجمُد، والصندوقُ يدخله ويخرج منه ناسٌ إلى الأبد.
     *
     * **والصفقةُ القديمة** تقسم بصفوفها كما قسمت دائماً. الطريقان يتعايشان: صفقاتُ ما قبل
     * الصندوق ما زالت تبيع بضاعتها على الرفّ، وتغييرُ قسمتها اليوم يعيد كتابة تاريخٍ اتُّفق عليه.
     *
     * ## وحين لا تكون للصفّ فترة
     *
     * يقع ذلك في يومٍ لا تسعه نافذةُ أيّ فترة — بين نهاية نافذةٍ مفتوحة وفتحِ التالية. فتُقرأ
     * نسبُ الفترة المفتوحة اليوم بدل أن يسقط المال: الفترةُ التي ستطالب بالصفّ عند إقفالها
     * غالباً هي التالية مباشرة، وحَمَلتُها هم هؤلاء إلا أن يدخل داخلٌ في نافذتها. والصفرُ — «لا
     * أحد» — كان سيُسقط ربحاً بلا أثرٍ في أيّ رصيد.
     *
     * @return array<int, string> المستثمر ← وزنُه في القسمة
     */
    private function weightsFor(InvestorDeal $deal, ?int $periodId): array
    {
        if ($this->fund->is($deal)) {
            $shares = $periodId === null ? [] : $this->periodShares->forPeriod($periodId);

            return $shares === [] ? $this->periodShares->current() : $shares;
        }

        $weights = [];

        foreach ($deal->shares()->get() as $share) {
            $weights[(int) $share->investor_id] = (string) $share->share_percent;
        }

        return $weights;
    }

    /**
     * @param  Collection<int, InvestorWalletEntry>  $standing
     * @param  array<int, string>  $target
     */
    private function matches($standing, array $target): bool
    {
        $current = [];

        foreach ($standing as $entry) {
            $signed = $entry->type === WalletEntryType::Loss
                ? '-'.$entry->amount
                : (string) $entry->amount;

            $current[(int) $entry->investor_id] = $signed;
        }

        $wanted = array_filter($target, fn (string $amount) => bccomp($amount, '0', 2) !== 0);

        if (array_keys($current) !== array_keys($wanted)) {
            return false;
        }

        foreach ($wanted as $investorId => $amount) {
            if (bccomp($current[$investorId], $amount, 2) !== 0) {
                return false;
            }
        }

        return true;
    }

    /**
     * The row that undoes another — in the period of the row it undoes, or today's if that one
     * has closed.
     *
     * A reversal must land where its original landed, or September keeps the wrong figure while
     * some other period carries a correction to a mistake it never made. But once September has
     * closed its money has left for people's pockets, and {@see PeriodForEntry::floorOf()} drops
     * the correction onto whatever is open today — which is what accounting does with a
     * prior-period correction everywhere.
     */
    private function reverse(InvestorWalletEntry $entry, string $note): void
    {
        $reversal = new InvestorWalletEntry([
            'amount' => (string) $entry->amount,
            'occurred_at' => now(),
            'notes' => $note,
        ]);

        $reversal->investor_id = $entry->investor_id;
        $reversal->investor_deal_id = $entry->investor_deal_id;
        $reversal->investment_period_id = $this->periodFor->floorOf(
            $entry->investment_period_id === null ? null : (int) $entry->investment_period_id
        );
        $reversal->type = WalletEntryType::Reversal;
        $reversal->reverses_entry_id = $entry->getKey();
        $reversal->save();
    }
}
