<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «these lines are bought with pool money» — and the price the press will pay for each.
 *
 * **No pool id anywhere.** The material decides which pool pays, so a payload that could name one
 * could route an investor's money into a heading he never agreed to. The only decision this carries
 * is the yes/no, one line at a time.
 *
 * `printing_sale_price` is optional per line and is سعر السادة for **this lorry**. Omitted means
 * «nobody said»: those goods ride the sale itself and their pool is paid from the delivered order's
 * profit. The floor is the column's own resolution — the price is stored to three places, so
 * anything under half a thousandth would pass `gt:0` and arrive at the `CHECK` as a flat zero.
 */
class BuyWithPoolMoneyRequest extends FormRequest
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
            'lines' => ['required', 'array', 'min:1', 'max:50'],
            'lines.*.stock_item_id' => ['required', 'integer', 'distinct'],
            'lines.*.printing_sale_price' => ['nullable', 'numeric', 'min:0.001', 'max:999999999'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'lines.required' => 'اختر بنداً واحداً على الأقل يُشترى من مال الصندوق',
            'lines.min' => 'اختر بنداً واحداً على الأقل يُشترى من مال الصندوق',
            'lines.*.stock_item_id.required' => 'كل سطر يحتاج مادة',
            'lines.*.stock_item_id.distinct' => 'المادة مكرَّرة — سطر واحد لكل مادة',
            'lines.*.printing_sale_price.min' => 'أقل سعر سادة يمكن تسجيله هو 0.001 د.ل',
        ];
    }
}
