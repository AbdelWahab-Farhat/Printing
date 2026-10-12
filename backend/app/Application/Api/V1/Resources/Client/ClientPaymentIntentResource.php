<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One online top-up attempt, as the customer's app follows it. **No provider ids, no raw answer.**
 *
 * @mixin PaymentIntent
 */
class ClientPaymentIntentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            /** The public id — what the app polls and sends the OTP to. */
            'id' => $this->uuid,
            'method' => $this->method->value,
            'method_label' => $this->method->label(),
            'flow' => $this->flow->value,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            /** The app can stop asking. */
            'is_final' => $this->status->isFinal() || $this->status === IntentStatus::Failed || $this->status === IntentStatus::Expired,
            // Not once EzonePay took a code: the payment is being confirmed, and the app waits.
            'requires_otp' => $this->flow === PaymentFlow::Otp && $this->status === IntentStatus::Pending && $this->otp_accepted_at === null,
            /** The code was taken; the server is asking EzonePay — «نتحقق من الدفع». */
            'is_confirming' => $this->resource->isConfirming(),
            'otp_attempts_left' => max(0, (int) config('ezone_pay.otp_max_attempts', 3) - (int) $this->otp_attempts),
            'payment_url' => $this->status === IntentStatus::Pending ? $this->payment_url : null,
            /** What reaches the wallet. */
            'amount' => (string) $this->net_amount,
            /** What is charged. */
            'total' => (string) $this->gross_amount,
            'fee' => $this->resource->customerFee(),
            'order_id' => $this->order_id,
            'failure_reason' => $this->status === IntentStatus::Failed ? $this->failure_reason : null,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'succeeded_at' => $this->succeeded_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
