<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * ربحٌ يملكه المستثمرون ولم يصل جيوبَهم بعد — رقمُ اللوحة، والطلبياتُ التي صنعته.
 *
 * «الأرباح المستحقّة للمستثمرين عند الضغط عليها تظهر طلبيات وربح كل واحدة منها» — طلبُ المالك
 * 2026-09-24.
 *
 * ## الرقمُ نصفان، ولكلٍّ جوابُه
 *
 * - **لم يُفرَج عنه بعد** — ربحُ طلبياتٍ في فترةٍ لم تُقفَل، أو في فترةٍ «قيد الإغلاق» حجزت
 *   بوّابةُ التحصيل ربحَ ما لم يُدفع منها. هذا يُردّ إلى طلبياته طلبيةً طلبية، وتحت كلٍّ منها
 *   نصيبُ كلِّ شريك.
 * - **في المحافظ** — أُفرج عنه ولم يُسحب. **وهذا لا يُردّ إلى طلبية**: الإفراجُ صفٌّ واحد لفترةٍ
 *   كاملة والسحبُ مبلغٌ من المحفظة كلِّها، فأيُّ «طلبيةٍ» تُنسب إليها السبعون الباقية من مئة
 *   سحب صاحبُها ثلاثين منها؟ جوابٌ كهذا قسمةٌ نخترعها لا واقعةٌ في الدفتر، فيُقال لكلّ صاحبٍ
 *   رصيدُه.
 *
 * ## والتعريفُ واحد
 *
 * {@see FundValuation} يطرح هذا الرقمَ من قيمة الصندوق، وهو يقرؤه من {@see total()} هنا: مشيةٌ
 * واحدة على الدفتر بـ`deltas()`، والجيبُ السالب يُقصّ عند الصفر صاحباً صاحباً (§٠.٨) — فالقائمةُ
 * تجمع إلى رقم اللوحة لأنهما المشيةُ نفسُها.
 *
 * ## وكيف يُردّ جيبٌ إلى طلبياته
 *
 * جيبُ كلِّ مستثمرٍ في كلِّ صفقة يُفصَّل فترةً فترة ({@see explain()}):
 *
 * - فترةٌ **لم تُسوَّ** بعد — لا إفراجَ فيها ولا شطب — ما فيها كلُّه لم يُفرَج عنه: كلُّ ربحٍ
 *   وخسارةٍ بطلبيته أو مصروفه، وكلُّ خسارةٍ رُحِّلت إليها.
 * - فترةٌ **سُوّيت** — لا يبقى فيها إلا ما حجزته بوّابةُ التحصيل
 *   ({@see InvestorBalances::releasableInPeriod()}): ربحُ طلبيةٍ لم يُدفع ثمنُها كاملاً.
 *
 * وما لم يُفسَّر بهذا — وهو صفرٌ في الحال السويّة — يُكتب سطراً باسمه لا يُسقَط: قائمةٌ تنقص
 * عن رقمها قرشاً تفتح سؤالاً بدل أن تجيبه.
 */
final class FundProfitOwed
{
    /** أنواعٌ لا يكتبها إلا الإقفال: وجودُ أحدها في فترةٍ يعني أنها سُوّيت. */
    private const SETTLING = [
        WalletEntryType::ProfitRelease,
        WalletEntryType::CapitalWritedown,
        WalletEntryType::LossAbsorbedByCompany,
        WalletEntryType::LossCarriedOut,
    ];

    public function __construct(
        private readonly InvestorBalances $balances,
        private readonly PeriodOrdersQuery $periodOrders,
    ) {}

    /**
     * ما يدين به الصندوقُ لأصحابه ربحاً — ما تطرحه {@see FundValuation}.
     *
     * @param  int|null  $dealId  حين يُمرَّر، يُقرأ الجيبُ غيرُ المسوّى لتلك الصفقة وحدها؛
     *                            وجيبُ المحفظة كاملٌ دائماً، لأنه لا يسمّي صفقة
     */
    public function total(?int $dealId = null): string
    {
        $walk = $this->walk($dealId);

        return bcadd($this->positive($walk['pots']), $this->positive($walk['wallets']), 8);
    }

    /**
     * الرقمُ مفصَّلاً: ما لم يُفرَج عنه بطلبياته، وما في المحافظ بأصحابه.
     *
     * @return array{
     *     total: string,
     *     unreleased: array{total: string, orders: list<array<string, mixed>>, adjustments: list<array{kind: string, label: string, amount: string}>},
     *     in_wallets: array{total: string, investors: list<array{investor_id: int, name: string, amount: string}>}
     * }
     */
    public function __invoke(): array
    {
        $walk = $this->walk(null);

        $owedPots = array_filter($walk['pots'], fn (string $balance): bool => bccomp($balance, '0', 8) > 0);
        $owedEntries = [];

        foreach (array_keys($owedPots) as $key) {
            array_push($owedEntries, ...($walk['rows'][$key] ?? []));
        }

        $withheld = $this->balances->ordersNotCollected($owedEntries);
        $lines = [];

        foreach (array_keys($owedPots) as $key) {
            $investorId = (int) explode(':', (string) $key)[0];
            $byPeriod = [];

            foreach ($walk['rows'][$key] ?? [] as $entry) {
                $byPeriod[(int) ($entry->investment_period_id ?? 0)][] = $entry;
            }

            foreach ($byPeriod as $entries) {
                array_push($lines, ...$this->explain($investorId, $entries, $withheld));
            }
        }

        [$orders, $adjustments] = $this->grouped($lines);

        $unreleased = $this->positive($owedPots);
        $inWallets = $this->positive($walk['wallets']);

        return [
            'total' => Money::round(bcadd($unreleased, $inWallets, 8)),
            'unreleased' => [
                'total' => Money::round($unreleased),
                'orders' => $orders,
                'adjustments' => $adjustments,
            ],
            'in_wallets' => [
                'total' => Money::round($inWallets),
                'investors' => $this->wallets($walk['wallets']),
            ],
        ];
    }

    /**
     * المشيةُ الواحدة على الدفتر كلِّه: الجيبُ غيرُ المسوّى لكلّ صاحبٍ في كلّ صفقة، وجيبُ
     * المحفظة لكلّ صاحب، وصفوفُ كلِّ جيبٍ لمن يريد أن يفصّله.
     *
     * **الجيبُ المحدَّد يخصّ صفقته، وجيبُ المحفظة يخصّ الجميع.** صفُّ الإفراج يسمّي صفقتَه فيُنسب
     * إليها، وصفُّ السحب لا يسمّي شيئاً — فما دام في المحفظة محسوبٌ ديناً مهما كان مصدرُه. وهو
     * دقيقٌ في الحال المستقرّة (لا صفقةَ إلا الصندوق)، ويُبالغ قليلاً في دَين الصندوق ما دامت
     * صفقةٌ قديمةٌ لم تُصفَّ بعد — وهو الاتجاهُ الذي لا يظلم قائماً لصالح داخلٍ جديد.
     *
     * @return array{
     *     pots: array<string, string>,
     *     wallets: array<int, string>,
     *     rows: array<string, list<InvestorWalletEntry>>
     * }
     */
    private function walk(?int $dealId): array
    {
        $pots = [];
        $wallets = [];
        $rows = [];

        foreach (InvestorWalletEntry::query()->with('reversedEntry')->orderBy('id')->get() as $entry) {
            $deltas = $entry->deltas();
            $investorId = (int) $entry->investor_id;

            if ($dealId === null || (int) ($entry->investor_deal_id ?? 0) === $dealId) {
                $key = $investorId.':'.(int) ($entry->investor_deal_id ?? 0);
                $pots[$key] = bcadd($pots[$key] ?? '0', $deltas['profit_deal'], 8);

                if (bccomp($deltas['profit_deal'], '0', 8) !== 0) {
                    $rows[$key][] = $entry;
                }
            }

            $wallets[$investorId] = bcadd($wallets[$investorId] ?? '0', $deltas['profit_wallet'], 8);
        }

        return ['pots' => $pots, 'wallets' => $wallets, 'rows' => $rows];
    }

    /**
     * جمعُ الموجب وحده — §٠.٨: السالبُ مطالبةٌ على صاحبه لا تُحصَّل نقداً، فلا تُنقص الدَّين.
     *
     * @param  array<array-key, string>  $balances
     */
    private function positive(array $balances): string
    {
        $total = '0';

        foreach ($balances as $balance) {
            if (bccomp($balance, '0', 8) > 0) {
                $total = bcadd($total, $balance, 8);
            }
        }

        return $total;
    }

    /**
     * ما بقي في جيبٍ واحدٍ من فترةٍ واحدة، سطراً سطراً.
     *
     * @param  list<InvestorWalletEntry>  $entries
     * @param  array<int, true>  $withheld  طلبياتٌ لم يُدفع ثمنُها كاملاً
     * @return list<array{investor_id: int, kind: string, type: ?string, id: ?int, amount: string}>
     */
    private function explain(int $investorId, array $entries, array $withheld): array
    {
        $residual = '0';
        $settled = false;

        foreach ($entries as $entry) {
            $residual = bcadd($residual, $entry->deltas()['profit_deal'], 8);
            $settled = $settled || in_array($entry->effectiveType(), self::SETTLING, true);
        }

        if (bccomp($residual, '0', 8) === 0) {
            return [];
        }

        $lines = [];
        $explained = '0';

        foreach ($entries as $entry) {
            $type = $entry->effectiveType();
            [$sourceType, $sourceId] = $entry->effectiveSource();
            $isEarning = in_array($type, [WalletEntryType::Profit, WalletEntryType::Loss], true);

            $stillOwed = $settled
                ? $isEarning && $sourceType === AuditSubject::Order->value && isset($withheld[$sourceId])
                : $isEarning || $type === WalletEntryType::LossCarriedIn;

            if (! $stillOwed) {
                continue;
            }

            $amount = $entry->deltas()['profit_deal'];
            $explained = bcadd($explained, $amount, 8);

            $lines[] = [
                'investor_id' => $investorId,
                'kind' => $isEarning ? 'earning' : 'carried_loss',
                'type' => $isEarning ? $sourceType : null,
                'id' => $isEarning ? $sourceId : null,
                'amount' => $amount,
            ];
        }

        $unexplained = bcsub($residual, $explained, 8);

        if (bccomp($unexplained, '0', 8) !== 0) {
            $lines[] = ['investor_id' => $investorId, 'kind' => 'other', 'type' => null, 'id' => null, 'amount' => $unexplained];
        }

        return $lines;
    }

    /**
     * السطورُ كما تُرسم: الطلبياتُ ببطاقة الفترة نفسِها، وما سواها سطرٌ باسمه.
     *
     * @param  list<array{investor_id: int, kind: string, type: ?string, id: ?int, amount: string}>  $lines
     * @return array{0: list<array<string, mixed>>, 1: list<array{kind: string, label: string, amount: string}>}
     */
    private function grouped(array $lines): array
    {
        $sourced = array_values(array_filter(
            $lines,
            fn (array $line): bool => $line['kind'] === 'earning' && $line['type'] !== null && $line['id'] !== null,
        ));

        $orderOf = $sourced === [] ? [] : $this->periodOrders->ordersBehind($sourced);
        $expenseNames = $this->expenseNames($sourced);

        $perOrder = [];
        $adjustments = [];

        foreach ($lines as $line) {
            $orderId = $line['kind'] === 'earning'
                ? ($orderOf[(string) $line['type']][(int) $line['id']] ?? null)
                : null;

            if ($orderId !== null) {
                $perOrder[$orderId][$line['investor_id']] = bcadd(
                    $perOrder[$orderId][$line['investor_id']] ?? '0',
                    $line['amount'],
                    8,
                );

                continue;
            }

            [$kind, $key, $label] = match (true) {
                $line['type'] === AuditSubject::InvestorDealExpense->value && isset($expenseNames[$line['id']]) => [
                    'expense',
                    'expense:'.$line['id'],
                    'مصروف: '.$expenseNames[$line['id']],
                ],
                $line['kind'] === 'carried_loss' => ['carried_loss', 'carried_loss', WalletEntryType::LossCarriedIn->label()],
                default => ['other', 'other', 'تسويات أخرى'],
            };

            $adjustments[$key] ??= ['kind' => $kind, 'label' => $label, 'amount' => '0'];
            $adjustments[$key]['amount'] = bcadd($adjustments[$key]['amount'], $line['amount'], 8);
        }

        $orders = $this->existing($perOrder, $adjustments);

        $out = [];

        foreach ($adjustments as $adjustment) {
            $amount = Money::round($adjustment['amount']);

            if (bccomp($amount, '0', 2) !== 0) {
                $out[] = ['kind' => $adjustment['kind'], 'label' => $adjustment['label'], 'amount' => $amount];
            }
        }

        return [$orders, $out];
    }

    /**
     * صفوفُ الطلبيات القائمة — **وطلبيةٌ حُذفت لا يسقط مالُها**.
     *
     * {@see PeriodOrdersQuery::rows()} تُسقط طلبيةً لا تجدها، وهو صوابٌ هناك. وهنا مالُها ما زال
     * في الرقم، فيذهب إلى «تسويات أخرى» قبل أن تُبنى الصفوف، ولا ينقص المجموع.
     *
     * @param  array<int, array<int, string>>  $perOrder
     * @param  array<string, array{kind: string, label: string, amount: string}>  $adjustments
     * @return list<array<string, mixed>>
     */
    private function existing(array $perOrder, array &$adjustments): array
    {
        if ($perOrder === []) {
            return [];
        }

        $alive = DB::table('orders')
            ->whereIn('id', array_keys($perOrder))
            ->whereNull('deleted_at')
            ->pluck('id')
            ->map(fn ($id): int => (int) $id)
            ->flip()
            ->all();

        foreach ($perOrder as $orderId => $amounts) {
            if (isset($alive[$orderId])) {
                continue;
            }

            $adjustments['other'] ??= ['kind' => 'other', 'label' => 'تسويات أخرى', 'amount' => '0'];

            foreach ($amounts as $amount) {
                $adjustments['other']['amount'] = bcadd($adjustments['other']['amount'], $amount, 8);
            }

            unset($perOrder[$orderId]);
        }

        return $perOrder === [] ? [] : $this->periodOrders->rows($perOrder)['orders'];
    }

    /**
     * @param  list<array{investor_id: int, kind: string, type: ?string, id: ?int, amount: string}>  $sourced
     * @return array<int, string>
     */
    private function expenseNames(array $sourced): array
    {
        $ids = [];

        foreach ($sourced as $line) {
            if ($line['type'] === AuditSubject::InvestorDealExpense->value) {
                $ids[(int) $line['id']] = (int) $line['id'];
            }
        }

        if ($ids === []) {
            return [];
        }

        $names = [];

        foreach (DB::table('investor_deal_expenses')->whereIn('id', array_values($ids))->pluck('name', 'id') as $id => $name) {
            $names[(int) $id] = (string) $name;
        }

        return $names;
    }

    /**
     * ما في محفظة كلِّ صاحبٍ من ربحٍ لم يسحبه — الأكبرُ أوّلاً.
     *
     * @param  array<int, string>  $wallets
     * @return list<array{investor_id: int, name: string, amount: string}>
     */
    private function wallets(array $wallets): array
    {
        $owed = array_filter($wallets, fn (string $balance): bool => bccomp($balance, '0', 8) > 0);

        if ($owed === []) {
            return [];
        }

        $names = DB::table('investors')->whereIn('id', array_keys($owed))->pluck('name', 'id');
        $rows = [];

        foreach ($owed as $investorId => $balance) {
            $rows[] = [
                'investor_id' => (int) $investorId,
                'name' => (string) ($names[$investorId] ?? ''),
                'amount' => Money::round($balance),
            ];
        }

        usort($rows, fn (array $a, array $b): int => bccomp($b['amount'], $a['amount'], 2));

        return $rows;
    }
}
