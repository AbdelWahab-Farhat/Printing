<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\DTOs\RefundAdditionalCostData;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Exceptions\AdditionalCostNotRefundable;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderCostRefund;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * Brings money back on a cost paid from a drawer or owed to a manual payable — on an order that
 * was cancelled, or any other past `new`. PURCHASE-ORDER-ARRIVAL-COSTS.md §7.
 *
 * **Money only.** The cost's `expense` movement is reposted at what is left, on the account that
 * paid; the cost row, the order's totals, what the vendor is owed and the stock's cost all stay
 * as they are — the owner's decision, 2026-11-04.
 *
 * **What may come back is what still stands on the treasury**, not the cost's amount. A deal's
 * share of an arrival cost left as that deal's expense and never stood here, so it cannot be
 * refunded by accident: it follows its receipt.
 *
 * **Refused on a `new` order** — editing the cost there already gives the money back, and no
 * status returns to `new`, so a refund and the order form never meet.
 *
 * @throws AdditionalCostNotRefundable
 */
final class RefundAdditionalCost
{
    public function __construct(
        private readonly SyncAdditionalCostExpense $costExpense,
        private readonly TreasuryService $treasury,
    ) {}

    public function __invoke(
        PurchaseOrder $order,
        PurchaseOrderAdditionalCost $cost,
        RefundAdditionalCostData $data,
    ): PurchaseOrderCostRefund {
        if ($order->status === PurchaseOrderStatus::New) {
            throw AdditionalCostNotRefundable::orderStillEditable();
        }

        return DB::transaction(function () use ($order, $cost, $data): PurchaseOrderCostRefund {
            // Locked so two refunds cannot both read the same figure and together pass it. A
            // receipt reversal that got here first has removed the cost: this then finds nothing.
            $cost = PurchaseOrderAdditionalCost::query()->whereKey($cost->getKey())->lockForUpdate()->firstOrFail();

            if (! $cost->isPaidElsewhere()) {
                throw AdditionalCostNotRefundable::onVendorBill();
            }

            $left = $cost->refundableAmount();
            $amount = Money::round($data->amount);

            if (bccomp($left, '0', 2) === 0) {
                throw AdditionalCostNotRefundable::nothingLeft();
            }

            if (bccomp($amount, $left, 2) > 0) {
                throw AdditionalCostNotRefundable::moreThanLeft($left);
            }

            $this->treasury->guardManualEntry($cost->treasuryAccount, now(), 'amount');

            $refund = new PurchaseOrderCostRefund(['amount' => $amount, 'reason' => $data->reason]);
            $refund->additional_cost_id = $cost->getKey();
            $refund->recorded_by = $data->recordedBy;
            $refund->save();

            ($this->costExpense)(
                $cost,
                $data->recordedBy,
                amount: bcsub($left, $amount, 2),
                reason: "استرداد من تكلفة {$cost->name} — أمر الشراء {$order->getKey()}: {$data->reason}",
            );

            return $refund;
        });
    }
}
