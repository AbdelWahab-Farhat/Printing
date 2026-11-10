<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Queries;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\PurchaseOrder\Support\PlannedDinarShares;

/**
 * What an order looks like to whoever is about to finance it: its shelves, its cost, and whether
 * it is still early enough to say who paid for it.
 *
 * **A query rather than a method on {@see PurchaseOrderService}, and that is not a style
 * preference.** `PurchaseOrderService` constructs `ReceivePurchaseOrder`, which constructs
 * `InvestorService`; an Investment action asking the service back would close a ring the
 * container resolves forever. A read class that touches nothing but its own models cannot.
 *
 * `total_cost` is the landed figure — `final_total_cost` per line, which already carries each
 * line's share of the shipping and customs typed on the order
 * ({@see AllocatePurchaseOrderAdditionalCosts}). It is what the funding screen holds the money
 * up against, so the man putting 30,000 into a 40,000 shipment sees both numbers.
 */
final class FundingSnapshotQuery
{
    /**
     * @return array{
     *     id: int,
     *     status: string,
     *     is_fundable: bool,
     *     stock_item_ids: list<int>,
     *     line_costs: array<int, string>,
     *     total_cost: string,
     *     is_dollar: bool,
     *     funding_rate: ?string,
     *     needs_rate: bool,
     * }|null
     *
     * **A dollar order's costs come back in dinars**, at the rate it was funded at before, or else
     * at `$rate` — what the funding screen asks, «سعر النظام» unless changed (USD-ACCOUNTS.md §٥).
     * Investors' money is dinars, so every figure it is held against is too: each line's dollars
     * times the rate, and its share of the dinar costs planned on the order as it is
     * ({@see PlannedDinarShares}). With neither rate, `needs_rate` says so and the costs are
     * dollars — the funding actions refuse before reading them.
     */
    public function __invoke(int $purchaseOrderId, bool $lock = false, ?string $rate = null): ?array
    {
        $query = PurchaseOrder::query()->whereKey($purchaseOrderId);

        // **Read under the row's own lock when a decision hangs on it.** Two people funding one
        // order at the same moment would otherwise both read «not funded yet» and both pass; the
        // second insert would then die on the unique index as a 500 instead of being refused in
        // Arabic. The `RecordWalletEntry` discipline, applied to the document rather than the
        // wallet.
        $order = ($lock ? $query->lockForUpdate() : $query)->first();

        if ($order === null) {
            return null;
        }

        $lines = $order->items()->get();

        $fundingRate = ! $order->isDollar() ? null : ($order->funding_rate !== null ? (string) $order->funding_rate : $rate);
        $planned = $fundingRate === null ? [] : PlannedDinarShares::of($order, $lines->keyBy('id'));

        $total = '0.00';
        $lineCosts = [];

        foreach ($lines as $line) {
            $cost = $fundingRate === null
                ? (string) ($line->final_total_cost ?? '0.00')
                : Money::round(PlannedDinarShares::fundedLineCost($line, $fundingRate, $planned[$line->getKey()] ?? '0'));

            $total = bcadd($total, $cost, 2);
            // Keyed by shelf, because funding is per line: a deal taking one line of three is
            // held up against that line's landed cost, not the lorry's.
            $lineCosts[(int) $line->stock_item_id] = $cost;
        }

        $shelves = $lines
            ->pluck('stock_item_id')
            ->map(fn ($id) => (int) $id)
            ->unique()
            ->values()
            ->all();

        return [
            'id' => (int) $order->getKey(),
            'status' => $order->status->value,
            // Ownership is declared before the lorry arrives — that is the whole of «الموظف لا
            // يختار الصفقة». Once a single line has been received there are cost layers on the
            // shelf that this deal can never be stamped onto.
            'is_fundable' => $order->status === PurchaseOrderStatus::New && $shelves !== [],
            'stock_item_ids' => $shelves,
            'line_costs' => $lineCosts,
            'total_cost' => $total,
            'is_dollar' => $order->isDollar(),
            // The rate the costs above were worked out at — the order's own, or the one asked.
            'funding_rate' => $fundingRate,
            'needs_rate' => $order->isDollar() && $fundingRate === null,
        ];
    }
}
