<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Who financed this purchase order, and with how much.
 *
 * **No shelves and no percentages.** The shelves are the order's own lines and the percentages
 * are the amounts — a form that asked for either would be asking a person to retype something
 * the system already holds and can be contradicted on.
 *
 * `investor_profit_share_percent` stays optional here as it is on the deal form: omitted, the
 * company default seeds it.
 */
class FundPurchaseOrderRequest extends FormRequest
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
        return [
            'investor_profit_share_percent' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],

            // Which of the order's lines this deal funds. Omitted, it takes every line nobody
            // has claimed — the whole order the first time, the remainder afterwards. That the
            // lines belong to this order, and are still free, is checked in the domain.
            'stock_item_ids' => ['sometimes', 'array', 'min:1', 'max:50'],
            'stock_item_ids.*' => ['required', 'integer', 'distinct'],

            'investors' => ['required', 'array', 'min:1', 'max:20'],
            'investors.*.investor_id' => [
                'required',
                'integer',
                'distinct',
                Rule::exists('investors', 'id')->withoutTrashed(),
            ],
            // What he actually put in. The ceiling is his wallet, checked in the domain against
            // the locked row — a rule here could only read a balance two requests could both pass.
            // The floor is the domain's — repeated here only so the refusal names the field
            // rather than arriving as a sentence about the whole payload.
            'investors.*.amount' => ['required', 'numeric', 'min:1000', 'max:9999999999.99'],
            'investors.*.notes' => ['nullable', 'string', 'max:255'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'stock_item_ids.min' => 'اختر بنداً واحداً على الأقل تموّله الصفقة',
            'investors.required' => 'اختر مستثمراً واحداً على الأقل',
            'investors.*.investor_id.distinct' => 'المستثمر مكرَّر — سطر واحد لكل مستثمر',
            'investors.*.amount.required' => 'اكتب ما وضعه المستثمر',
            'investors.*.amount.min' => 'أقل مبلغ يدخل به مستثمر صفقةً هو 1000 د.ل',
        ];
    }
}
