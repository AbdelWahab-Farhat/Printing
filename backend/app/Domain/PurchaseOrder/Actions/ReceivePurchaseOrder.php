<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\SupplyFunding;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\InvestorService;
use App\Domain\PurchaseOrder\DTOs\PurchaseOrderAdditionalCostData;
use App\Domain\PurchaseOrder\DTOs\ReceivePurchaseOrderData;
use App\Domain\PurchaseOrder\DTOs\ReceivePurchaseOrderItemData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\ArrivalCostOnFundedLineNeedsADrawer;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderHasNoWarehouse;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderNotReceivable;
use App\Domain\PurchaseOrder\Exceptions\StockItemNotOnPurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\PurchaseOrder\Support\LargestRemainder;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Vendor\DTOs\StockArrivalData;
use App\Domain\Vendor\DTOs\StockArrivalItemData;
use App\Domain\Vendor\Models\StockArrival;
use App\Domain\Vendor\VendorService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Receives a shipment against a purchase order: posts it through Vendor's own front door, then
 * applies what it means for this order's lines and status.
 *
 * **This class never writes a balance, and never writes `stock_arrival_items` itself.**
 * {@see VendorService::recordStockArrival()} — the same call the plain
 * `POST /stock-arrivals` endpoint makes — is the only path taken to actually move stock, per
 * RULES.md §3: cross-context work goes through the other module's Service, never around it. What
 * happens here is layered strictly on top, in the same transaction: a line's
 * `quantity_received` climbs by what this shipment carried, and the order's status is
 * recomputed from the result.
 *
 * **A shipment larger than the order is booked in whole.** Suppliers overship — a run of bags
 * comes off the machine heavy and the whole lot arrives — and the goods are on the shelf whether
 * or not the paperwork expected them, so refusing the receipt would only leave the ledger
 * describing a warehouse that does not exist. The surplus enters stock at the line's own landed
 * unit cost; the line then owes nothing and reports the surplus separately, and the order
 * completes.
 *
 * **A shipment smaller than the order also completes it, and the shortfall is reported rather
 * than left holding the order open.** The owner's rule, on 2026-09-06: «تسجيل شحنات دوما يخليها
 * مكتملة حتى لو في نواقص وتسجل كنواقص». A delivery is the event that closes the order — what the
 * supplier failed to send is a fact about that delivery, not a reason to keep asking whether more
 * is coming. What is still owing stays on the line as `quantity_ordered - quantity_received` and
 * is published as `quantity_remaining` beside `quantity_over_received`, so «نواقص» is a number
 * every screen can read off the order rather than a status it has to infer.
 *
 * **So the receipt is the order's last act.** `completed` is refused by the guard above, which
 * makes the first shipment the only one an order takes: goods that turn up afterwards are their
 * own event and are posted through `POST /stock-arrivals`, unattached to a purchase order.
 *
 * ## What the layers cost — PURCHASE-ORDER-ARRIVAL-COSTS.md
 *
 * **Costs paid on the lorry's arrival** — delivery, porters, customs — come in with the receipt
 * and are written as the order's additional costs, stamped with this arrival. Each is spread over
 * the lines that received anything, weighted by the base value of what arrived, in cents
 * ({@see LargestRemainder}) — so it lands on what it was paid to bring.
 *
 * **A company line's layer opens at everything paid for what arrived**, over the quantity that
 * arrived: its base cost for that quantity, its whole share of the planned costs, and its share
 * of the arrival costs. A short shipment no longer leaves part of a delivery fee outside the stock
 * — the owner's decision 3.
 *
 * **A funded line's layer opens at `final_unit_cost`, as it always has** — the deal agreed its cost
 * when it was funded (decision 2). Its share of an arrival cost is charged to the deal instead, as
 * the deal's expense, through {@see InvestorService::recordSupplyExpense()}. A deal expense is money
 * that left a drawer, so such a cost must name one ({@see ArrivalCostOnFundedLineNeedsADrawer}).
 *
 * **Who was paid** decides the money: on the vendor's bill it joins `vendor_amount`; from a drawer
 * or owed to a manual payable it is an `expense` on that account ({@see SyncAdditionalCostExpense}),
 * for the company's part — the deal expense posts its own.
 *
 * @throws PurchaseOrderNotReceivable
 * @throws PurchaseOrderHasNoWarehouse
 * @throws StockItemNotOnPurchaseOrder
 * @throws ArrivalCostOnFundedLineNeedsADrawer
 */
final class ReceivePurchaseOrder
{
    public function __construct(
        private readonly VendorService $vendors,
        private readonly InvestorService $investors,
        private readonly RecalculatePurchaseOrderTotal $recalculateTotal,
        private readonly SyncPurchaseOrderDebt $syncDebt,
        private readonly SyncAdditionalCostExpense $costExpense,
    ) {}

    public function __invoke(PurchaseOrder $order, ReceivePurchaseOrderData $data): StockArrival
    {
        if (! in_array($order->status, [PurchaseOrderStatus::New, PurchaseOrderStatus::Arrived], true)) {
            throw PurchaseOrderNotReceivable::make($order->status);
        }

        if ($order->warehouse_id === null) {
            throw PurchaseOrderHasNoWarehouse::make((int) $order->getKey());
        }

        return DB::transaction(function () use ($order, $data): StockArrival {
            // Locked for the rest of the transaction so two concurrent receipts against the
            // same order cannot both read the same quantity_received and both write a total
            // computed from it — the same reasoning ApplyStockChange locks a balance row for.
            $items = $order->items()->lockForUpdate()->get()->keyBy('stock_item_id');

            foreach ($data->items as $line) {
                $this->guardLine($order, $items, $line);
            }

            /** @var array<int, string> $received Quantity this shipment carried, by order line id. */
            $received = [];
            /** @var array<int, SupplyFunding|null> $funding The deal that bought each line, by line id. */
            $funding = [];

            foreach ($data->items as $line) {
                /** @var PurchaseOrderItem $item */
                $item = $items->get($line->stockItemId);
                $received[$item->getKey()] = $line->quantity;
                // **The whole of «الموظف لا يختار الصفقة أبداً».** One question to Investment per
                // line, answered from a claim somebody made before the goods left the supplier.
                // Null for everything the company bought for itself.
                $funding[$item->getKey()] = $this->investors->dealForSupply((int) $order->getKey(), $line->stockItemId);
            }

            $byId = $items->keyBy('id');
            $shares = $this->splitArrivalCosts($data->additionalCosts, $byId, $received);

            // Every refusal before anything is written.
            foreach ($data->additionalCosts as $index => $cost) {
                $field = "additional_costs.{$index}.treasury_account_id";
                $this->costExpense->guardAccount($cost->treasuryAccountId, $field);
                $this->guardFundedShare($cost, $shares[$index], $funding, $field);
            }

            /** @var array<int, string> $arrivalShare Each line's share of every arrival cost. */
            $arrivalShare = array_map(fn () => '0', $received);

            foreach ($shares as $costShares) {
                foreach ($costShares as $itemId => $cents) {
                    $arrivalShare[$itemId] = bcadd($arrivalShare[$itemId], $cents, 0);
                }
            }

            $landed = [];

            foreach ($received as $itemId => $quantity) {
                $landed[$itemId] = $this->landedCost(
                    $byId->get($itemId),
                    $quantity,
                    LargestRemainder::fromCents($arrivalShare[$itemId]),
                    $funding[$itemId] !== null,
                );
            }

            $arrival = $this->vendors->recordStockArrival(new StockArrivalData(
                vendorId: $order->vendor_id,
                warehouseId: $order->warehouse_id,
                receivedBy: $data->receivedBy,
                items: array_map(
                    function (ReceivePurchaseOrderItemData $line) use ($items, $landed, $funding): StockArrivalItemData {
                        $itemId = (int) $items->get($line->stockItemId)->getKey();

                        return new StockArrivalItemData(
                            stockItemId: $line->stockItemId,
                            quantity: $line->quantity,
                            unitCost: $landed[$itemId]['unit'],
                            // Priced against what *this* shipment delivered, not the order line's
                            // own total — a partial receipt costs less than the whole line does.
                            totalCost: $landed[$itemId]['total'],
                            // The receiving screen's body is unchanged and the storekeeper sees no
                            // field.
                            investorDealId: $funding[$itemId]?->dealId,
                            // Frozen onto the layer beside the deal that owns it: what the press
                            // will pay for these bags the day it prints on them.
                            printingSalePrice: $funding[$itemId]?->printingSalePrice,
                        );
                    },
                    $data->items,
                ),
                invoiceNumber: $data->invoiceNumber,
                notes: $data->notes,
                purchaseOrderId: $order->getKey(),
            ));

            foreach ($received as $itemId => $quantity) {
                /** @var PurchaseOrderItem $item */
                $item = $byId->get($itemId);
                $item->quantity_received = bcadd((string) $item->quantity_received, $quantity, 3);
                $item->forceFill([
                    'arrival_additional_cost' => LargestRemainder::fromCents($arrivalShare[$itemId]),
                    'landed_unit_cost' => $landed[$itemId]['unit'],
                ]);
                $item->save();
            }

            $costs = [];

            foreach ($data->additionalCosts as $cost) {
                $row = $order->additionalCosts()->make(['name' => $cost->name, 'amount' => $cost->amount]);
                $row->stock_arrival_id = $arrival->getKey();
                $row->treasury_account_id = $cost->treasuryAccountId;
                $row->recorded_by = $data->receivedBy;
                $row->save();

                $costs[] = $row;
            }

            // Unconditional — see the class docblock. A short delivery closes the order just as
            // a full one does, and what is missing is read off the lines, not off the status.
            $order->status = PurchaseOrderStatus::Completed;
            $order->save();

            ($this->recalculateTotal)($order);
            // A cost on the vendor's bill is owed to them from now on.
            ($this->syncDebt)($order, $data->receivedBy);

            foreach ($costs as $index => $row) {
                $this->chargeTheMoney($order, $row, $shares[$index], $funding, $data->receivedBy);
            }

            return $arrival;
        });
    }

    /**
     * The line has to *be* on the order — a shipment naming a shelf nobody ordered is a mistyped
     * payload, not a delivery. How much it carried is not questioned: over-delivery is a normal
     * thing for a supplier to do on one size, and refusing it would leave real stock unbooked.
     *
     * @param  Collection<int, PurchaseOrderItem>  $items  Keyed by stock_item_id.
     *
     * @throws StockItemNotOnPurchaseOrder
     */
    private function guardLine(PurchaseOrder $order, Collection $items, ReceivePurchaseOrderItemData $line): void
    {
        if (! $items->has($line->stockItemId)) {
            throw StockItemNotOnPurchaseOrder::make($line->stockItemId, (int) $order->getKey());
        }
    }

    /**
     * Each arrival cost over the lines that arrived, by the base value of what arrived — the
     * line's base cost scaled to the quantity received. A line priced before cost tracking
     * weighs nothing.
     *
     * @param  list<PurchaseOrderAdditionalCostData>  $costs
     * @param  Collection<int, PurchaseOrderItem>  $items  Keyed by id.
     * @param  array<int, string>  $received  By line id.
     * @return list<array<int, string>> Per cost, its cents per line id.
     */
    private function splitArrivalCosts(array $costs, Collection $items, array $received): array
    {
        $weights = [];

        foreach ($received as $itemId => $quantity) {
            $weights[$itemId] = LargestRemainder::toCents(Money::round($this->baseCostOf($items->get($itemId), $quantity) ?? '0'));
        }

        return array_map(
            fn (PurchaseOrderAdditionalCostData $cost) => LargestRemainder::split(LargestRemainder::toCents($cost->amount), $weights),
            array_values($costs),
        );
    }

    /**
     * What the line's base cost comes to for `$quantity` — its `base_total_cost` scaled from what
     * was ordered to what arrived. Null on a line priced before cost tracking.
     */
    private function baseCostOf(PurchaseOrderItem $item, string $quantity): ?string
    {
        if ($item->base_total_cost === null) {
            return null;
        }

        return bcdiv(bcmul((string) $item->base_total_cost, $quantity, 10), (string) $item->quantity_ordered, 10);
    }

    /**
     * The unit and total cost the line's layer opens at.
     *
     * @return array{unit: ?string, total: ?string}
     */
    private function landedCost(PurchaseOrderItem $item, string $quantity, string $arrivalShare, bool $funded): array
    {
        if ($item->final_unit_cost === null) {
            return ['unit' => null, 'total' => null];
        }

        // The deal agreed this cost when it was funded; its arrival share is its expense instead.
        if ($funded) {
            $unit = (string) $item->final_unit_cost;

            return ['unit' => $unit, 'total' => Money::round(bcmul($unit, $quantity, 6))];
        }

        $total = bcadd(
            bcadd((string) $this->baseCostOf($item, $quantity), (string) ($item->allocated_additional_cost ?? '0'), 10),
            $arrivalShare,
            10,
        );

        return [
            'unit' => Money::roundTo(bcdiv($total, $quantity, 10), 3),
            'total' => Money::round($total),
        ];
    }

    /**
     * A funded line's share is a deal expense, which is money out of a drawer — refused when the
     * cost was on the vendor's bill or owed to a payable.
     *
     * @param  array<int, string>  $shares  Cents per line id.
     * @param  array<int, SupplyFunding|null>  $funding
     *
     * @throws ArrivalCostOnFundedLineNeedsADrawer
     */
    private function guardFundedShare(PurchaseOrderAdditionalCostData $cost, array $shares, array $funding, string $field): void
    {
        $fundedCents = $this->fundedCents($shares, $funding);

        if ($fundedCents === []) {
            return;
        }

        $account = $cost->treasuryAccountId === null ? null : TreasuryAccount::query()->find($cost->treasuryAccountId);

        if ($account === null || $account->kind === AccountKind::Payable) {
            throw ArrivalCostOnFundedLineNeedsADrawer::make($cost->name, $field);
        }
    }

    /**
     * What a cost puts on each deal, in cents — the shares of the lines it bought. Empty when no
     * line it falls on is funded.
     *
     * @param  array<int, string>  $shares
     * @param  array<int, SupplyFunding|null>  $funding
     * @return array<int, string> Cents per deal id.
     */
    private function fundedCents(array $shares, array $funding): array
    {
        $byDeal = [];

        foreach ($shares as $itemId => $cents) {
            $deal = $funding[$itemId] ?? null;

            if ($deal === null || bccomp($cents, '0', 0) === 0) {
                continue;
            }

            $byDeal[$deal->dealId] = bcadd($byDeal[$deal->dealId] ?? '0', $cents, 0);
        }

        return $byDeal;
    }

    /**
     * The money behind one arrival cost: each deal's share as its expense, and the company's own
     * share out of the account that paid — or nothing here, when the vendor's bill carries it.
     *
     * @param  array<int, string>  $shares
     * @param  array<int, SupplyFunding|null>  $funding
     */
    private function chargeTheMoney(
        PurchaseOrder $order,
        PurchaseOrderAdditionalCost $cost,
        array $shares,
        array $funding,
        int $actorId,
    ): void {
        $dealsCents = '0';

        foreach ($this->fundedCents($shares, $funding) as $dealId => $cents) {
            $this->investors->recordSupplyExpense($dealId, new DealExpenseData(
                kind: DealExpenseKind::Other,
                name: (string) $cost->name,
                amount: LargestRemainder::fromCents($cents),
                incurredOn: now()->toDateString(),
                notes: "تكاليف وصول أمر الشراء {$order->getKey()}",
                treasuryAccountId: $cost->treasury_account_id,
                sourceType: $cost->getMorphClass(),
                sourceId: (int) $cost->getKey(),
            ), $actorId);

            $dealsCents = bcadd($dealsCents, $cents, 0);
        }

        ($this->costExpense)(
            $cost,
            $actorId,
            amount: LargestRemainder::fromCents(bcsub(LargestRemainder::toCents((string) $cost->amount), $dealsCents, 0)),
        );
    }
}
