<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;

/**
 * Puts a purchase order's total on its vendor's payable — owed from the moment the order is
 * raised, at its full landed total (TREASURY-DESIGN §٢٠, the owner's decision).
 *
 * Run after anything that can change what the order owes: raising it, editing its lines or
 * extra costs or vendor, cancelling it. Nothing is owed on a cancelled order, on one from before
 * the treasury (its debt, if any, is an opening debt), or on one with no costs yet. The
 * treasury reposts only when the figure or the vendor actually changed.
 */
final class SyncPurchaseOrderDebt
{
    public function __construct(private readonly TreasuryService $treasury) {}

    public function __invoke(PurchaseOrder $order, ?int $actorId): void
    {
        $owes = ! $order->predates_treasury
            && $order->status !== PurchaseOrderStatus::Cancelled
            && $order->total_amount !== null;

        $code = (string) $order->getKey();
        $account = null;

        if ($owes) {
            /** @var Vendor $vendor */
            $vendor = Vendor::query()->findOrFail($order->vendor_id);
            $account = (int) $this->treasury->payableForVendor((int) $vendor->getKey(), (string) $vendor->name)->getKey();
        }

        $this->treasury->syncDebt(
            sourceType: $order->getMorphClass(),
            sourceId: (int) $order->getKey(),
            accountId: $account,
            amount: $owes ? (string) $order->total_amount : '0',
            firstPostedAt: $order->created_at ?? now(),
            notes: "أمر الشراء {$code}",
            reason: $order->status === PurchaseOrderStatus::Cancelled
                ? "إلغاء أمر الشراء {$code}"
                : "تعديل أمر الشراء {$code}",
            actorId: $actorId,
        );
    }
}
