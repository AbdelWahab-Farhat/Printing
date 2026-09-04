<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\Investor;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Investor
 */
class InvestorResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            // What staff say out loud — «حساب I7» — and the safe half of this row to read down a
            // phone line.
            'code' => $this->code,
            'name' => $this->name,
            'phone' => $this->phone,
            'notes' => $this->notes,
            'is_active' => (bool) $this->is_active,

            // Whether he can sign in. A fact about the row rather than a role name, so renaming
            // the role cannot change what the app believes.
            'has_login' => $this->user_id !== null,

            // Present only where the caller asked for balances — a list of fifty investors does
            // not walk fifty ledgers to draw a table.
            'balances' => $this->when(
                isset($this->balances),
                fn (): array => $this->balances,
            ),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
