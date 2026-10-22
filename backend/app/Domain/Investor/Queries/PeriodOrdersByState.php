<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\ProfitSourceState;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * طلبياتُ الفترة وأين ربحُ كلٍّ منها — «أيُّها استُلم ربحُه وكم، وأيُّها ينتظر».
 *
 * المواصفة: §١١ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * ## فوق {@see PeriodOrdersQuery} لا داخلها
 *
 * تلك يقرؤها {@see FundProfitOwed} فيقرؤها الإقفالُ من طريق {@see FundValuation}، وهذه تحتاج
 * {@see ProfitAwaitingDelivery} الذي يحمل خدمةَ الطلبيات كلَّها — فلو نزلت هناك لأغلقت حلقة.
 * فصفوفُها وأرقامُها كما هي، وهذه تضيف إليها حالَها، وتقرؤها الشاشةُ وحدها.
 *
 * ## الحالُ من البوّابتين نفسَيهما
 *
 * كلُّ صفٍّ في الدفتر يُسأل: أيَّ بوّابةٍ اجتاز؟ ({@see gateOf()}) — مفتوحةٌ لم يحن موعدُها،
 * ومغلقةٌ لم يبقَ فيها ما يُحجز، وبينهما «قيد الإغلاق» تحجز ربحَ ما لم يُدفع ثمنُه بالشرط الذي
 * يحجز به الإقفالُ نفسُه ({@see InvestorBalances::ordersNotCollected()}).
 *
 * **والمبلغُ بالصفّ لا بالطلبية.** هامشُ السادة لا تمرّ عليه بوّابةُ التحصيل، فطلبيةٌ واحدة قد
 * يكون بعضُ ربحها في المحافظ وبعضُه محجوزاً — فلكلّ طلبيةٍ مبلغُ كلّ حالة، ومجموعُ الثلاثة التي
 * من الدفتر هو `investors_total` بالبناء.
 *
 * ## و«قيد التسليم» ما ينتظر المستثمرون ربحَه من التسليم
 *
 * طلبياتُ الفترة التي سحبت من رفّ الصندوق ولم تُسلَّم، **إلا ما اشترته المطبعةُ كلَّه بسعر
 * السادة** ({@see PeriodOrderIds::owingDeliveryProfitAmong()}): ذاك قُبض هامشُه يومَ غادر الرفّ،
 * ولا يأتي المستثمرين منه بالتسليم شيء. ورقمُها من {@see ProfitAwaitingDelivery} لما بلغ «جاهزة»، وما
 * دونها يُعدّ ولا يُسعَّر (§١٢أ). **والمغلقةُ لا تعرضها**: لا تُغلق وفيها شيءٌ إلا بتجاوز، وربحُ ما
 * يصل بعد ذلك لا يقع فيها.
 */
final class PeriodOrdersByState
{
    /** حالاتُ الدفتر، بترتيب أبعدِها عن الجيب — وهو ما تُختار به حالةُ الطلبية. */
    private const LEDGER = [
        ProfitSourceState::AwaitingPayment,
        ProfitSourceState::AwaitingPeriodEnd,
        ProfitSourceState::Released,
    ];

    public function __construct(
        private readonly PeriodOrdersQuery $orders,
        private readonly PeriodOrderIds $periodOrders,
        private readonly InvestorBalances $balances,
        private readonly ProfitAwaitingDelivery $awaitingDelivery,
    ) {}

    /**
     * @return array{
     *     orders: list<array<string, mixed>>,
     *     investors: list<array<string, mixed>>,
     *     totals: array<string, mixed>
     * }
     */
    public function __invoke(InvestmentPeriod $period): array
    {
        $sourced = $this->orders->sourced((int) $period->getKey());
        $orderOf = $sourced === [] ? [] : $this->orders->ordersBehind($sourced);

        // ما سيحجزه الإقفالُ أو يحجزه الآن: ربحٌ مصدرُه الطلبيةُ نفسُها ولم يُدفع ثمنُها.
        $unpaid = $this->balances->ordersNotCollected(array_column($sourced, 'entry'));

        $perOrder = [];
        $parts = [];

        foreach ($sourced as $row) {
            $orderId = $orderOf[$row['type']][$row['id']] ?? null;

            if ($orderId === null) {
                continue;
            }

            $investorId = $row['investor_id'];
            $state = $this->gateOf($period->status, $row['type'], $row['id'], $unpaid)->value;

            $perOrder[$orderId][$investorId] = bcadd($perOrder[$orderId][$investorId] ?? '0', $row['amount'], 8);
            $parts[$orderId][$state][$investorId] = bcadd($parts[$orderId][$state][$investorId] ?? '0', $row['amount'], 8);
        }

        $inFlight = $period->status === PeriodStatus::Closed
            ? []
            : $this->periodOrders->owingDeliveryProfitAmong($this->periodOrders->of($period));

        $expected = [];

        foreach ($inFlight as $orderId) {
            $expected[$orderId] = $this->awaitingDelivery->ofOrder($orderId);
        }

        $base = $this->orders->rows($perOrder, $inFlight);
        $names = $this->namesOf($parts, $expected, $base['investors']);

        $rows = [];

        foreach ($base['orders'] as $row) {
            $rows[] = $this->decorated(
                $row,
                $parts[$row['order_id']] ?? [],
                array_key_exists($row['order_id'], $expected),
                $expected[$row['order_id']] ?? null,
                isset($unpaid[$row['order_id']]),
                $period->status,
                $names,
            );
        }

        return [
            'orders' => $rows,
            'investors' => $this->perInvestor($base['investors'], $parts, $expected, $names),
            'totals' => [
                // «من كم طلبيةٍ جاء ربحُ المستثمرين» — ما في الدفتر وحده، كما كان.
                'orders' => count(array_filter($rows, fn (array $row): bool => $row['investors'] !== [])),
                'investors_total' => $base['totals']['investors_total'],
                'by_state' => $this->totalsByState($rows),
            ],
        ];
    }

    /**
     * أيَّ بوّابةٍ اجتاز صفٌّ واحد — القاعدةُ التي يُفرج بها الإقفالُ نفسُه.
     *
     * {@see InvestorBalances::releasableInPeriod()} يُفرج في «قيد الإغلاق» عن كلّ صفٍّ إلا ربحَ
     * طلبيةٍ لم يُدفع ثمنُها؛ والمغلقةُ «لم يبقَ فيها شيء» بتعريفها.
     *
     * @param  array<int, true>  $unpaid
     */
    private function gateOf(PeriodStatus $status, string $sourceType, int $sourceId, array $unpaid): ProfitSourceState
    {
        return ProfitSourceState::ofLedgerRow(
            $status,
            $sourceType === AuditSubject::Order->value && isset($unpaid[$sourceId]),
        );
    }

    /**
     * صفُّ الطلبية كما كان، ومعه أين ربحُه.
     *
     * - `profit_state` — الحالةُ على البطاقة: الطريقُ أوّلاً، ثم أبعدُ أجزاء الدفتر عن الجيب.
     * - `states` — كلُّ حالةٍ لها فيها شيء: ما تصفّي به الشاشة، فتجمع الطلبياتُ تحت مرشّحٍ إلى
     *   رقمه في `totals.by_state`.
     * - `by_state` — مبلغُ كلّ حالة، و`awaiting_delivery` `null` ما لم يُسعَّر.
     * - `uncollected` — سيُحجز ربحُها عند الإقفال ما لم يُدفع: «غير محصّلة» تحت الحالة.
     *
     * @param  array<string, array<int, string>>  $parts
     * @param  array<int, string>|null  $expected
     * @param  array<int, string>  $names
     * @return array<string, mixed>
     */
    private function decorated(
        array $row,
        array $parts,
        bool $inFlight,
        ?array $expected,
        bool $unpaid,
        PeriodStatus $status,
        array $names,
    ): array {
        $byState = [];
        $states = [];

        foreach (self::LEDGER as $state) {
            $amount = Money::round($this->sum($parts[$state->value] ?? []));
            $byState[$state->value] = $amount;

            if (bccomp($amount, '0', 2) !== 0) {
                $states[] = $state;
            }
        }

        $byState[ProfitSourceState::AwaitingDelivery->value] = $inFlight && $expected !== null
            ? Money::round($this->sum($expected))
            : null;

        if ($inFlight) {
            array_unshift($states, ProfitSourceState::AwaitingDelivery);
        }

        // طلبيةٌ تعادلت أجزاؤها ولم تُسقطها الصفوف: حالُها حالُ فترتها.
        $primary = $states[0] ?? ($status === PeriodStatus::Open
            ? ProfitSourceState::AwaitingPeriodEnd
            : ProfitSourceState::Released);

        return [
            ...$row,
            'profit_state' => $primary->value,
            'profit_state_label' => $primary->label(),
            'states' => array_map(fn (ProfitSourceState $state): string => $state->value, $states),
            'by_state' => $byState,
            'uncollected' => $unpaid,
            'expected_investors' => $this->shares($expected ?? [], $names),
        ];
    }

    /**
     * عددُ الطلبيات ومبلغُها تحت كلّ حالة — مشيُ الصفوف المرسومة نفسِها.
     *
     * **ومجموعُ الثلاثة التي من الدفتر = `investors_total`**: كلُّ صفٍّ وقع تحت حالةٍ واحدة.
     * و«قيد التسليم» محسوبٌ لا مقيَّد، فيقف خارج ذلك المجموع، ويُعدّ معه ما لم يُسعَّر بعد.
     *
     * @param  list<array<string, mixed>>  $rows
     * @return array<string, array<string, int|string>>
     */
    private function totalsByState(array $rows): array
    {
        $totals = [];

        foreach (ProfitSourceState::inAPeriod() as $state) {
            $totals[$state->value] = ['orders' => 0, 'amount' => '0'];
        }

        $totals[ProfitSourceState::AwaitingDelivery->value]['unpriced'] = 0;

        foreach ($rows as $row) {
            foreach ($row['states'] as $state) {
                $totals[$state]['orders']++;

                $amount = $row['by_state'][$state];

                if ($amount === null) {
                    $totals[$state]['unpriced']++;

                    continue;
                }

                $totals[$state]['amount'] = bcadd((string) $totals[$state]['amount'], $amount, 2);
            }
        }

        foreach ($totals as $state => $total) {
            $totals[$state]['amount'] = Money::round((string) $total['amount']);
        }

        return $totals;
    }

    /**
     * كلُّ شريكٍ في الفترة: ما أخذه منها، وكم منه في محفظته، وكم ينتظر، وكم في الطريق.
     *
     * `amount` هو ما كان، من {@see PeriodOrdersQuery}؛ والباقي قسمتُه بالبوّابات. ومن لا شيءَ له
     * إلا في الطريق يُكتب كذلك — هو شريكٌ في الفترة سيصله ربحٌ منها.
     *
     * @param  list<array{investor_id: int, name: string, amount: string}>  $ledger
     * @param  array<int, array<string, array<int, string>>>  $parts
     * @param  array<int, array<int, string>|null>  $expected
     * @param  array<int, string>  $names
     * @return list<array<string, mixed>>
     */
    private function perInvestor(array $ledger, array $parts, array $expected, array $names): array
    {
        $released = [];
        $pending = [];
        $coming = [];

        foreach ($parts as $states) {
            foreach ($states as $state => $amounts) {
                foreach ($amounts as $investorId => $amount) {
                    if ($state === ProfitSourceState::Released->value) {
                        $released[$investorId] = bcadd($released[$investorId] ?? '0', $amount, 8);
                    } else {
                        $pending[$investorId] = bcadd($pending[$investorId] ?? '0', $amount, 8);
                    }
                }
            }
        }

        foreach ($expected as $amounts) {
            foreach ($amounts ?? [] as $investorId => $amount) {
                $coming[$investorId] = bcadd($coming[$investorId] ?? '0', $amount, 8);
            }
        }

        $taken = [];

        foreach ($ledger as $share) {
            $taken[$share['investor_id']] = $share['amount'];
        }

        $rows = [];

        foreach (array_unique([...array_keys($taken), ...array_keys($released), ...array_keys($pending), ...array_keys($coming)]) as $investorId) {
            $row = [
                'investor_id' => (int) $investorId,
                'name' => $names[$investorId] ?? '',
                'amount' => $taken[$investorId] ?? '0.00',
                'released' => Money::round($released[$investorId] ?? '0'),
                'pending' => Money::round($pending[$investorId] ?? '0'),
                'expected' => Money::round($coming[$investorId] ?? '0'),
            ];

            if ($row['amount'] === '0.00' && $row['released'] === '0.00' && $row['pending'] === '0.00' && $row['expected'] === '0.00') {
                continue;
            }

            $rows[] = $row;
        }

        usort($rows, fn (array $a, array $b): int => bccomp($b['amount'], $a['amount'], 2)
            ?: bccomp($b['expected'], $a['expected'], 2));

        return $rows;
    }

    /**
     * @param  array<int, string>  $amounts
     * @param  array<int, string>  $names
     * @return list<array{investor_id: int, name: string, amount: string}>
     */
    private function shares(array $amounts, array $names): array
    {
        $shares = [];

        foreach ($amounts as $investorId => $amount) {
            $rounded = Money::round($amount);

            if (bccomp($rounded, '0', 2) === 0) {
                continue;
            }

            $shares[] = ['investor_id' => (int) $investorId, 'name' => $names[$investorId] ?? '', 'amount' => $rounded];
        }

        usort($shares, fn (array $a, array $b): int => bccomp($b['amount'], $a['amount'], 2));

        return $shares;
    }

    /**
     * أسماءُ كلِّ من في القسمة — ومن أخذ من الدفتر فاسمُه معه أصلاً، فلا يُسأل عنه ثانية.
     *
     * @param  array<int, array<string, array<int, string>>>  $parts
     * @param  array<int, array<int, string>|null>  $expected
     * @param  list<array{investor_id: int, name: string, amount: string}>  $ledger
     * @return array<int, string>
     */
    private function namesOf(array $parts, array $expected, array $ledger): array
    {
        $names = [];

        foreach ($ledger as $share) {
            $names[$share['investor_id']] = $share['name'];
        }

        $missing = [];
        $groups = [...array_values($expected)];

        foreach ($parts as $states) {
            array_push($groups, ...array_values($states));
        }

        foreach ($groups as $amounts) {
            foreach (array_keys($amounts ?? []) as $investorId) {
                if (! isset($names[$investorId])) {
                    $missing[$investorId] = $investorId;
                }
            }
        }

        if ($missing !== []) {
            foreach (DB::table('investors')->whereIn('id', array_values($missing))->pluck('name', 'id') as $id => $name) {
                $names[(int) $id] = (string) $name;
            }
        }

        return $names;
    }

    /**
     * @param  array<int, string>  $amounts
     */
    private function sum(array $amounts): string
    {
        $total = '0';

        foreach ($amounts as $amount) {
            $total = bcadd($total, $amount, 8);
        }

        return $total;
    }
}
