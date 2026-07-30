<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Product;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Enums\ProductCategory;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreProductRequest extends FormRequest
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
            'slug' => ['required', 'string', 'max:80', 'regex:/^[a-z0-9-]+$/', 'unique:products,slug'],
            'name' => ['required', 'string', 'min:2', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'features' => ['nullable', 'array', 'max:12'],
            'features.*' => ['required', 'string', 'max:255'],

            'category' => ['required', Rule::enum(ProductCategory::class)],
            'pricing_unit' => ['required', Rule::enum(PricingUnit::class)],
            'pricing_mode' => ['required', Rule::enum(PricingMode::class)],

            'min_order_quantity' => ['required', 'numeric', 'min:0.001'],
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],

            // A size and its price list. Sizes are optional here so a quote-only product can be
            // created before its sizes are known.
            'variants' => ['sometimes', 'array'],
            'variants.*.label' => ['required', 'string', 'max:60'],
            'variants.*.width_cm' => ['nullable', 'integer', 'min:1', 'max:1000'],
            'variants.*.height_cm' => ['nullable', 'integer', 'min:1', 'max:1000'],
            'variants.*.is_active' => ['sometimes', 'boolean'],
            'variants.*.sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],
            'variants.*.price_tiers' => ['sometimes', 'array'],
            'variants.*.price_tiers.*.min_quantity' => ['required', 'numeric', 'min:0.001'],
            'variants.*.price_tiers.*.unit_price' => ['required', 'numeric', 'min:0'],
        ];
    }

    /**
     * Two rules the field-level rules cannot see, because each depends on more than one field.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $this->rejectFractionalMinimumForPieces($validator);
            $this->rejectPricesOnQuoteOnlyProducts($validator);
        });
    }

    private function rejectFractionalMinimumForPieces(Validator $validator): void
    {
        if ($this->input('pricing_unit') !== PricingUnit::Piece->value) {
            return;
        }

        $minimum = $this->input('min_order_quantity');

        if (is_numeric($minimum) && floor((float) $minimum) !== (float) $minimum) {
            $validator->errors()->add('min_order_quantity', 'الحد الأدنى للمنتجات المُسعَّرة بالقطعة يجب أن يكون رقماً صحيحاً');
        }
    }

    /**
     * A quote-only product must not carry prices — publishing a price for something the
     * catalogue says is priced on request is exactly the contradiction this guards against.
     */
    private function rejectPricesOnQuoteOnlyProducts(Validator $validator): void
    {
        if ($this->input('pricing_mode') !== PricingMode::QuoteOnRequest->value) {
            return;
        }

        foreach ((array) $this->input('variants', []) as $index => $variant) {
            if (! empty($variant['price_tiers'])) {
                $validator->errors()->add(
                    "variants.{$index}.price_tiers",
                    'لا يمكن إضافة أسعار لمنتج سعره حسب الطلب',
                );
            }
        }
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'slug.required' => 'المعرف مطلوب',
            'slug.regex' => 'المعرف يجب أن يحتوي على أحرف إنجليزية صغيرة وأرقام وشرطات فقط',
            'slug.unique' => 'المعرف مستخدم مسبقاً',
            'name.required' => 'اسم المنتج مطلوب',
            'category.required' => 'التصنيف مطلوب',
            'pricing_unit.required' => 'وحدة التسعير مطلوبة',
            'pricing_mode.required' => 'طريقة التسعير مطلوبة',
            'min_order_quantity.required' => 'الحد الأدنى للطلب مطلوب',
            'min_order_quantity.min' => 'الحد الأدنى للطلب يجب أن يكون أكبر من صفر',
            'variants.*.label.required' => 'اسم المقاس مطلوب',
            'variants.*.price_tiers.*.min_quantity.required' => 'الكمية الأدنى للشريحة مطلوبة',
            'variants.*.price_tiers.*.unit_price.required' => 'سعر الوحدة مطلوب',
            'variants.*.price_tiers.*.unit_price.min' => 'سعر الوحدة لا يمكن أن يكون سالباً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'slug' => 'المعرف',
            'name' => 'اسم المنتج',
            'description' => 'الوصف',
            'features' => 'المميزات',
            'category' => 'التصنيف',
            'pricing_unit' => 'وحدة التسعير',
            'pricing_mode' => 'طريقة التسعير',
            'min_order_quantity' => 'الحد الأدنى للطلب',
            'variants' => 'المقاسات',
        ];
    }
}
