<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Investor\Actions\FundPurchaseOrder;
use App\Domain\Investor\Actions\PurchaseFromFund;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;

/**
 * Writes what funding a dollar order fixed — USD-ACCOUNTS.md §٥, the owner's decision of
 * 2026-11-10: the order's `funding_rate`, and each funded line's `funded_cost` in dinars at it.
 *
 * Called by {@see FundPurchaseOrder} and {@see PurchaseFromFund} inside their transaction, with
 * the line costs their snapshot worked out. **An Action with no dependencies, on purpose**: the
 * Investment actions cannot ask `PurchaseOrderService` — it builds `ReceivePurchaseOrder`, which
 * builds `InvestorService`, and the container would resolve that ring forever (see
 * `FundingSnapshotQuery`).
 *
 * A rate already on the order is kept: a second funding on the order's other lines is bought at
 * the same rate, so the order has one funding rate to compare with its arrival rate. Nothing on a
 * dinar order.
 */
final class FixFundingRate
{
    /**
     * @param  array<int, string>  $lineCosts  Dinars per funded stock item id.
     */
    public function __invoke(int $purchaseOrderId, string $rate, array $lineCosts): void
    {
        $order = PurchaseOrder::query()->findOrFail($purchaseOrderId);

        if (! $order->isDollar()) {
            return;
        }

        if ($order->funding_rate === null) {
            $order->forceFill(['funding_rate' => $rate])->save();
        }

        foreach ($order->items()->whereIn('stock_item_id', array_keys($lineCosts))->get() as $item) {
            $item->forceFill(['funded_cost' => $lineCosts[(int) $item->stock_item_id]])->save();
        }
    }
}
