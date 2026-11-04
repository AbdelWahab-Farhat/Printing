<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Exceptions\CostRefundAlreadyReversed;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderCostRefund;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Takes back a refund recorded in error: the expense stands again for that much, on the account
 * that paid. The row stays, stamped with who and why — the mirror of {@see RefundAdditionalCost}.
 *
 * @throws CostRefundAlreadyReversed
 */
final class ReverseCostRefund
{
    public function __construct(
        private readonly SyncAdditionalCostExpense $costExpense,
        private readonly TreasuryService $treasury,
    ) {}

    public function __invoke(
        PurchaseOrder $order,
        PurchaseOrderAdditionalCost $cost,
        PurchaseOrderCostRefund $refund,
        string $reason,
        int $actorId,
    ): PurchaseOrderCostRefund {
        return DB::transaction(function () use ($order, $cost, $refund, $reason, $actorId): PurchaseOrderCostRefund {
            // The cost first, the order RefundAdditionalCost takes its locks in.
            $cost = PurchaseOrderAdditionalCost::query()->whereKey($cost->getKey())->lockForUpdate()->firstOrFail();
            $refund = PurchaseOrderCostRefund::query()->whereKey($refund->getKey())->lockForUpdate()->firstOrFail();

            if ($refund->isReversed()) {
                throw CostRefundAlreadyReversed::make();
            }

            $this->treasury->guardManualEntry($cost->treasuryAccount, now(), 'reason');

            $standing = bcadd($cost->refundableAmount(), (string) $refund->amount, 2);

            $refund->reversed_at = Carbon::now();
            $refund->reversed_by = $actorId;
            $refund->reversal_reason = $reason;
            $refund->save();

            ($this->costExpense)(
                $cost,
                $actorId,
                amount: $standing,
                reason: "التراجع عن استرداد من تكلفة {$cost->name} — أمر الشراء {$order->getKey()}: {$reason}",
            );

            return $refund;
        });
    }
}
