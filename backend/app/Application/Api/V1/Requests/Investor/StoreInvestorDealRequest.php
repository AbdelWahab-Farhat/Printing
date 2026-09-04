<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * A deal, its shelves and its participants, in one payload.
 *
 * `investor_profit_share_percent` is optional: omitted, the company default seeds it. That is
 * the whole of «لدي إمكانية التحكم بالنسبة من إعداد معين ولا حاجة لإدخالها كل مرة» — one number
 * edited once, copied onto each new deal, and never read again for that deal.
 */
class StoreInvestorDealRequest extends FormRequest
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
            'name' => ['required', 'string', 'min:2', 'max:120'],
            'opened_on' => ['required', 'date'],

            // A label for the screen. Attribution runs through the shelves below, because a
            // product does not own stock in this system.
            'product_id' => ['nullable', 'integer', Rule::exists('products', 'id')->withoutTrashed()],

            'investor_profit_share_percent' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],

            'items' => ['required', 'array', 'min:1', 'max:50'],
            'items.*.stock_item_id' => ['required', 'integer', Rule::exists('stock_items', 'id')->withoutTrashed()],
            'items.*.quantity_expected' => ['nullable', 'numeric', 'gt:0', 'max:999999999'],
            'items.*.expected_unit_cost' => ['nullable', 'numeric', 'gte:0', 'max:999999999'],
            'items.*.expected_unit_price' => ['nullable', 'numeric', 'gte:0', 'max:999999999'],
            'items.*.notes' => ['nullable', 'string', 'max:255'],

            'investors' => ['required', 'array', 'min:1', 'max:20'],
            'investors.*.investor_id' => ['required', 'integer', Rule::exists('investors', 'id')->withoutTrashed()],
            // The sum is checked in the domain, under the deal's lock — a rule here could only
            // check one request at a time, and two arriving together would each pass.
            'investors.*.share_percent' => ['required', 'numeric', 'gt:0', 'max:100'],
            'investors.*.committed_amount' => ['nullable', 'numeric', 'gte:0', 'max:9999999999.99'],
            'investors.*.notes' => ['nullable', 'string', 'max:255'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'اسم الصفقة مطلوب',
            'opened_on.required' => 'تاريخ الصفقة مطلوب',
            'items.required' => 'الصفقة تحتاج مادة واحدة على الأقل',
            'investors.required' => 'الصفقة تحتاج مستثمراً واحداً على الأقل',
            'investors.*.share_percent.required' => 'نسبة المستثمر مطلوبة',
        ];
    }
}
