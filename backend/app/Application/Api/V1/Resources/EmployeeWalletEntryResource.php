<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use App\Domain\EmployeeWallet\Support\OwnWalletRule;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * سطرٌ من محفظة موظف، لمن يدير المحافظ. EMPLOYEE-WALLET-DESIGN §٧.
 *
 * `direction` و`can_reverse` يقرّرهما الخادم من السطر، فلا يحفظ التطبيق نسخةً من أيّ الأنواع تزيد،
 * ولا من قاعدة «لا تحرّك محفظتك بنفسك».
 *
 * @mixin EmployeeWalletEntry
 */
class EmployeeWalletEntryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'user' => $this->whenLoaded('employee', fn (): ?array => $this->employee === null ? null : [
                'id' => $this->employee->id,
                'code' => $this->employee->employee_code,
                'name' => $this->employee->name,
                'phone' => $this->employee->phone,
            ]),

            'type' => $this->type->value,
            'type_label' => $this->resource->displayLabel(),

            /** `in` يزيد المحفظة، و`out` ينقصها. */
            'direction' => $this->resource->isCredit() ? 'in' : 'out',

            // موجبٌ دائماً، نصّاً كأيّ حقل مال.
            'amount' => (string) $this->amount,

            // الإيداع والسحب وحدهما.
            'method' => $this->method?->value,
            'method_label' => $this->method?->label(),
            'treasury_account' => $this->whenLoaded('treasuryAccount', fn (): ?array => $this->treasuryAccount === null ? null : [
                'id' => $this->treasuryAccount->id,
                'name' => $this->treasuryAccount->name,
            ]),

            // المستحق وحده.
            'category' => $this->whenLoaded('category', fn (): ?array => $this->category === null ? null : [
                'id' => $this->category->id,
                'name' => $this->category->name,
            ]),

            'reference' => $this->reference,
            'notes' => $this->notes,

            'has_receipt' => $this->resource->hasReceipt(),
            'receipt_is_image' => $this->resource->receiptIsImage(),
            'receipt_url' => $this->resource->receiptUrl(),
            'receipt_filename' => $this->receipt_original_filename,

            'occurred_at' => $this->occurred_at?->toIso8601String(),

            'is_reversed' => $this->resource->isReversed(),
            'can_reverse' => $this->canReverse($request),
            'reverses_entry_id' => $this->reverses_entry_id,
            'reversal' => $this->whenLoaded('reversal', fn (): ?array => $this->reversal === null ? null : [
                'id' => $this->reversal->id,
                'reason' => $this->reversal->notes,
                'created_at' => $this->reversal->created_at?->toIso8601String(),
            ]),

            'recorded_by' => $this->recorded_by,
            'recorder' => $this->whenLoaded('recorder', fn (): ?array => $this->recorder === null ? null : [
                'id' => $this->recorder->id,
                'name' => $this->recorder->name,
            ]),

            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /** ما يضع «عكس» على السطر: سطرٌ لم يُعكس، والصلاحية، وليس محفظة القارئ نفسه. */
    private function canReverse(Request $request): bool
    {
        $viewer = $request->user();

        return $viewer instanceof User
            && $this->type->isReversibleByHand()
            && ! $this->resource->isReversed()
            && $viewer->can(PermissionName::ReverseEmployeeWalletEntries->value)
            && OwnWalletRule::allows($viewer, (int) $this->user_id);
    }
}
