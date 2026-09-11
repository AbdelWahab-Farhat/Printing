<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Investor\Support\StockPurchaseMargins;
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
 *     investor_funded_percent × investor_profit_share_percent`, net of any reversal. Null while
 *     the ledger holds no row for the order, which is every سادة order before «تم الاستلام» and
 *     also the rare delivered one whose share rounded to nothing — the posting action writes no
 *     row for a zero.
 *
 * The gap between them is the company's own cut, and publishing only one of the two would hide
 * either where the money came from or what was done with it.
 *
 * **Both roads land in the one row, added together.** A printed line does not ride the sale: the
 * press bought its plain bags at سعر السادة the day they left the shelf, and {@see
 * OrderDealSlices} drops that draw precisely so the delivery does not pay for it twice. Read
 * alone it would leave this screen saying «٠ وحدة · تكلفتها ٠ · ربح ٠» about an order that took
 * twenty kilos off the shelf and paid for them — the goods would simply vanish from the deal's
 * own statement. So {@see StockPurchaseMargins} is read beside it and the two are summed: what
 * this order took from the deal, and what the deal made on it, by whichever road.
 *
 * **The distinction the two roads do have is kept where it belongs** — on the order screen
 * ({@see OrderInvestorSharesQuery}), which draws them as separate rows because there one sits
 * above the cost line and the other below it. Here the question is «كم أدخلت لي هذه الطلبية»,
 * and it has one answer.
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
    /** A road this order did not travel — what the other road's figures are added to. */
    private const NOTHING = [
        'quantity' => '0.000',
        'material_cost' => '0.00',
        'revenue' => '0.00',
        'conversion_cost' => '0.00',
        'profit' => '0.00',
    ];

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

        $attributions = $this->orders->profitAttributionForMany($orderIds);
        $scrap = $this->scrapMovementsFor($orderIds);
        $breakdown = $this->breakdownFor($attributions, $scrap);

        $figures = $this->figuresFor($attributions, $scrap, $breakdown, $dealId);
        $posted = $this->postedFor($orderIds, $attributions, $scrap, $dealId);

        return $paginator->through(fn (object $row): array => $this->row(
            $row,
            $figures[(int) $row->id] ?? null,
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
     * Every draw behind this page, keyed by movement — the lines' own, and any spoiled run after
     * them.
     *
     * One read for the whole page: the sale's split needs every draw of every movement, the
     * company's included, so there is nothing to narrow here anyway.
     *
     * @param  array<int, array<string, mixed>>  $attributions
     * @param  array<int, list<int>>  $scrap
     * @return array<int, list<array<string, mixed>>>
     */
    private function breakdownFor(array $attributions, array $scrap): array
    {
        $movementIds = [];

        foreach ($attributions as $attribution) {
            foreach ($attribution['lines'] as $line) {
                $movementIds[] = $line['movement_id'];
            }
        }

        foreach ($scrap as $movements) {
            foreach ($movements as $movementId) {
                $movementIds[] = $movementId;
            }
        }

        return $movementIds === [] ? [] : $this->inventory->consumptionBreakdownFor($movementIds);
    }

    /**
     * What each order took from this deal and made for it, by both roads at once, keyed by order.
     *
     * @param  array<int, array<string, mixed>>  $attributions
     * @param  array<int, list<int>>  $scrap
     * @param  array<int, list<array<string, mixed>>>  $breakdown
     * @return array<int, array<string, string>>
     */
    private function figuresFor(array $attributions, array $scrap, array $breakdown, int $dealId): array
    {
        $figures = [];

        foreach ($attributions as $orderId => $attribution) {
            $sale = OrderDealSlices::forOrder($attribution, $breakdown)[$dealId] ?? null;
            $purchase = $this->purchaseOf($attribution, $scrap[$orderId] ?? [], $breakdown, $dealId);

            if ($sale === null && $purchase === null) {
                continue;
            }

            $figures[$orderId] = $this->add($sale ?? self::NOTHING, $purchase ?? self::NOTHING);
        }

        return $figures;
    }

    /**
     * What the press bought off this deal on one order — the road {@see OrderDealSlices} leaves
     * out by design, because the money for it was settled at the shelf rather than at the door.
     *
     * `revenue` here is what the **press** paid, not what the customer did: on this road the
     * deal's sale completed at the warehouse, and the customer's price is the press's business
     * afterwards. Null when this order bought nothing off this deal, which keeps a سادة order out
     * of the addition entirely rather than adding zeros to it.
     *
     * @param  array<string, mixed>  $attribution
     * @param  list<int>  $scrapMovements
     * @param  array<int, list<array<string, mixed>>>  $breakdown
     * @return array<string, string>|null
     */
    private function purchaseOf(array $attribution, array $scrapMovements, array $breakdown, int $dealId): ?array
    {
        $movementIds = [];

        foreach ($attribution['lines'] as $line) {
            if ($line['stock_purchased']) {
                $movementIds[] = $line['movement_id'];
            }
        }

        foreach ($scrapMovements as $movementId) {
            $movementIds[] = $movementId;
        }

        $figures = self::NOTHING;
        $bought = false;

        foreach ($movementIds as $movementId) {
            $draws = $breakdown[$movementId] ?? [];
            $paid = StockPurchaseMargins::paidByDeal($draws)[$dealId] ?? null;

            if ($paid === null) {
                continue;
            }

            $bought = true;

            // The money is the shared arithmetic's; the quantity and what those kilos had cost
            // are plain sums over the same draws, and are what the row says the profit was made
            // on.
            foreach ($draws as $draw) {
                if ((int) ($draw['investor_deal_id'] ?? 0) !== $dealId || $draw['printing_sale_price'] === null) {
                    continue;
                }

                $figures['quantity'] = bcadd($figures['quantity'], $draw['quantity'], 3);
                $figures['material_cost'] = bcadd($figures['material_cost'], $draw['total_cost'], 2);
            }

            $figures['revenue'] = bcadd($figures['revenue'], $paid, 2);
            $figures['profit'] = bcadd(
                $figures['profit'],
                StockPurchaseMargins::byDeal($draws)[$dealId] ?? '0.00',
                2,
            );
        }

        return $bought ? $figures : null;
    }

    /**
     * @param  array<string, string>  $sale
     * @param  array<string, string>  $purchase
     * @return array<string, string>
     */
    private function add(array $sale, array $purchase): array
    {
        return [
            'quantity' => bcadd($sale['quantity'], $purchase['quantity'], 3),
            'material_cost' => bcadd($sale['material_cost'], $purchase['material_cost'], 2),
            'revenue' => bcadd($sale['revenue'], $purchase['revenue'], 2),
            'conversion_cost' => bcadd($sale['conversion_cost'], $purchase['conversion_cost'], 2),
            'profit' => bcadd($sale['profit'], $purchase['profit'], 2),
        ];
    }

    /**
     * The spoiled runs charged to each of these orders, keyed by order id.
     *
     * **Found by `reference_id`, which is safe for this movement type and no other**: scrap rows
     * have exactly one writer — `Order\Actions\RecordScrapLoss` — and it always stamps the order.
     * The warning that column carries elsewhere is about `OrderFulfillment`, which a generic
     * endpoint can post with any reference at all.
     *
     * @param  list<int>  $orderIds
     * @return array<int, list<int>>
     */
    private function scrapMovementsFor(array $orderIds): array
    {
        if ($orderIds === []) {
            return [];
        }

        $byOrder = [];

        $rows = DB::table('stock_movements')
            ->where('movement_type', 'scrap_loss')
            ->whereIn('reference_id', $orderIds)
            ->whereNull('deleted_at')
            ->orderBy('id')
            ->get(['id', 'reference_id']);

        foreach ($rows as $row) {
            $byOrder[(int) $row->reference_id][] = (int) $row->id;
        }

        return $byOrder;
    }

    /**
     * What the ledger actually paid the investors for each order, keyed by order id.
     *
     * Signed, and net of corrections: a reversed row is not what stands, and the fresh row that
     * replaced it names the same order under the next sequence.
     *
     * **Three posting keys, one row.** A سادة sale is paid against the **order**; a purchase at
     * سعر السادة against the **line** that bought it, so that a restatement can correct itself;
     * and a spoiled run against its own **movement**, so that its payment is added beside the
     * line's rather than replacing it. A person reading this list is asking about the order, so
     * each key is resolved back to the order it belongs to and the three are summed. Reading only
     * the order key — as this did before سعر السادة — would leave a paid purchase showing as
     * unpaid forever.
     *
     * @param  list<int>  $orderIds
     * @param  array<int, array<string, mixed>>  $attributions
     * @param  array<int, list<int>>  $scrap
     * @return array<int, string>
     */
    private function postedFor(array $orderIds, array $attributions, array $scrap, int $dealId): array
    {
        if ($orderIds === []) {
            return [];
        }

        /** @var array<string, array<int, int>> $owners source id → the order it belongs to */
        $owners = [AuditSubject::Order->value => array_combine($orderIds, $orderIds)];

        foreach ($attributions as $orderId => $attribution) {
            foreach ($attribution['lines'] as $line) {
                $owners[AuditSubject::OrderItem->value][(int) $line['line_id']] = $orderId;
            }
        }

        foreach ($scrap as $orderId => $movements) {
            foreach ($movements as $movementId) {
                $owners[AuditSubject::StockMovement->value][$movementId] = $orderId;
            }
        }

        $posted = [];

        foreach ($owners as $sourceType => $map) {
            $entries = InvestorWalletEntry::query()
                ->where('investor_deal_id', $dealId)
                ->where('source_type', $sourceType)
                ->whereIn('source_id', array_keys($map))
                ->whereIn('type', [WalletEntryType::Profit->value, WalletEntryType::Loss->value])
                ->whereDoesntHave('reversedBy')
                ->get();

            foreach ($entries as $entry) {
                $orderId = $map[(int) $entry->source_id] ?? null;

                if ($orderId === null) {
                    continue;
                }

                $posted[$orderId] = bcadd($posted[$orderId] ?? '0.00', $entry->signedAmount(), 2);
            }
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
