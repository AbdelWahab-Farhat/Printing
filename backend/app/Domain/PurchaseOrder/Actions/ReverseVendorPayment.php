<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * Undoes a vendor payment, or an opening debt, entered in error.
 *
 * The payment's movement is mirrored on the drawer it left, so the money is back where it was —
 * never refused for balance, because undoing a mistake is not spending.
 */
final class ReverseVendorPayment
{
    public function __construct(private readonly TreasuryService $treasury) {}

    public function __invoke(VendorPayment $payment, string $reason, ?User $actor): VendorPayment
    {
        return DB::transaction(function () use ($payment, $reason, $actor): VendorPayment {
            $locked = VendorPayment::query()->whereKey($payment->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->isReversible()) {
                throw VendorPaymentRefused::cannotBeReversed();
            }

            $actorId = $actor?->getKey() === null ? null : (int) $actor->getKey();

            $reversal = new VendorPayment([
                'amount' => (string) $locked->amount,
                'reference' => $locked->reference,
                'paid_at' => now(),
                'notes' => $reason,
            ]);

            $reversal->vendor_id = $locked->vendor_id;
            $reversal->purchase_order_id = $locked->purchase_order_id;
            $reversal->type = VendorPaymentType::Reversal;
            $reversal->reverses_payment_id = $locked->getKey();
            $reversal->recorded_by = $actorId;
            $reversal->save();

            $this->treasury->reverseSource($locked->getMorphClass(), (int) $locked->getKey(), $reason, $actorId);

            return $reversal;
        });
    }
}
