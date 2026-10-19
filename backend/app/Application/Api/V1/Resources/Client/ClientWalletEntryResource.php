<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One row of the customer's own wallet, for the customer app.
 *
 * **Only what the customer may know** (CUSTOMER-APP-DESIGN §4): no account the money landed in, no
 * colleague's name, and no hand-written reason — an adjustment's reason is the shop's note to
 * itself. An order's rows carry the order, which the customer can open.
 *
 * @mixin CustomerWalletEntry
 */
class ClientWalletEntryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type->value,
            'type_label' => $this->type->label(),
            /** `in` adds to the wallet, `out` takes from it. */
            'direction' => $this->resource->isCredit() ? 'in' : 'out',
            'amount' => (string) $this->amount,
            /** How a top-up came in: `cash` · `bank_transfer` · `bank_card` · `libyana` · `online`. */
            'method' => $this->method?->value,
            /** The EzonePay method an online top-up came through (103 ون باي…) — its logo in the app. */
            'online_method' => $this->onlineMethod()?->value,
            /** «كاش», or the EzonePay method's own name («ون باي») rather than «دفع إلكتروني». */
            'method_label' => $this->onlineMethod()?->label() ?? $this->method?->label(),
            'order_id' => $this->order_id,
            /** The order's code as the app writes it, bare. */
            'order_code' => $this->attached('orderCode'),
            'description' => $this->type === WalletEntryType::OrderPayment || $this->type === WalletEntryType::OrderRefund
                ? $this->notes
                : null,
            'is_reversed' => $this->resource->isReversed(),
            'occurred_at' => $this->occurred_at?->toIso8601String(),
        ];
    }

    private function onlineMethod(): ?OnlineMethod
    {
        $method = $this->attached('onlineMethod');

        return $method instanceof OnlineMethod ? $method : null;
    }

    /**
     * What the controller attached from the orders and online payments (`WalletController::
     * attachNames`), or null where it attached nothing.
     */
    private function attached(string $name): mixed
    {
        return $this->resource->relationLoaded($name) ? $this->resource->getRelation($name) : null;
    }
}
