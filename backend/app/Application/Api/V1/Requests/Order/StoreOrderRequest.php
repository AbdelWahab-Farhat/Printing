<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Order\Enums\DesignSource;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreOrderRequest extends FormRequest
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
            'customer_id' => ['required', 'integer', Rule::exists('customers', 'id')->withoutTrashed()],

            // Checked against the customer in the domain, not here: "belongs to somebody else"
            // is a business refusal with a sentence worth reading, not a missing row.
            'customer_shop_id' => ['nullable', 'integer', Rule::exists('customer_shops', 'id')->withoutTrashed()],

            'city_id' => ['required', 'integer', Rule::exists('cities', 'id')->withoutTrashed()],
            'region_id' => ['nullable', 'integer', Rule::exists('regions', 'id')->withoutTrashed()],

            'design_source' => ['sometimes', Rule::enum(DesignSource::class)],

            'recipient_name' => ['nullable', 'string', 'max:255'],
            'recipient_phone' => ['nullable', 'string', 'max:20'],
            'address_details' => ['nullable', 'string', 'max:1000'],
            'notes' => ['nullable', 'string', 'max:2000'],

            // Only counted when design_source is in_house; sending it otherwise is harmless and
            // is kept rather than blanked, so flipping the source back does not lose the number.
            'design_fee' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],

            // The artwork, chosen from the customer's library as it is everywhere else — never
            // uploaded here. Whether each design is *this customer's* is a domain refusal with a
            // sentence worth reading, and it takes the whole order down with it rather than
            // leaving one behind that is missing the file it was taken for.
            //
            // Capped at the library's own size: a longer list could only be repetition, and
            // `AddOrderDesign` is one insert per entry.
            'design_ids' => ['sometimes', 'array', 'max:50'],
            'design_ids.*' => ['integer', Rule::exists('customer_designs', 'id')->withoutTrashed()],

            // Guarded by `orders.discount` inside the domain, so a console command or a future
            // import cannot get past it either.
            'discount' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],

            'tracking_number' => ['nullable', 'string', 'max:100'],

            'items' => ['required', 'array', 'min:1', 'max:100'],
            'items.*.product_id' => ['required', 'integer', Rule::exists('products', 'id')->withoutTrashed()],
            'items.*.product_variant_id' => ['required', 'integer', Rule::exists('product_variants', 'id')->withoutTrashed()],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001', 'max:999999999'],

            // Honoured only for a product the catalogue prices on request; ignored otherwise, so
            // a posted number can never undercut a listed rate.
            'items.*.unit_price' => ['nullable', 'numeric', 'min:0', 'max:9999999.999'],
            'items.*.notes' => ['nullable', 'string', 'max:500'],
            'items.*.sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],

            // Only when the sales unit and the warehouse unit genuinely differ — see the
            // docblock on OrderItem::warehouse_quantity. Left null, DeductOrderStock deducts
            // `quantity` unchanged.
            'items.*.warehouse_quantity' => ['nullable', 'numeric', 'gt:0', 'max:999999999'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'customer_id.required' => 'العميل مطلوب',
            'customer_id.exists' => 'العميل غير موجود',
            'city_id.required' => 'مدينة التوصيل مطلوبة',
            'city_id.exists' => 'المدينة غير موجودة',
            'region_id.exists' => 'المنطقة غير موجودة',
            'items.required' => 'الطلبية يجب أن تحتوي على منتج واحد على الأقل',
            'items.min' => 'الطلبية يجب أن تحتوي على منتج واحد على الأقل',
            'items.*.product_id.required' => 'المنتج مطلوب',
            'items.*.product_variant_id.required' => 'المقاس مطلوب',
            'items.*.quantity.required' => 'الكمية مطلوبة',
            'items.*.quantity.min' => 'الكمية يجب أن تكون أكبر من صفر',
            'discount.min' => 'الخصم لا يمكن أن يكون سالباً',
            'design_fee.min' => 'سعر التصميم لا يمكن أن يكون سالباً',
            'design_ids.*.exists' => 'التصميم غير موجود',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'customer_id' => 'العميل',
            'customer_shop_id' => 'محل العميل',
            'city_id' => 'المدينة',
            'region_id' => 'المنطقة',
            'design_source' => 'مصدر التصميم',
            'design_ids' => 'التصاميم',
            'recipient_name' => 'اسم المستلم',
            'recipient_phone' => 'هاتف المستلم',
            'address_details' => 'تفاصيل العنوان',
            'design_fee' => 'سعر التصميم',
            'discount' => 'الخصم',
            'items' => 'بنود الطلبية',
            'items.*.warehouse_quantity' => 'الكمية المخصومة من المخزن',
        ];
    }
}
