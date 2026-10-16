<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One online top-up attempt, for «المدفوعات الإلكترونية». CUSTOMER-WALLET §٥.
 *
 * @mixin PaymentIntent
 */
class PaymentIntentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $user = $user instanceof User ? $user : null;

        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'customer' => $this->whenLoaded('customer', fn (): ?array => $this->customer === null ? null : [
                'id' => $this->customer->id,
                'code' => $this->customer->code,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
            ]),
            'order_id' => $this->order_id,
            'method' => $this->method->value,
            'method_label' => $this->method->label(),
            'flow' => $this->flow->value,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'net_amount' => (string) $this->net_amount,
            'gross_amount' => (string) $this->gross_amount,
            'customer_fee' => $this->resource->customerFee(),
            'fee_rate' => (string) $this->fee_rate,
            'fee_payer' => $this->fee_payer->value,
            'fee_payer_label' => $this->fee_payer->label(),
            /** What EzonePay kept — known once the payment is credited. */
            'provider_fee' => $this->provider_fee === null ? null : (string) $this->provider_fee,
            'reference' => $this->our_reference,
            'provider_transaction_id' => $this->provider_transaction_id,
            'otp_attempts' => (int) $this->otp_attempts,
            'failure_reason' => $this->failure_reason,
            'wallet_entry_id' => $this->wallet_entry_id,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'succeeded_at' => $this->succeeded_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            /** «إعادة التحقق» — for an attempt not credited and not waiting for a person. */
            'can_recheck' => ! in_array($this->status, [IntentStatus::Succeeded, IntentStatus::NeedsReview], true)
                && ($user?->can(PermissionName::ReconcileOnlinePayments->value) ?? false),
        ];
    }
}
