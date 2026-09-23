<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * The four balances, walked from the ledger — the only place any of them is computed.
 *
 * There is no balance column anywhere in this feature, which is the standing rule of the schema
 * («الرصيد لا يُخزَّن») and the reason `orders.paid_amount` may only ever be written by one
 * action. A cached figure here could only ever disagree with the rows it summarises, and this is
 * precisely the table somebody will add up by hand.
 *
 * Every row is asked what it did through {@see InvestorWalletEntry::deltas()}, so a reversal is
 * a negation of the row it undoes and nothing here has to know that.
 */
final class InvestorBalances
{
    /** @var array{capital_wallet: string, capital_deal: string, profit_deal: string, profit_wallet: string} */
    private const ZERO = [
        'capital_wallet' => '0.00',
        'capital_deal' => '0.00',
        'profit_deal' => '0.00',
        'profit_wallet' => '0.00',
    ];

    /**
     * Every balance of one investor: the two wallet pots, and the two per-deal pots keyed by
     * deal id.
     *
     * One query and one walk rather than four aggregates: the rows are few per investor, and
     * summing them in PHP is what lets `deltas()` stay the single definition instead of being
     * restated as four SQL CASE expressions that can drift from it.
     *
     * @return array{
     *     wallet: array{capital: string, profit: string},
     *     deals: array<int, array{capital: string, profit: string}>
     * }
     */
    public function forInvestor(int $investorId): array
    {
        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investor_id', $investorId)
            ->get();

        $wallet = ['capital' => '0', 'profit' => '0'];
        $deals = [];

        foreach ($entries as $entry) {
            $deltas = $entry->deltas();

            $wallet['capital'] = bcadd($wallet['capital'], $deltas['capital_wallet'], 8);
            $wallet['profit'] = bcadd($wallet['profit'], $deltas['profit_wallet'], 8);

            $dealId = $entry->investor_deal_id;

            if ($dealId === null) {
                continue;
            }

            $deals[$dealId] ??= ['capital' => '0', 'profit' => '0'];
            $deals[$dealId]['capital'] = bcadd($deals[$dealId]['capital'], $deltas['capital_deal'], 8);
            $deals[$dealId]['profit'] = bcadd($deals[$dealId]['profit'], $deltas['profit_deal'], 8);
        }

        return [
            'wallet' => [
                'capital' => Money::round($wallet['capital']),
                'profit' => Money::round($wallet['profit']),
            ],
            // A loop rather than `array_map`, and it matters: `array_map` preserves *string*
            // keys and renumbers integer ones, so mapping over a map keyed by deal id silently
            // relabels deal 7 as deal 0. Every figure stays correct and lands against the wrong
            // deal — which is exactly the class of bug this table exists to make impossible.
            'deals' => $this->rounded($deals),
        ];
    }

    /**
     * The wallet-and-deal totals of a page of investors, in **one** query.
     *
     * What the register screen draws. The per-deal breakdown is deliberately not returned: a
     * list wants «كم ماله عندنا وكم ربح», and carrying fifty deal maps to draw two numbers is
     * work nobody asked for.
     *
     * **One query and one walk, not one per row.** The rows are few and `deltas()` stays the
     * single definition of what each type does — restating it as SQL CASE expressions is the one
     * thing this class exists to avoid, and it would drift from the enum the first time a type
     * is added.
     *
     * @param  list<int>  $investorIds
     * @return array<int, array{capital: string, profit: string, wallet_capital: string, wallet_profit: string}>
     */
    public function forInvestors(array $investorIds): array
    {
        if ($investorIds === []) {
            return [];
        }

        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->whereIn('investor_id', $investorIds)
            ->get();

        $totals = [];

        foreach ($investorIds as $id) {
            $totals[$id] = ['capital' => '0', 'profit' => '0', 'wallet_capital' => '0', 'wallet_profit' => '0'];
        }

        foreach ($entries as $entry) {
            $id = (int) $entry->investor_id;

            if (! isset($totals[$id])) {
                continue;
            }

            $deltas = $entry->deltas();

            // «رأس ماله عندنا» is both places his capital can be — in his wallet and committed
            // to deals — because from where he stands they are one sum he handed over. The two
            // are told apart on his own screen, where the distinction is the point.
            $totals[$id]['capital'] = bcadd(
                $totals[$id]['capital'],
                bcadd($deltas['capital_wallet'], $deltas['capital_deal'], 8),
                8,
            );
            $totals[$id]['profit'] = bcadd(
                $totals[$id]['profit'],
                bcadd($deltas['profit_wallet'], $deltas['profit_deal'], 8),
                8,
            );
            $totals[$id]['wallet_capital'] = bcadd($totals[$id]['wallet_capital'], $deltas['capital_wallet'], 8);
            $totals[$id]['wallet_profit'] = bcadd($totals[$id]['wallet_profit'], $deltas['profit_wallet'], 8);
        }

        return array_map(
            fn (array $pots): array => [
                'capital' => Money::round($pots['capital']),
                'profit' => Money::round($pots['profit']),
                'wallet_capital' => Money::round($pots['wallet_capital']),
                'wallet_profit' => Money::round($pots['wallet_profit']),
            ],
            $totals,
        );
    }

    /**
     * ما ربحه كلُّ مستثمر في كل صفقة **داخل فترةٍ واحدة** — ما يُفرَج عنه عند إقفالها.
     *
     * **ولماذا فترةً لا الدفترَ كلَّه.** الإقفالُ كان يُفرج عن كل ربحٍ موجبٍ في الدفتر بلا سؤالٍ
     * عن فترته، فإقفالُ سبتمبر في ١٥ أكتوبر كان يسلّم حَمَلةَ سبتمبر ربحَ طلبيةٍ من أكتوبر.
     * الشريحة ٢ من المواصفة، وهذه هي قراءتُها.
     *
     * والمشيُ بـ`deltas()` كبقيّة هذا الصنف: `profit_deal` وحده — `capital_writedown` يرفعه
     * و`profit_release` يخفضه، فإقفالٌ يُعاد لا يُفرج عمّا أُفرج عنه مرّة.
     *
     * @return array<int, array<int, string>> المستثمر ← الصفقة ← ربحُه فيها، بإشارته
     */
    public function profitInPeriod(int $periodId): array
    {
        $entries = $this->withoutFoldedDeals(InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investment_period_id', $periodId)
            ->whereNotNull('investor_deal_id'))
            ->get();

        $profit = [];

        foreach ($entries as $entry) {
            $investorId = (int) $entry->investor_id;
            $dealId = (int) $entry->investor_deal_id;

            $profit[$investorId][$dealId] = bcadd(
                $profit[$investorId][$dealId] ?? '0',
                $entry->deltas()['profit_deal'],
                8,
            );
        }

        // حلقتان لا `array_map`، للسبب المكتوب في `forInvestor()`: التعيينُ يُعيد ترقيم
        // المفاتيح الصحيحة، فيصير المستثمرُ ٧ مستثمراً ٠ وتقع أرقامُه كلُّها على غيره.
        $out = [];

        foreach ($profit as $investorId => $deals) {
            foreach ($deals as $dealId => $amount) {
                $out[$investorId][$dealId] = Money::round($amount);
            }
        }

        return $out;
    }

    /**
     * ما يجوز الإفراجُ عنه من ربح هذه الفترة اليوم — ببوّابة التحصيل.
     *
     * المواصفة: §٠.٨ — **بوّابتان لا واحدة**. انقضاءُ مدّة الفترة يفتح الأولى، وهذا يفحص
     * الثانية: «في حال انتهت الفترة التي فيها طلبية **وسُلّمت للزبون (Paid)**».
     *
     * ## ولماذا لا يكفي التسليم
     *
     * الربحُ يُقيَّد عند التسليم، ومالُه يدخل خزينةَ الصندوق عند **التحصيل**. فطلبيةٌ بالأجل
     * تصنع رقماً قابلاً للسحب بلا دينارٍ خلفه — و`RecordWalletEntry` لا يفحص الخزينة في سحب
     * الأرباح إطلاقاً، فيمرّ السحبُ وتصير خزينةُ الصندوق سالبة. البوّابةُ هنا تجعل ذلك
     * مستحيلاً بالبناء بدل أن يُضاف حارسٌ ثالث.
     *
     * ## والشرطُ رقمٌ لا زرّ
     *
     * `paid_amount >= grand_total` — الواقعةُ المالية لا حالةٌ يضغطها موظّف، **وهو الشرطُ
     * بعينه الذي تقيس به {@see FundValuation} المستحقّات**. فلا يخرج دينارٌ من بند «مبيعاتٌ لم
     * تُحصَّل» إلا وقد فُتحت له بوّابةُ السحب في اللحظة نفسها.
     *
     * ## وما لا طلبيةَ له يمرّ
     *
     * المصروفُ خرج مالُه فعلاً، وهامشُ المكينة قُبض يوم اشترت، وصفوفُ التسوية نفسُها لا مصدرَ
     * لها — فلا شيءَ من ذلك ينتظر تحصيلاً. والبوّابةُ للطلبيات وحدها.
     *
     * @return array<int, array<int, string>> المستثمر ← الصفقة ← ما يجوز الإفراج عنه، بإشارته
     */
    public function releasableInPeriod(int $periodId): array
    {
        $entries = $this->withoutFoldedDeals(InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investment_period_id', $periodId)
            ->whereNotNull('investor_deal_id'))
            ->get();

        $withheld = $this->ordersNotCollected($entries);
        $profit = [];

        foreach ($entries as $entry) {
            [$sourceType, $sourceId] = $entry->effectiveSource();

            if ($sourceType === AuditSubject::Order->value && isset($withheld[$sourceId])) {
                continue;
            }

            $investorId = (int) $entry->investor_id;
            $dealId = (int) $entry->investor_deal_id;

            $profit[$investorId][$dealId] = bcadd(
                $profit[$investorId][$dealId] ?? '0',
                $entry->deltas()['profit_deal'],
                8,
            );
        }

        $out = [];

        foreach ($profit as $investorId => $deals) {
            foreach ($deals as $dealId => $amount) {
                $out[$investorId][$dealId] = Money::round($amount);
            }
        }

        return $out;
    }

    /**
     * أيُّ الطلبيات وراء هذه الصفوف لم يصل مالُها بعد.
     *
     * استعلامٌ واحد لكلّ الصفوف لا واحدٌ لكلّ صفّ — والصفوفُ قليلةٌ في الفترة، والطلبياتُ
     * أقلُّ منها لأن طلبيةً واحدة تحمل صفَّ كلِّ مستثمر.
     *
     * @param  iterable<InvestorWalletEntry>  $entries
     * @return array<int, true>
     */
    private function ordersNotCollected(iterable $entries): array
    {
        $orderIds = [];

        foreach ($entries as $entry) {
            [$sourceType, $sourceId] = $entry->effectiveSource();

            if ($sourceType === AuditSubject::Order->value && $sourceId !== null) {
                $orderIds[$sourceId] = true;
            }
        }

        if ($orderIds === []) {
            return [];
        }

        $unpaid = DB::table('orders')
            ->whereIn('id', array_keys($orderIds))
            ->whereNull('deleted_at')
            ->whereColumn('paid_amount', '<', 'grand_total')
            ->pluck('id');

        $withheld = [];

        foreach ($unpaid as $id) {
            $withheld[(int) $id] = true;
        }

        return $withheld;
    }

    /**
     * **صفقةٌ دخلت الصندوق ليست من شأن فترة** — قاعدةٌ واحدة لقارئين: ما يُفرَج عنه
     * ({@see releasableInPeriod()}) وما يُرحَّل خسارةً ({@see profitInPeriod()}).
     *
     * `FoldDealIntoFund` يكتب في الصفقة القديمة صفَّ إفراجٍ لربحٍ صُنع قبل الصندوق. لو قرأته فترةٌ
     * لرأت ربحاً سالباً خرج مالُه — فرحّلت على صاحبه خسارةً وهمية بحجمه، ولأفرجت عن ربح الصفقة
     * المختوم بها مرّةً ثانية. والصفقةُ المعلَّمة تُسوّى بالتحويل ثم بإقفالها هي.
     *
     * @template TQuery of \Illuminate\Database\Eloquent\Builder
     *
     * @param  TQuery  $query
     * @return TQuery
     */
    private function withoutFoldedDeals($query)
    {
        return $query->whereNotIn(
            'investor_deal_id',
            DB::table('investor_deals')->whereNotNull('folded_into_fund_at')->select('id'),
        );
    }

    /**
     * One investor's standing in one deal.
     *
     * @return array{capital: string, profit: string}
     */
    public function forShare(int $investorId, int $dealId): array
    {
        return $this->forInvestor($investorId)['deals'][$dealId]
            ?? ['capital' => '0.00', 'profit' => '0.00'];
    }

    /**
     * What a whole deal holds and has earned, across everybody in it.
     *
     * @return array{capital: string, profit: string, per_investor: array<int, array{capital: string, profit: string}>}
     */
    public function forDeal(int $dealId): array
    {
        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investor_deal_id', $dealId)
            ->get();

        $capital = '0';
        $profit = '0';
        $perInvestor = [];

        foreach ($entries as $entry) {
            $deltas = $entry->deltas();

            $capital = bcadd($capital, $deltas['capital_deal'], 8);
            $profit = bcadd($profit, $deltas['profit_deal'], 8);

            $id = (int) $entry->investor_id;
            $perInvestor[$id] ??= ['capital' => '0', 'profit' => '0'];
            $perInvestor[$id]['capital'] = bcadd($perInvestor[$id]['capital'], $deltas['capital_deal'], 8);
            $perInvestor[$id]['profit'] = bcadd($perInvestor[$id]['profit'], $deltas['profit_deal'], 8);
        }

        return [
            'capital' => Money::round($capital),
            'profit' => Money::round($profit),
            'per_investor' => $this->rounded($perInvestor),
        ];
    }

    /**
     * Rounds a map of pots, keeping whatever it is keyed by — see the note in `forInvestor()`.
     *
     * @param  array<int, array{capital: string, profit: string}>  $pots
     * @return array<int, array{capital: string, profit: string}>
     */
    private function rounded(array $pots): array
    {
        $out = [];

        foreach ($pots as $key => $value) {
            $out[$key] = [
                'capital' => Money::round($value['capital']),
                'profit' => Money::round($value['profit']),
            ];
        }

        return $out;
    }

    /**
     * @return array{capital_wallet: string, capital_deal: string, profit_deal: string, profit_wallet: string}
     */
    public static function zero(): array
    {
        return self::ZERO;
    }
}
