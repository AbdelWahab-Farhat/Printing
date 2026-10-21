<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\ProfitSourceState;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * «مصدر الربح» — من أين جاء كلُّ رقمٍ من بوّابات ربحه الثلاث.
 *
 * ```
 * قيد التسليم   →  معلّقة         →  متاحة للسحب
 * طلبياتٌ محسوبة    صفوفُ profit_deal    صفوفُ profit_wallet
 * ```
 *
 * **كلُّ قائمةٍ مجموعُها رقمُ بوّابتها على البطاقة، بالبناء.** البطاقةُ تمشي الصفوفَ بـ
 * {@see InvestorWalletEntry::deltas()} ({@see InvestorBalances::forInvestor()})، وهذه تمشي الصفوفَ
 * نفسَها بالجيب نفسِه وتفصّلها — فلا صفَّ يُسقط ولا صفَّ يُعدّ مرّتين.
 *
 * ## و«معلّقة» و«متاحة للسحب» مطابقةٌ لا قائمةُ طلبيات
 *
 * الإفراجُ صفٌّ واحد لكلّ رجلٍ في الصفقة يجمع طلبياتٍ كثيرة، والسحبُ يأخذ من الجيب لا من طلبية.
 * فـ«أيُّ الطلبيات ما زال مالُها في محفظته» ليس واقعةً في الدفتر، ولا يُخترع لها جواب
 * (قرارُ المالك 2026-10-21: مطابقةٌ لا «الأقدمُ أوّلاً»). فالقائمةُ تقول ما جرى:
 *
 * - **معلّقة** فترةً فترة: ربحُ كلِّ طلبيةٍ بحالها، وما ليس طلبيةً (المصاريف، الخسارةُ
 *   المرحَّلة) سطرٌ باسمه، و«أُفرج عنه» سالباً في فترةٍ أُفرج عن بعضها.
 * - **متاحة للسحب**: ما أُفرج عنه من كلّ فترة (يُفتح على طلبياتها)، ثم كلُّ سحبٍ وتحويلٍ
 *   إلى رأس مال.
 */
final class InvestorProfitSources
{
    public const GATES = ['awaiting_delivery', 'pending', 'available'];

    /** صفوفٌ هي حركةُ الإفراج نفسُها، لا ما صُنع منه الربح — لا تُعرض تحت إفراجٍ مفتوح. */
    private const MOVEMENT_TYPES = [
        WalletEntryType::ProfitRelease,
        WalletEntryType::ProfitWithheld,
        WalletEntryType::LossCarriedOut,
    ];

    public function __construct(
        private readonly ProfitAwaitingDelivery $awaiting,
        private readonly PeriodOrdersQuery $periodOrders,
        private readonly InvestorBalances $balances,
    ) {}

    /**
     * @return array{gate: string, total: string, groups: list<array<string, mixed>>}
     */
    public function forGate(int $investorId, string $gate): array
    {
        return match ($gate) {
            'awaiting_delivery' => $this->awaitingDelivery($investorId),
            'pending' => $this->pending($investorId),
            'available' => $this->available($investorId),
        };
    }

    /**
     * «قيد التسليم» — طلبياتٌ بلغت «جاهزة» ولم تُسلَّم، ونصيبُه من كلٍّ منها.
     *
     * @return array{gate: string, total: string, groups: list<array<string, mixed>>}
     */
    public function awaitingDelivery(int $investorId): array
    {
        $amounts = $this->awaiting->ordersOf($investorId);
        $orders = $this->ordersById(array_keys($amounts));

        $lines = [];

        foreach ($amounts as $orderId => $amount) {
            $lines[] = $this->orderLine($orderId, $orders[$orderId] ?? null, ProfitSourceState::AwaitingDelivery, $amount);
        }

        usort($lines, fn (array $a, array $b): int => [$b['occurred_at'], $b['order_id']] <=> [$a['occurred_at'], $a['order_id']]);

        $total = Money::round(Money::sum('0', ...array_values($amounts)));

        return [
            'gate' => 'awaiting_delivery',
            'total' => $total,
            'groups' => $lines === [] ? [] : [$this->bareGroup('awaiting_delivery', $total, $lines)],
        ];
    }

    /**
     * «معلّقة» — صفوفُ ربحه التي لم تبلغ محفظته، فترةً فترة.
     *
     * فترةٌ مجموعُها صفرٌ لا تُعرض: كلُّ ما فيها أُفرج عنه، وهو في «متاحة للسحب».
     *
     * @return array{gate: string, total: string, groups: list<array<string, mixed>>}
     */
    public function pending(int $investorId): array
    {
        $ledger = $this->ledger($this->entriesOf($investorId));

        $total = '0';
        $groups = [];

        foreach ($ledger as $group) {
            $total = bcadd($total, $group['total'], 2);

            if (bccomp($group['total'], '0', 2) === 0) {
                continue;
            }

            $groups[] = $group;
        }

        return [
            'gate' => 'pending',
            'total' => Money::round($total),
            'groups' => array_map(fn (array $group): array => $this->withoutSortKeys($group), $groups),
        ];
    }

    /**
     * «متاحة للسحب» — ما أُفرج عنه من كلّ فترة، وما خرج من المحفظة بعده.
     *
     * إفراجاتُ الفترة الواحدة (عند الإقفال، ثم كلّما حُصِّلت طلبيةٌ منها) وما حُجز منها ثانيةً
     * سطرٌ واحد يُفتح على ما صُنع منه. والسحبُ والتحويلُ إلى رأس المال كلٌّ سطرُه، وما عُكس منها
     * يسقط مع عكسه — مجموعُهما صفر.
     *
     * @return array{gate: string, total: string, groups: list<array<string, mixed>>}
     */
    public function available(int $investorId): array
    {
        $entries = $this->entriesOf($investorId);
        $ledger = $this->ledger($entries);

        $releases = [];
        $wallet = [];

        foreach ($entries as $entry) {
            $delta = $entry->deltas()['profit_wallet'];

            if (bccomp($delta, '0', 2) === 0) {
                continue;
            }

            if ($entry->effectiveType()->belongsToADeal()) {
                $key = $this->groupKey($entry);
                $releases[$key] ??= ['entry' => $entry, 'amount' => '0', 'at' => null];
                $releases[$key]['amount'] = bcadd($releases[$key]['amount'], $delta, 2);
                $releases[$key]['at'] = $this->later($releases[$key]['at'], $entry->occurred_at);

                continue;
            }

            $wallet[(int) $entry->getKey()] = $entry;
        }

        $lines = [];
        $total = '0';

        foreach ($releases as $key => $release) {
            $total = bcadd($total, $release['amount'], 2);

            if (bccomp($release['amount'], '0', 2) === 0) {
                continue;
            }

            $lines[] = $this->releaseLine($key, $release['entry'], $release['amount'], $release['at'], $ledger[$key]['lines'] ?? []);
        }

        foreach ($this->withoutReversedPairs($wallet) as $entry) {
            $amount = $entry->deltas()['profit_wallet'];
            $total = bcadd($total, $amount, 2);

            $lines[] = [
                'kind' => 'entry',
                'key' => 'entry:'.$entry->getKey(),
                'label' => $entry->label(),
                'amount' => Money::round($amount),
                'occurred_at' => $entry->occurred_at?->toIso8601String(),
                'method' => $entry->method,
                'reference' => $entry->reference,
            ];
        }

        usort($lines, fn (array $a, array $b): int => [$b['occurred_at'] ?? '', $b['key']] <=> [$a['occurred_at'] ?? '', $a['key']]);

        $total = Money::round($total);

        return [
            'gate' => 'available',
            'total' => $total,
            'groups' => $lines === [] ? [] : [$this->bareGroup('available', $total, $lines)],
        ];
    }

    /**
     * صفوفُ ربحه في الصفقات مجموعةً بفترتها — أو بصفقتها لما لا فترةَ له — ومفصّلةً على طلبياتها.
     *
     * يقرؤها الجيبان كلاهما: «معلّقة» تعرضها كما هي، و«متاحة للسحب» تفتح بها إفراجَ كلّ فترة.
     *
     * @param  Collection<int, InvestorWalletEntry>  $entries
     * @return array<string, array<string, mixed>> المفتاح ← المجموعة، الأحدثُ أوّلاً
     */
    private function ledger(Collection $entries): array
    {
        $rows = [];

        foreach ($entries as $entry) {
            $amount = $entry->deltas()['profit_deal'];

            if (bccomp($amount, '0', 2) === 0) {
                continue;
            }

            [$sourceType, $sourceId] = $entry->effectiveSource();

            $rows[] = ['entry' => $entry, 'amount' => $amount, 'type' => $sourceType, 'id' => $sourceId];
        }

        $orderOf = $this->periodOrders->ordersBehind(array_values(array_filter(
            $rows,
            fn (array $row): bool => $row['type'] !== null && $row['id'] !== null,
        )));

        // ما يحجزه الإقفالُ: ربحٌ مصدرُه الطلبيةُ نفسُها ولم يُدفع ثمنُها — شرطُ الإقفال بعينه.
        $unpaid = $this->balances->ordersNotCollected(array_column($rows, 'entry'));

        $groups = [];

        foreach ($rows as $row) {
            /** @var InvestorWalletEntry $entry */
            $entry = $row['entry'];
            $key = $this->groupKey($entry);

            $groups[$key] ??= $this->emptyGroup($key, $entry);
            $groups[$key]['total'] = bcadd($groups[$key]['total'], $row['amount'], 2);
            $groups[$key]['at'] = $this->later($groups[$key]['at'], $entry->occurred_at);

            $orderId = $row['type'] === null ? null : ($orderOf[$row['type']][$row['id']] ?? null);

            if ($orderId !== null) {
                $state = $this->stateOf($entry, $row['type'] === AuditSubject::Order->value && isset($unpaid[$orderId]));
                $lineKey = $orderId.':'.$state->value;

                $groups[$key]['orders'][$lineKey] ??= ['order_id' => $orderId, 'state' => $state, 'amount' => '0'];
                $groups[$key]['orders'][$lineKey]['amount'] = bcadd($groups[$key]['orders'][$lineKey]['amount'], $row['amount'], 2);

                continue;
            }

            [$otherKey, $label] = $this->otherOf($entry, $row['type']);

            $groups[$key]['others'][$otherKey] ??= ['key' => $otherKey, 'label' => $label, 'amount' => '0', 'at' => null];
            $groups[$key]['others'][$otherKey]['amount'] = bcadd($groups[$key]['others'][$otherKey]['amount'], $row['amount'], 2);
            $groups[$key]['others'][$otherKey]['at'] = $this->later($groups[$key]['others'][$otherKey]['at'], $entry->occurred_at);
        }

        $orderIds = [];

        foreach ($groups as $group) {
            foreach ($group['orders'] as $line) {
                $orderIds[$line['order_id']] = $line['order_id'];
            }
        }

        $orders = $this->ordersById(array_values($orderIds));

        foreach ($groups as $key => $group) {
            $groups[$key] = $this->drawn($group, $orders);
        }

        uasort($groups, fn (array $a, array $b): int => $b['sort'] <=> $a['sort']);

        return $groups;
    }

    /**
     * المجموعةُ كما تُرسم: الطلبياتُ بحالها، ثم ما ليس طلبية، والإفراجُ آخرُها.
     *
     * @param  array<string, mixed>  $group
     * @param  array<int, object>  $orders
     * @return array<string, mixed>
     */
    private function drawn(array $group, array $orders): array
    {
        $orderLines = [];

        foreach ($group['orders'] as $line) {
            if (bccomp($line['amount'], '0', 2) === 0) {
                continue;
            }

            $orderLines[] = $this->orderLine($line['order_id'], $orders[$line['order_id']] ?? null, $line['state'], $line['amount']);
        }

        usort($orderLines, fn (array $a, array $b): int => [ProfitSourceState::from($a['state'])->rank(), $b['occurred_at'], $b['order_id']]
            <=> [ProfitSourceState::from($b['state'])->rank(), $a['occurred_at'], $a['order_id']]);

        $otherLines = [];

        foreach ($group['others'] as $other) {
            if (bccomp($other['amount'], '0', 2) === 0) {
                continue;
            }

            $otherLines[] = [
                'kind' => 'entry',
                'key' => $other['key'],
                'label' => $other['label'],
                'amount' => Money::round($other['amount']),
                'occurred_at' => $other['at']?->toIso8601String(),
            ];
        }

        // الإفراجُ وما يشبهه آخرُ المجموعة: هو ما يطرح منها، فيُقرأ بعد ما جُمع.
        usort($otherLines, fn (array $a, array $b): int => [$this->isMovement($a['key']), $a['key']] <=> [$this->isMovement($b['key']), $b['key']]);

        return [
            'key' => $group['key'],
            'title' => $group['title'],
            'starts_on' => $group['starts_on'],
            'ends_on' => $group['ends_on'],
            'status' => $group['status'],
            'status_label' => $group['status_label'],
            'total' => Money::round($group['total']),
            'lines' => [...$orderLines, ...$otherLines],
            'sort' => $group['sort'],
        ];
    }

    /**
     * إفراجُ فترةٍ أو صفقة، يُفتح على ما صُنع منه — طلبياتُه التي استُلم ربحُها وما ليس طلبية.
     *
     * @param  list<array<string, mixed>>  $groupLines
     * @return array<string, mixed>
     */
    private function releaseLine(string $key, InvestorWalletEntry $entry, string $amount, ?Carbon $at, array $groupLines): array
    {
        $children = array_values(array_filter($groupLines, fn (array $line): bool => $line['kind'] === 'order'
            ? $line['state'] === ProfitSourceState::Released->value
            : ! $this->isMovement($line['key'])));

        $period = $entry->period;
        $deal = $entry->deal;

        return [
            'kind' => 'release',
            'key' => 'release:'.$key,
            'label' => $period !== null
                ? 'أُفرج عنه من '.$period->code
                : 'أُفرج عنه من '.($deal?->isTheFund() === true ? 'الصندوق' : ($deal?->name ?? '')),
            'amount' => Money::round($amount),
            'occurred_at' => $at?->toIso8601String(),
            'period_code' => $period?->code,
            'starts_on' => $period?->starts_on?->toDateString(),
            'ends_on' => $period?->ends_on?->toDateString(),
            'children' => $children,
        ];
    }

    /**
     * أيَّ بوّابةٍ اجتاز صفٌّ واحد — القاعدةُ التي يُفرج بها الإقفالُ نفسُه.
     *
     * {@see InvestorBalances::releasableInPeriod()} يُفرج في «قيد الإغلاق» عن كلّ صفٍّ إلا ربحَ
     * طلبيةٍ لم يُدفع ثمنُها؛ والمغلقةُ «لم يبقَ فيها شيء» بتعريفها. وما لا فترةَ له: صفقةٌ قديمة
     * تُفرج يومَ تُقفَل، أو صفُّ صندوقٍ لم تختمه فترةٌ بعد.
     */
    private function stateOf(InvestorWalletEntry $entry, bool $unpaid): ProfitSourceState
    {
        $period = $entry->period;

        if ($period !== null) {
            return match ($period->status) {
                PeriodStatus::Open => ProfitSourceState::AwaitingPeriodEnd,
                PeriodStatus::Closing => $unpaid ? ProfitSourceState::AwaitingPayment : ProfitSourceState::Released,
                PeriodStatus::Closed => ProfitSourceState::Released,
            };
        }

        $deal = $entry->deal;

        if ($deal === null || $deal->folded_into_fund_at !== null || $deal->status === DealStatus::Closed) {
            return ProfitSourceState::Released;
        }

        return $deal->isTheFund() ? ProfitSourceState::AwaitingPeriodEnd : ProfitSourceState::AwaitingDealClose;
    }

    /**
     * سطرُ ما ليس طلبية: المصاريفُ معاً، والباقي باسم نوعه.
     *
     * @return array{0: string, 1: string}
     */
    private function otherOf(InvestorWalletEntry $entry, ?string $sourceType): array
    {
        $type = $entry->effectiveType();

        if ($type === WalletEntryType::Profit || $type === WalletEntryType::Loss) {
            if (in_array($sourceType, [AuditSubject::InvestorDealExpense->value, AuditSubject::FundExpenseCharge->value], true)) {
                return ['expenses', 'نصيبه من المصاريف'];
            }

            if (in_array($sourceType, [AuditSubject::StockMovement->value, AuditSubject::OrderItem->value], true)) {
                return ['press_margin', 'هامش بيع السادة للمطبعة'];
            }
        }

        return [
            'type:'.$type->value,
            $entry->deal?->isTheFund() === true ? $type->fundLabel() : $type->label(),
        ];
    }

    private function isMovement(string $key): bool
    {
        foreach (self::MOVEMENT_TYPES as $type) {
            if ($key === 'type:'.$type->value) {
                return true;
            }
        }

        return false;
    }

    /**
     * سحبٌ عُكس وعكسُه يسقطان معاً — مجموعُهما صفر، ورسمُهما سطران يقولان لا شيء.
     *
     * @param  array<int, InvestorWalletEntry>  $entries
     * @return list<InvestorWalletEntry>
     */
    private function withoutReversedPairs(array $entries): array
    {
        $dropped = [];

        foreach ($entries as $id => $entry) {
            $original = $entry->reverses_entry_id === null ? null : (int) $entry->reverses_entry_id;

            if ($entry->type === WalletEntryType::Reversal && $original !== null && isset($entries[$original])) {
                $dropped[$id] = true;
                $dropped[$original] = true;
            }
        }

        return array_values(array_filter($entries, fn (InvestorWalletEntry $entry): bool => ! isset($dropped[(int) $entry->getKey()])));
    }

    private function groupKey(InvestorWalletEntry $entry): string
    {
        return $entry->investment_period_id !== null
            ? 'period:'.$entry->investment_period_id
            : 'deal:'.$entry->investor_deal_id;
    }

    /**
     * @return array<string, mixed>
     */
    private function emptyGroup(string $key, InvestorWalletEntry $entry): array
    {
        $period = $entry->period;
        $deal = $entry->deal;

        return [
            'key' => $key,
            'title' => $period?->code ?? ($deal?->isTheFund() === true ? 'الصندوق — لم تُختم بفترة' : ($deal?->name ?? '')),
            'starts_on' => $period?->starts_on?->toDateString(),
            'ends_on' => $period?->ends_on?->toDateString(),
            'status' => $period?->status->value,
            'status_label' => $period?->status->label(),
            'total' => '0',
            'at' => null,
            // الأحدثُ أوّلاً: الفترةُ ببدايتها، وما لا فترةَ له بآخر صفوفه.
            'sort' => $period?->starts_on?->toDateString() ?? '',
            'orders' => [],
            'others' => [],
        ];
    }

    /**
     * مجموعةٌ بلا عنوان — «قيد التسليم» و«متاحة للسحب» قائمةٌ واحدة.
     *
     * @param  list<array<string, mixed>>  $lines
     * @return array<string, mixed>
     */
    private function bareGroup(string $key, string $total, array $lines): array
    {
        return [
            'key' => $key,
            'title' => null,
            'starts_on' => null,
            'ends_on' => null,
            'status' => null,
            'status_label' => null,
            'total' => $total,
            'lines' => $lines,
        ];
    }

    /**
     * @param  array<string, mixed>  $group
     * @return array<string, mixed>
     */
    private function withoutSortKeys(array $group): array
    {
        unset($group['sort']);

        return $group;
    }

    /**
     * @return array<string, mixed>
     */
    private function orderLine(int $orderId, ?object $order, ProfitSourceState $state, string $amount): array
    {
        $status = $order === null ? null : OrderStatus::tryFrom((string) $order->status);
        $at = $order === null ? null : ($order->delivered_at ?? $order->ready_at ?? $order->placed_at ?? $order->created_at);

        return [
            'kind' => 'order',
            'key' => 'order:'.$orderId.':'.$state->value,
            'order_id' => $orderId,
            'code' => $order === null ? null : (string) $order->code,
            'customer_name' => $order?->customer_name === null ? null : (string) $order->customer_name,
            'order_status' => $order === null ? null : (string) $order->status,
            'order_status_label' => $status?->label(),
            'state' => $state->value,
            'state_label' => $state->label(),
            'amount' => Money::round($amount),
            'occurred_at' => $at === null ? null : Carbon::parse((string) $at)->toIso8601String(),
        ];
    }

    /**
     * بياناتُ الطلبيات وراء الصفوف — **والمحذوفةُ معها**: ربحُها في الدفتر ما لم يُعكس، وإسقاطُها
     * يجعل القائمةَ أقلَّ من رقم البطاقة بلا سبب.
     *
     * @param  list<int>  $orderIds
     * @return array<int, object>
     */
    private function ordersById(array $orderIds): array
    {
        if ($orderIds === []) {
            return [];
        }

        return DB::table('orders as o')
            ->leftJoin('customers as cu', 'cu.id', '=', 'o.customer_id')
            ->whereIn('o.id', $orderIds)
            ->get([
                'o.id',
                'o.code',
                'o.status',
                'o.delivered_at',
                'o.ready_at',
                'o.placed_at',
                'o.created_at',
                'cu.name as customer_name',
            ])
            ->keyBy('id')
            ->all();
    }

    /**
     * @return Collection<int, InvestorWalletEntry>
     */
    private function entriesOf(int $investorId): Collection
    {
        return InvestorWalletEntry::query()
            ->with(['reversedEntry', 'deal', 'period'])
            ->where('investor_id', $investorId)
            ->orderBy('id')
            ->get();
    }

    private function later(?Carbon $current, ?Carbon $candidate): ?Carbon
    {
        if ($candidate === null) {
            return $current;
        }

        return $current === null || $candidate->greaterThan($current) ? $candidate : $current;
    }
}
