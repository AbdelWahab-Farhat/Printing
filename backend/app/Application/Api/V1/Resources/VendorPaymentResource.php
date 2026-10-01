<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\PurchaseOrder\Models\VendorPayment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin VendorPayment
 */
class VendorPaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'vendor_id' => $this->vendor_id,
            'purchase_order_id' => $this->purchase_order_id,

            'type' => $this->type->value,
            'type_label' => $this->type->label(),
            'amount' => (string) $this->amount,

            'method' => $this->method?->value,
            'method_label' => $this->method?->label(),
            'treasury_account' => $this->whenLoaded('treasuryAccount', fn (): ?array => $this->treasuryAccount === null ? null : [
                'id' => $this->treasuryAccount->id,
                'name' => $this->treasuryAccount->name,
            ]),

            'reference' => $this->reference,
            'has_receipt' => $this->hasReceipt(),
            'receipt_url' => $this->receiptUrl(),

            'paid_at' => $this->paid_at?->toIso8601String(),
            'notes' => $this->notes,

            'is_reversed' => $this->isReversed(),
            'is_reversible' => $this->isReversible(),
            'reverses_payment_id' => $this->reverses_payment_id,

            'recorder' => $this->whenLoaded('recorder', fn (): ?array => $this->recorder === null ? null : [
                'id' => $this->recorder->id,
                'name' => $this->recorder->name,
                'employee_code' => $this->recorder->employee_code,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
