<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One line of an account's history: date, amount, kind, who, the order it belongs to, the note.
 *
 * @mixin TreasuryMovement
 */
class TreasuryMovementResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // Only an account's own ledger selects it; «المصاريف» spans accounts and has no balance.
        $balanceAfter = $this->resource->getAttributes()['balance_after'] ?? null;
        $operation = $this->relationLoaded('operation') ? $this->operation : null;

        return [
            'id' => $this->id,
            'account_id' => $this->account_id,
            // «المصاريف» reads every account at once, so each line names its own.
            'account' => $this->whenLoaded('account', fn (): ?array => $this->account === null ? null : [
                'id' => $this->account->id,
                'name' => $this->account->name,
                'kind' => $this->account->kind->value,
            ]),

            'direction' => $this->direction->value,
            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),
            'amount' => (string) $this->amount,
            // Signed, so a list can print «+50» and «−300» without knowing the rule.
            'signed_amount' => $this->signedAmount(),
            'balance_after' => $balanceAfter === null ? null : number_format((float) $balanceAfter, 2, '.', ''),

            'occurred_at' => $this->occurred_at?->toIso8601String(),

            'source_type' => $this->source_type,
            'source_type_label' => AuditSubject::tryFrom((string) $this->source_type)?->label(),
            'source_id' => $this->source_id,
            'operation_id' => $this->operation_id,
            'order_id' => $this->order_id,

            'counterpart_account' => $this->whenLoaded('counterpartAccount', fn (): ?array => $this->counterpartAccount === null ? null : [
                'id' => $this->counterpartAccount->id,
                'name' => $this->counterpartAccount->name,
            ]),

            'category' => $operation?->category === null ? null : [
                'id' => $operation->category->id,
                'name' => $operation->category->name,
            ],
            'employee' => $operation?->employee === null ? null : [
                'id' => $operation->employee->id,
                'name' => $operation->employee->name,
            ],

            'is_reversal' => $this->isReversal(),
            'reverses_movement_id' => $this->reverses_movement_id,
            'is_reversible' => $this->reversibleBy($request, $operation),
            // **أعُكس هذا السطر** — فيرسمه التطبيق مشطوباً بعد كل تحديث، لا في لحظة عكسه وحدها.
            // من علاقةٍ حمّلها السجلُّ للصفحة كلِّها؛ وسطرٌ يُقرأ وحده يسأل سؤالاً واحداً.
            'is_reversed' => $this->relationLoaded('reversedBy')
                ? $this->reversedBy !== null
                : $this->reversedBy()->exists(),

            'notes' => $this->notes,

            // «غير مراجَعة / تمت المراجعة» on a line a customer's payment or refund moved —
            // `{is_reviewed, reviewed_at, reviewer}`, null when that payment asks for no review.
            // Only the account ledger attaches it; every other list leaves the key out.
            'payment_review' => $this->whenLoaded('paymentReview'),

            'recorder' => $this->whenLoaded('recorder', fn (): ?array => $this->recorder === null ? null : [
                'id' => $this->recorder->id,
                'name' => $this->recorder->name,
                'employee_code' => $this->recorder->employee_code,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * أيعكس هذا القارئُ السطرَ من هنا؟ — بدل أن يخمّنه التطبيق.
     *
     * نعم حين يكون السطرُ من عمليةٍ يدوية يعكسها إنسان (لا افتتاح ولا تسوية)، ليست هي عكساً ولم
     * تُعكس، ومعه `treasury.reverse`. وكلُّ ما سواها — دفعةٌ، شراءٌ، حركةُ محفظة — يُعكس من شاشته.
     */
    private function reversibleBy(Request $request, ?TreasuryOperation $operation): bool
    {
        $operation ??= $this->operation_id === null ? null : $this->operation;

        if ($operation === null || ! $operation->type->isReversibleByHand()) {
            return false;
        }

        $reversed = $operation->relationLoaded('reversedBy')
            ? $operation->reversedBy !== null
            : $operation->isReversed();

        if ($operation->isReversal() || $reversed) {
            return false;
        }

        return (bool) $request->user()?->can(PermissionName::ReverseTreasuryOperations->value);
    }
}
