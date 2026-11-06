<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\EmployeeWallet\Models\EmployeeWalletEntry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * سطرٌ من محفظة الموظف، لصاحبها. **ما يعرفه هو وحده**: النوع والمبلغ والتاريخ والملاحظة، لا الحساب
 * الذي خرج منه المال ولا اسم الزميل الذي سجّله. EMPLOYEE-WALLET-DESIGN §١٠.
 *
 * @mixin EmployeeWalletEntry
 */
class MyWalletEntryResource extends JsonResource
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
            /** `in` يزيد المحفظة، و`out` ينقصها. */
            'direction' => $this->resource->isCredit() ? 'in' : 'out',
            'amount' => (string) $this->amount,
            'method_label' => $this->method?->label(),
            'category_name' => $this->category?->name,
            'notes' => $this->notes,
            'is_reversed' => $this->resource->isReversed(),
            'occurred_at' => $this->occurred_at?->toIso8601String(),
        ];
    }
}
