<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * «التراجع عن تسوية الدفعة» — the payment's money goes back to the account it landed in, because
 * it was settled to the wrong place, or before it really arrived. TREASURY-DESIGN §٢٣.
 *
 * **A reason is required**, as for every money correction here. The reversal is written beside
 * the settlement — nothing is deleted — so the account's ledger shows both.
 *
 * **Refused while the order is «تم التسوية»**: the order's settlement carried whatever was left,
 * and money put back now would sit in custody with nothing left to settle it. Un-settle the order
 * first ({@see UnsettleOrder}); that leaves this payment's settlement standing, to be undone here.
 */
final class UnsettleOrderPayment
{
    public function __construct(private readonly TreasuryService $treasury) {}

    public function __invoke(Order $order, OrderPayment $payment, string $reason, ?User $actor = null): OrderPayment
    {
        return DB::transaction(function () use ($order, $payment, $reason, $actor): OrderPayment {
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->first();

            if ($refusal = $payment->unsettlementRefusal($locked)) {
                throw $refusal;
            }

            $this->treasury->unsettlePayment(
                (int) $payment->getKey(),
                trim($reason),
                $actor?->getKey() === null ? null : (int) $actor->getKey(),
            );

            return $payment->refresh();
        });
    }
}
