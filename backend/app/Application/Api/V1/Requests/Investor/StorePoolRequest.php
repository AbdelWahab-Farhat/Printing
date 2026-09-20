<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Opening or renaming a صندوق.
 *
 * **No funders and no amounts.** A deal was struck in one act because it *was* one lorry; a pool
 * outlives every lorry it buys, and capital reaches it later through its own endpoint, gated by
 * the grace window. A pool is created empty on purpose.
 *
 * **No `investor_profit_share_percent` on update**, only on create. It is the term the partners
 * were shown, and a pool that could be re-cut mid-life would be re-cutting periods already closed
 * and paid against. Renegotiating is a decision with its own act and its own audit line, not a
 * field slipped into a rename.
 *
 * **At least one shelf.** A pool that owns nothing can take money and never buy anything with it,
 * and the investor would have no way to see that from his screen.
 *
 * The uniqueness of the name is checked here **and** by a partial unique index on the table. Twice
 * on purpose: the index is the guarantee, and this is what turns a violation into an Arabic
 * sentence rather than a 500.
 */
class StorePoolRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        $poolId = $this->route('pool')?->id;

        return [
            'name' => [
                'required', 'string', 'min:2', 'max:120',
                Rule::unique('investor_deals', 'name')
                    ->where(fn ($q) => $q->where('kind', 'pool')->whereNull('deleted_at'))
                    ->ignore($poolId),
            ],
            'stock_item_ids' => ['required', 'array', 'min:1'],
            'stock_item_ids.*' => ['required', 'integer', 'exists:stock_items,id'],
            'investor_profit_share_percent' => [
                $this->isMethod('POST') ? 'nullable' : 'prohibited',
                'numeric', 'min:0', 'max:100',
            ],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'اسم الصندوق مطلوب',
            'name.min' => 'اسم الصندوق قصير جداً',
            'name.unique' => 'يوجد صندوق بهذا الاسم',
            'stock_item_ids.required' => 'اختر المواد التي يشتريها الصندوق',
            'stock_item_ids.min' => 'الصندوق يحتاج مادة واحدة على الأقل',
            'stock_item_ids.*.exists' => 'إحدى المواد غير موجودة',
            'investor_profit_share_percent.prohibited' => 'نسبة أرباح المستثمرين لا تُعدَّل بعد فتح الصندوق',
            'investor_profit_share_percent.max' => 'النسبة لا تتجاوز 100',
        ];
    }
}
