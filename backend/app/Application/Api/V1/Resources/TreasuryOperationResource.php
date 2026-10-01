<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TreasuryOperation
 */
class TreasuryOperationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $account = fn (?TreasuryAccount $account): ?array => $account === null ? null : [
            'id' => $account->id,
            'name' => $account->name,
            'kind' => $account->kind->value,
        ];

        $reversed = $this->relationLoaded('reversedBy') ? $this->reversedBy !== null : $this->isReversed();

        return [
            'id' => $this->id,
            'type' => $this->type->value,
            'type_label' => $this->type->label(),
            'amount' => (string) $this->amount,

            'from_account_id' => $this->from_account_id,
            'from_account' => $this->whenLoaded('fromAccount', fn () => $account($this->fromAccount)),
            'to_account_id' => $this->to_account_id,
            'to_account' => $this->whenLoaded('toAccount', fn () => $account($this->toAccount)),

            'category' => $this->whenLoaded('category', fn (): ?array => $this->category === null ? null : [
                'id' => $this->category->id,
                'name' => $this->category->name,
            ]),
            'employee' => $this->whenLoaded('employee', fn (): ?array => $this->employee === null ? null : [
                'id' => $this->employee->id,
                'name' => $this->employee->name,
            ]),

            'order_id' => $this->order_id,
            'system_balance' => $this->system_balance === null ? null : (string) $this->system_balance,
            'counted_balance' => $this->counted_balance === null ? null : (string) $this->counted_balance,

            'occurred_at' => $this->occurred_at?->toIso8601String(),
            'notes' => $this->notes,

            'is_reversal' => $this->isReversal(),
            'is_reversed' => $reversed,
            'is_reversible' => $this->type->isReversibleByHand() && ! $this->isReversal() && ! $reversed,
            'reverses_operation_id' => $this->reverses_operation_id,

            'recorder' => $this->whenLoaded('recorder', fn (): ?array => $this->recorder === null ? null : [
                'id' => $this->recorder->id,
                'name' => $this->recorder->name,
                'employee_code' => $this->recorder->employee_code,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
