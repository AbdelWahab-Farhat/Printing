<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Exceptions\DesignFeeCannotChange;
use App\Domain\Order\Exceptions\DesignFeeRequiresPermission;
use App\Domain\Order\Exceptions\DiscountExceedsTotal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * Sets «أجرة التصميم», what the customer pays for the design. See ORDER-DESIGN-FEE.md.
 *
 * **A route of its own, never the edit form.** Employees do not see the fee, so every edit they
 * send carries a number they never had; `UpdateOrder` leaves the column alone for that reason.
 *
 * **A fee above zero makes the design ours.** `RecalculateOrderTotals` only charges a fee on
 * «تصميم من عندنا», so a fee left on «تصميم العميل» would be a price nobody pays. Clearing it
 * leaves the source as it is: the design was still ours.
 *
 * **Every call is a decision**, zero included: `design_fee_set_at` is written, and from then on
 * no approved ticket fills the fee from «أجرة المصمم» again.
 */
final class SetOrderDesignFee
{
    public function __construct(
        private readonly RecalculateOrderTotals $recalculateTotals,
        private readonly RecalculateOrderPayments $recalculatePayments,
    ) {}

    /**
     * @throws DesignFeeRequiresPermission
     * @throws DesignFeeCannotChange
     * @throws DiscountExceedsTotal
     */
    public function __invoke(Order $order, string $fee, ?User $actor): Order
    {
        if (! $actor?->can(PermissionName::SetOrderDesignFee->value)) {
            throw DesignFeeRequiresPermission::make();
        }

        $fee = Money::normalize($fee);

        return DB::transaction(function () use ($order, $fee, $actor): Order {
            // The lock every money move on an order takes first.
            $locked = Order::withTrashed()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            $this->guardEditable($locked);

            $locked->forceFill([
                'design_fee' => $fee,
                'design_fee_set_at' => now(),
                'design_fee_set_by' => $actor?->getKey(),
                ...(bccomp($fee, '0', Money::SCALE) > 0 ? ['design_source' => DesignSource::InHouse] : []),
            ])->save();

            ($this->recalculateTotals)($locked->load('items'));
            ($this->recalculatePayments)($locked->refresh());

            return $locked->refresh();
        });
    }

    /**
     * @throws DesignFeeCannotChange
     */
    private function guardEditable(Order $order): void
    {
        if ($order->trashed()) {
            throw DesignFeeCannotChange::archived();
        }

        if ($order->is_compensation) {
            throw DesignFeeCannotChange::compensation();
        }

        if (! $order->designFeeIsEditable()) {
            throw DesignFeeCannotChange::closed($order->status);
        }
    }
}
