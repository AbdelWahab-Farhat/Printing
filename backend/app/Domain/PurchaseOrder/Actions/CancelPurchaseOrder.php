<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderIsPaid;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderTransitionNotAllowed;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Queries\VendorPaymentSummary;
use Illuminate\Support\Facades\DB;

/**
 * Writes a purchase order off. Allowed from {@see PurchaseOrderStatus::New} or
 * {@see PurchaseOrderStatus::Arrived} only — a completed order has nothing left to cancel, and
 * a cancelled one already is one.
 *
 * **Its debt goes with it**, and so it may not be cancelled while anything was paid or credited
 * on it: the vendor would be left holding money the company no longer owes — «لا دفع مقدّم»,
 * TREASURY-DESIGN §٢٠. Reverse those first.
 *
 * @throws PurchaseOrderTransitionNotAllowed
 * @throws PurchaseOrderIsPaid
 */
final class CancelPurchaseOrder
{
    public function __construct(
        private readonly SyncPurchaseOrderDebt $syncDebt,
        private readonly VendorPaymentSummary $payments,
    ) {}

    public function __invoke(PurchaseOrder $order): PurchaseOrder
    {
        $from = $order->status;

        if (! $from->canMoveTo(PurchaseOrderStatus::Cancelled)) {
            throw PurchaseOrderTransitionNotAllowed::make($from, PurchaseOrderStatus::Cancelled);
        }

        $settled = $this->payments->settledOn((int) $order->getKey());

        if (bccomp($settled, '0', 2) > 0) {
            throw PurchaseOrderIsPaid::cannotBeCancelled($settled);
        }

        return DB::transaction(function () use ($order): PurchaseOrder {
            $order->status = PurchaseOrderStatus::Cancelled;
            $order->save();

            ($this->syncDebt)($order, null);

            return $order;
        });
    }
}
