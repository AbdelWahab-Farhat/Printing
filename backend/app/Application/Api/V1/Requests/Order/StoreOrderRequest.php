<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Customer\Support\PrintColors;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Enums\AdditionalCostReason;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use Closure;
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
            'design_fee' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99', $this->wholeDinars('design_fee')],

            // The artwork, chosen from the customer's library as it is everywhere else — never
            // uploaded here. Whether each design is *this customer's* is a domain refusal with a
            // sentence worth reading, and it takes the whole order down with it rather than
            // leaving one behind that is missing the file it was taken for.
            //
            // Capped at the library's own size: a longer list could only be repetition, and
            // `AddOrderDesign` is one insert per entry.
            'design_ids' => ['sometimes', 'array', 'max:50'],
            'design_ids.*' => ['integer', Rule::exists('customer_designs', 'id')->withoutTrashed()],

            // The colours typed for each chosen design in the form (PRINT-COLORS.md §9). Only for
            // a design that is also in `design_ids`; `CreateOrder` decides whether they fill the
            // library or only this order's copy. Every colour carries its swatch or its press
            // code, because a name alone is how the wrong shade was printed.
            'design_colors' => ['sometimes', 'array', 'max:50'],
            'design_colors.*.design_id' => ['required', 'integer', Rule::in($this->designIds())],
            'design_colors.*.print_colors' => ['required', 'array', 'min:1', 'max:'.PrintColors::MAX],
            'design_colors.*.print_colors.*.name' => ['required', 'string', 'max:'.PrintColors::NAME_MAX],
            'design_colors.*.print_colors.*.code' => ['nullable', 'string', 'max:'.PrintColors::CODE_MAX],
            'design_colors.*.print_colors.*.hex' => [
                'nullable', 'required_without:design_colors.*.print_colors.*.code', 'string', 'regex:'.PrintColors::HEX_PATTERN,
            ],

            // Guarded by `orders.discount` inside the domain, so a console command or a future
            // import cannot get past it either.
            'discount' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99', $this->wholeDinars('discount')],

            // The charge going the other way, behind `orders.additional_cost` and guarded in the
            // domain for the same reason the discount is.
            //
            // **The reason is required the moment there is anything to explain.** It is the axis
            // this money will be read along later — «كم حصّلنا مقابل التغليف؟» — and a charge
            // nobody can account for is what the field exists to prevent. A closed set, so the
            // column stays something a report can group by rather than four spellings of one
            // category.
            'additional_cost' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99', $this->wholeDinars('additional_cost')],
            'additional_cost_reason' => [
                Rule::requiredIf(fn () => (float) $this->input('additional_cost', 0) > 0),
                'nullable',
                Rule::enum(AdditionalCostReason::class),
            ],
            // «أخرى» on its own carries no information at all, so it is the one reason that has
            // to bring its own words.
            'additional_cost_note' => [
                Rule::requiredIf(
                    fn () => $this->input('additional_cost_reason') === AdditionalCostReason::Other->value
                        && (float) $this->input('additional_cost', 0) > 0
                ),
                'nullable',
                'string',
                'max:500',
            ],

            // **Who is making it, for an order a vendor executes.** Chosen from the list the
            // purchase-order screens already pick from — never a name typed into a box.
            //
            // Optional *here* and required by the domain: whether an order owes a vendor depends
            // on the road it walks, and the road is read off the lines after they are written —
            // see `CreateOrder` and `OutsourcedOrderNeedsAVendor`. A rule here could only guess at
            // it from product ids, and would be a second copy of `ResolveOrderFlow` besides.
            'vendor_id' => ['nullable', 'integer', Rule::exists('vendors', 'id')->withoutTrashed()],

            'tracking_number' => ['nullable', 'string', 'max:100'],

            // «مستعجلة». `sometimes`, not `nullable`: on an edit the key being absent means
            // «اتركها كما هي», and a null arriving in its place would be a third state nothing
            // downstream has a meaning for. See `OrderData::$isUrgent`.
            'is_urgent' => ['sometimes', 'boolean'],

            'items' => ['required', 'array', 'min:1', 'max:100'],
            'items.*.product_id' => ['required', 'integer', Rule::exists('products', 'id')->withoutTrashed()],
            'items.*.product_variant_id' => ['required', 'integer', Rule::exists('product_variants', 'id')->withoutTrashed()],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001', 'max:999999999'],

            // Honoured only for a product the catalogue prices on request; ignored otherwise, so
            // a posted number can never undercut a listed rate.
            'items.*.unit_price' => ['nullable', 'numeric', 'min:0', 'max:9999999.999'],

            // What the vendor charges for one unit of a وسيط line, typed for this order. Ignored
            // on every other line, like `unit_price` on a listed one. **Refused outright** to
            // anybody without `products.view_cost`: a clerk who may not read the vendor's price
            // may not write it either, and dropping it silently would teach the app it was kept.
            'items.*.unit_cost' => [
                Rule::prohibitedIf(fn (): bool => $this->user()?->can(PermissionName::ViewProductCost->value) !== true),
                'nullable', 'numeric', 'min:0', 'max:9999999.999',
            ],
            'items.*.notes' => ['nullable', 'string', 'max:500'],
            'items.*.sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],

            // **No `warehouse_quantity` here, deliberately.** What comes off the shelf is asked
            // for on the way into «جاهزة» — see {@see \App\Domain\Order\Support\TransitionFields} —
            // by the person holding the parcel, not by a clerk agreeing a piece count on the
            // phone before anything has been printed or weighed. One writer, at the one moment
            // the answer exists.
        ];
    }

    /**
     * An order's own charges are in whole dinars, or a fraction comes back through them.
     *
     * **Not Laravel's `integer`:** the apps send back what they were given, and that refuses
     * `25.00`. **And a fraction already on the order passes unchanged**, because every edit
     * re-sends these three — an order from before the rule would otherwise refuse any edit at all.
     */
    protected function wholeDinars(string $column): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail) use ($column): void {
            // Not numeric is the rule before this one's to say, and bcmath would throw on it.
            if (! is_numeric($value)) {
                return;
            }

            $amount = Money::normalize($value);
            $order = $this->route('order');

            if (Money::isWhole($amount)
                || ($order instanceof Order && bccomp($amount, (string) $order->{$column}, Money::SCALE) === 0)) {
                return;
            }

            $fail(':attribute بالدينار الكامل، بلا كسور');
        };
    }

    /**
     * The design ids sent with the order, for `design_colors.*.design_id`.
     *
     * @return list<int>
     */
    protected function designIds(): array
    {
        $ids = $this->input('design_ids');

        return is_array($ids)
            ? array_values(array_map(intval(...), array_filter($ids, is_numeric(...))))
            : [];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'design_colors.*.design_id.in' => 'ألوانٌ لتصميمٍ لم يُختر في الطلبية',
            'design_colors.*.print_colors.required' => 'حدّد ألوان الطباعة للتصميم',
            'design_colors.*.print_colors.min' => 'حدّد ألوان الطباعة للتصميم',
            'design_colors.*.print_colors.max' => 'لا تزيد ألوان الطباعة على :max',
            'design_colors.*.print_colors.*.name.required' => 'اسم اللون مطلوب',
            'design_colors.*.print_colors.*.hex.required_without' => 'اختر اللون',
            'design_colors.*.print_colors.*.hex.regex' => 'لون العيّنة يجب أن يكون بصيغة #RRGGBB',
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
            'items.*.unit_cost.prohibited' => 'لا تملك صلاحية تحديد تكلفة المورد',
            'items.*.unit_cost.min' => 'تكلفة المورد لا يمكن أن تكون سالبة',
            'discount.min' => 'الخصم لا يمكن أن يكون سالباً',
            'additional_cost.min' => 'التكلفة الإضافية لا يمكن أن تكون سالبة',
            'additional_cost_reason.required' => 'سبب التكلفة الإضافية مطلوب',
            'additional_cost_note.required' => 'اكتب سبب التكلفة الإضافية عند اختيار «أخرى»',
            'design_fee.min' => 'سعر التصميم لا يمكن أن يكون سالباً',
            'design_ids.*.exists' => 'التصميم غير موجود',
            'vendor_id.exists' => 'المورد المحدد غير موجود',
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
            'additional_cost' => 'التكلفة الإضافية',
            'additional_cost_reason' => 'سبب التكلفة الإضافية',
            'additional_cost_note' => 'ملاحظة التكلفة الإضافية',
            'vendor_id' => 'المورد',
            'items' => 'بنود الطلبية',
        ];
    }
}
