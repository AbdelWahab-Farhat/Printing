<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Customer\Support\PhoneNumber;
use App\Domain\Delivery\Models\Region;
use App\Domain\Order\Support\Money;
use Closure;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * An instant sale as the counter typed it (INSTANT-ORDERS-PLAN.md §3).
 *
 * The shape is checked here; whether the branch, the products and the stock allow the sale is
 * the domain's to say, with sentences an employee can act on — see CreateInstantOrder.
 */
class StoreInstantOrderRequest extends FormRequest
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
            'client_token' => ['nullable', 'string', 'max:64'],
            'branch_id' => ['required', 'integer', Rule::exists('cities', 'id')->withoutTrashed()],

            // Name and phone are required; the address is optional (owner's decision,
            // 2026-11-27 — the order goes to the branch, the address only fills the customer's
            // record). A region never comes without its city. The customer's address is theirs —
            // never the branch's.
            'customer' => ['required', 'array'],
            'customer.phone' => ['required', 'string', 'max:30', $this->validPhone()],
            'customer.name' => ['required', 'string', 'min:2', 'max:255'],
            'customer.city_id' => ['nullable', 'integer', 'required_with:customer.region_id', Rule::exists('cities', 'id')->withoutTrashed()],
            'customer.region_id' => ['nullable', 'integer', Rule::exists('regions', 'id')->withoutTrashed()],

            ...self::lineRules(),

            'discount' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99', $this->wholeDinars()],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    /**
     * The lines, shared with the edit. No price, no weight and no cost: the price comes from the
     * product and the stock unit is the sale unit for every product an instant order may sell.
     *
     * @return array<string, mixed>
     */
    public static function lineRules(): array
    {
        return [
            'items' => ['required', 'array', 'min:1', 'max:100'],
            'items.*.product_id' => ['required', 'integer', Rule::exists('products', 'id')->withoutTrashed()],
            'items.*.product_variant_id' => ['required', 'integer', Rule::exists('product_variants', 'id')->withoutTrashed()],
            'items.*.quantity' => ['required', 'numeric', 'gt:0', 'max:999999999'],
            'items.*.notes' => ['nullable', 'string', 'max:500'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $cityId = $this->input('customer.city_id');
            $regionId = $this->input('customer.region_id');

            // Both halves optional; only a pair that disagrees is refused.
            if ($cityId === null || $cityId === '' || $regionId === null || $regionId === ''
                || $validator->errors()->has('customer.city_id')) {
                return;
            }

            if (! Region::query()->whereKey($regionId)->where('city_id', $cityId)->exists()) {
                $validator->errors()->add('customer.region_id', 'المنطقة المختارة ليست ضمن المدينة المحددة');
            }
        });
    }

    private function validPhone(): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail): void {
            if (! is_string($value) || ! PhoneNumber::isValid(PhoneNumber::normalise($value))) {
                $fail('رقم الهاتف غير صحيح');
            }
        };
    }

    private function wholeDinars(): Closure
    {
        return function (string $attribute, mixed $value, Closure $fail): void {
            if (is_numeric($value) && ! Money::isWhole(Money::normalize($value))) {
                $fail('الخصم بالدينار الكامل، بلا كسور');
            }
        };
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'branch_id.required' => 'مكان الاستلام مطلوب',
            'branch_id.exists' => 'مكان الاستلام غير موجود',
            'customer.phone.required' => 'رقم الهاتف مطلوب',
            'customer.name.required' => 'اسم العميل مطلوب',
            'customer.name.min' => 'اسم العميل قصير جداً',
            'customer.city_id.required_with' => 'اختر المدينة قبل المنطقة',
            'customer.city_id.exists' => 'المدينة غير موجودة',
            'customer.region_id.exists' => 'المنطقة غير موجودة',
            'items.required' => 'أضف منتجاً واحداً على الأقل',
            'items.min' => 'أضف منتجاً واحداً على الأقل',
            'items.*.quantity.required' => 'الكمية مطلوبة',
            'items.*.quantity.gt' => 'الكمية يجب أن تكون أكبر من صفر',
            'discount.min' => 'الخصم لا يمكن أن يكون سالباً',
        ];
    }
}
