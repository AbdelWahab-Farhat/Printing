<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\OrderService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * Every order that sold this deal's goods, and what each one earned it.
 *
 * The answer to «أي طلبيات كانت مرتبطة بالصفقة وكم ربحٍ أدخلت» — and the reason it can be
 * answered at all is that nothing here is stored: the link is the FIFO draw ledger, and the
 * money is arithmetic over figures that were frozen when the order was.
 *
 * **Two numbers per row, and they are not the same number.**
 *
 *   * `profit` is what the *deal* made on that order — revenue less the company's conversion cost
 *     less the exact material cost of the units drawn. Derived, never stored, by the very code
 *     that pays the investors ({@see OrderDealSlices}), so the row and the ledger cannot disagree.
 *   * `investors_share` is what was actually **written into the ledger** for it — `profit ×
 *     investor_profit_share_percent`, net of any reversal. Null while the ledger holds no row
 *     for the order, which is every order before «تم الاستلام» and also the rare delivered one
 *     whose share rounded to nothing — the posting action writes no row for a zero.
 *
 * The gap between them is the company's own cut, and publishing only one of the two would hide
 * either where the money came from or what was done with it.
 *
 * **A reversed draw is not a row.** A cancelled order returns its goods to this deal's very
 * layers, so it took nothing and earned nothing — the same exclusion {@see DealStockPosition} and
 * {@see DealOrdersInFlightQuery} make, and for the same reason.
 *
 * **An order in flight is a row.** It is holding the deal's stock right now and is exactly what
 * refuses to let the deal close; showing it only once it is paid would leave a person looking at
 * an empty shelf and an empty list, wondering where the goods went.
 */
final class DealOrdersQuery
{
    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @return LengthAwarePaginator<int, array<string, mixed>>
     */
    public function __invoke(int $dealId, int $perPage = 15): LengthAwarePaginator
    {
        /** @var LengthAwarePaginator<int, object> $paginator */
        $paginator = $this->ordersOf($dealId)->paginate($perPage);

        $orderIds = $paginator->getCollection()
            ->map(fn (object $row): int => (int) $row->id)
            ->all();

        $slices = $this->slicesFor($orderIds, $dealId);
        $posted = $this->postedFor($orderIds, $dealId);

        return $paginator->through(fn (object $row): array => $this->row(
            $row,
            $slices[(int) $row->id] ?? null,
            $posted[(int) $row->id] ?? null,
        ));
    }

    /**
     * The orders whose lines drew from a live layer of this deal, newest first.
     *
     * Joined through `order_items.fulfillment_stock_movement_id` rather than through
     * `stock_movements.reference_id`: that column has no foreign key and is freely settable, so a
     * query keyed on it sweeps in rows belonging to no order line at all.
     */
    private function ordersOf(int $dealId): Builder
    {
        return DB::table('orders as o')
            ->leftJoin('customers as cu', 'cu.id', '=', 'o.customer_id')
            ->whereNull('o.deleted_at')
            ->whereExists(fn ($q) => $q->select(DB::raw(1))
                ->from('stock_batch_consumptions as c')
                ->join('stock_batches as b', 'b.id', '=', 'c.stock_batch_id')
                ->join('stock_movements as m', 'm.id', '=', 'c.stock_movement_id')
                ->join('order_items as oi', 'oi.fulfillment_stock_movement_id', '=', 'm.id')
                ->whereColumn('oi.order_id', 'o.id')
                ->where('b.investor_deal_id', $dealId)
                ->whereNull('b.deleted_at')
                ->whereNull('c.deleted_at')
                ->whereNull('m.deleted_at')
                ->whereNull('oi.deleted_at')
                ->whereNotExists(fn ($r) => $r->select(DB::raw(1))
                    ->from('stock_movements as rev')
                    ->whereColumn('rev.reverses_movement_id', 'm.id')
                    ->whereNull('rev.deleted_at')))
            ->orderByDesc('o.id')
            ->select([
                'o.id',
                'o.code',
                'o.status',
                'o.grand_total',
                'o.delivered_at',
                'o.placed_at',
                'o.created_at',
                'cu.name as customer_name',
            ]);
    }

    /**
     * This deal's slice of each order, keyed by order id.
     *
     * @param  list<int>  $orderIds
     * @return array<int, array<string, string>>
     */
    private function slicesFor(array $orderIds, int $dealId): array
    {
        $attributions = $this->orders->profitAttributionForMany($orderIds);

        if ($attributions === []) {
            return [];
        }

        $movementIds = [];

        foreach ($attributions as $attribution) {
            foreach ($attribution['lines'] as $line) {
                $movementIds[] = $line['movement_id'];
            }
        }

        // One read for the whole page's draws — the split needs every draw of every movement,
        // the company's included, so there is nothing to narrow here anyway.
        $breakdown = $this->inventory->consumptionBreakdownFor($movementIds);

        $slices = [];

        foreach ($attributions as $orderId => $attribution) {
            $slice = OrderDealSlices::forOrder($attribution, $breakdown)[$dealId] ?? null;

            if ($slice !== null) {
                $slices[$orderId] = $slice;
            }
        }

        return $slices;
    }

    /**
     * What the ledger actually paid the investors for each order, keyed by order id.
     *
     * Signed, and net of corrections: a reversed row is not what stands, and the fresh row that
     * replaced it names the same order under the next sequence.
     *
     * @param  list<int>  $orderIds
     * @return array<int, string>
     */
    private function postedFor(array $orderIds, int $dealId): array
    {
        if ($orderIds === []) {
            return [];
        }

        $entries = InvestorWalletEntry::query()
            ->where('investor_deal_id', $dealId)
            ->where('source_type', AuditSubject::Order->value)
            ->whereIn('source_id', $orderIds)
            ->whereIn('type', [WalletEntryType::Profit->value, WalletEntryType::Loss->value])
            ->whereDoesntHave('reversedBy')
            ->get();

        $posted = [];

        foreach ($entries as $entry) {
            $orderId = (int) $entry->source_id;

            $posted[$orderId] = bcadd($posted[$orderId] ?? '0.00', $entry->signedAmount(), 2);
        }

        return $posted;
    }

    /**
     * @param  array<string, string>|null  $slice
     * @return array<string, mixed>
     */
    private function row(object $order, ?array $slice, ?string $posted): array
    {
        $status = OrderStatus::tryFrom((string) $order->status);
        $profit = $slice['profit'] ?? '0.00';

        return [
            'order_id' => (int) $order->id,
            'code' => (string) $order->code,
            'status' => (string) $order->status,
            'status_label' => $status?->label() ?? (string) $order->status,
            'customer_name' => $order->customer_name === null ? null : (string) $order->customer_name,

            // When it reached the customer — the moment the money became this deal's — falling
            // back to when it was placed for one that has not got there yet.
            'occurred_at' => $order->delivered_at ?? $order->placed_at ?? $order->created_at,

            'grand_total' => (string) $order->grand_total,

            'quantity' => $slice['quantity'] ?? '0.000',
            'material_cost' => $slice['material_cost'] ?? '0.00',
            'revenue' => $slice['revenue'] ?? '0.00',
            'conversion_cost' => $slice['conversion_cost'] ?? '0.00',
            'profit' => $profit,

            // Null, not zero: «nothing was paid» and «zero was paid» are different sentences, and
            // the second one is what an order that broke exactly even says.
            'investors_share' => $posted,
            'company_share' => $posted === null ? null : bcsub($profit, $posted, 2),
            'is_posted' => $posted !== null,
        ];
    }
}
