<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;

/**
 * Puts a vendor payment, credit or opening debt that is already written onto its vendor's
 * «علينا», dated when it was paid — for rows that reached the drawer but not the payable: those
 * from before «علينا» existed, and those on an old order just brought in (§٢٠).
 *
 * Does nothing for a row already on the payable, so it is safe to call twice.
 */
final class PostVendorPaymentToPayable
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /** True when it posted, false when the row was already there. */
    public function __invoke(VendorPayment $payment): bool
    {
        $payable = $this->treasury->payableForVendor((int) $payment->vendor_id, (string) $payment->vendor?->name);

        $posted = $this->treasury->liveMovementsOf($payment->getMorphClass(), (int) $payment->getKey())
            ->contains(fn ($movement) => (int) $movement->account_id === (int) $payable->getKey());

        if ($posted) {
            return false;
        }

        $about = $payment->purchase_order_id === null ? '' : " — أمر الشراء {$payment->purchase_order_id}";

        [$direction, $kind, $notes] = match ($payment->type) {
            VendorPaymentType::Payment => [MovementDirection::In, MovementKind::VendorPayment, "دفعة من «{$payment->treasuryAccount?->name}»{$about}"],
            VendorPaymentType::Credit => [MovementDirection::In, MovementKind::VendorCredit, "خصم من المورد{$about}"],
            default => [MovementDirection::Out, MovementKind::Opening, 'دَين افتتاحي'],
        };

        $this->treasury->post(new MovementData(
            accountId: (int) $payable->getKey(),
            direction: $direction,
            kind: $kind,
            amount: (string) $payment->amount,
            occurredAt: $payment->paid_at,
            sourceType: $payment->getMorphClass(),
            sourceId: (int) $payment->getKey(),
            notes: $notes,
            recordedBy: $payment->recorded_by === null ? null : (int) $payment->recorded_by,
            counterpartAccountId: $payment->treasury_account_id === null ? null : (int) $payment->treasury_account_id,
        ));

        return true;
    }
}
