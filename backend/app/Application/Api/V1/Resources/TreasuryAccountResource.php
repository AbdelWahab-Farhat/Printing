<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TreasuryAccount
 */
class TreasuryAccountResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $balance = $this->resource->getAttribute('balance');

        return [
            'id' => $this->id,
            'name' => $this->name,
            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),
            'currency' => $this->currency,

            'holder_user_id' => $this->holder_user_id,
            'holder' => $this->whenLoaded('holder', fn (): ?array => $this->holder === null ? null : [
                'id' => $this->holder->id,
                'name' => $this->holder->name,
                'employee_code' => $this->holder->employee_code,
            ]),

            'is_default' => (bool) $this->is_default,
            'is_active' => (bool) $this->is_active,
            // The Nawris account: the webhook writes to it, and it cannot be switched off.
            'is_system' => $this->isSystem(),
            // Custody fills from customers and empties by settlement — the app hides the hand
            // operations that would be refused on it.
            'is_spendable' => $this->kind->spendable(),

            // Custody only: where its money goes at settlement when nobody picks.
            'settles_into_account_id' => $this->settles_into_account_id,
            'settles_into' => $this->whenLoaded('settlesInto', fn (): ?array => $this->settlesInto === null ? null : [
                'id' => $this->settlesInto->id,
                'name' => $this->settlesInto->name,
            ]),

            // «يُجمَع عند التسوية»: false keeps its order money where it landed (§١٨).
            'is_collected' => (bool) ($this->is_collected ?? true),
            // Cash only: the «استلام مكتب» branch whose cash lands here (§١٩).
            'pickup_city_id' => $this->pickup_city_id,

            // Present when the caller asked for balances; a string like every figure of money.
            'balance' => $balance === null ? null : (string) $balance,

            'notes' => $this->notes,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
