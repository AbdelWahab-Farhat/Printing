<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Exceptions\VendorPaymentRefused;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\PurchaseOrder\Queries\VendorPaymentSummary;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Support\Facades\DB;

/**
 * Undoes a vendor payment, an opening debt or a credit, entered in error.
 *
 * Every movement it posted is mirrored — the drawer the money left, and the vendor's payable —
 * so the money and the debt are back where they were. Never refused for balance, because
 * undoing a mistake is not spending.
 */
final class ReverseVendorPayment
{
    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly VendorPaymentSummary $summary,
    ) {}

    public function __invoke(VendorPayment $payment, string $reason, ?User $actor): VendorPayment
    {
        return DB::transaction(function () use ($payment, $reason, $actor): VendorPayment {
            $locked = VendorPayment::query()->whereKey($payment->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->isReversible()) {
                throw VendorPaymentRefused::cannotBeReversed();
            }

            // Undoing a debt lowers what is owed, and «لا دفع مقدّم» holds for that too: a debt
            // already paid off cannot vanish and leave the vendor holding the payments (§٢٠).
            if ($locked->type === VendorPaymentType::OpeningDebt) {
                Vendor::query()->whereKey($locked->vendor_id)->lockForUpdate()->first();

                $owed = $this->summary->forVendor((int) $locked->vendor_id)['owed'];

                if (bccomp((string) $locked->amount, $owed, 2) > 0) {
                    throw VendorPaymentRefused::debtAlreadyPaid($owed);
                }
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
