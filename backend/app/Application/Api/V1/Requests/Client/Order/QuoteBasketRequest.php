<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Order;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * سلةٌ تُسعَّر قبل إرسالها.
 *
 * **سطورها بقواعد {@see RequestOrderRequest} نفسها**، مكتوبةً كاملةً لا موروثة — Scramble لا يقرأ
 * قواعد مدمجةً من أب (RULES §7). والمدينة اختيارية: السلة تُسعَّر قبل أن تُختار الوجهة، والتوصيل
 * يُضاف حين تُختار.
 */
class QuoteBasketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'city_id' => ['nullable', 'integer', Rule::exists('cities', 'id')->withoutTrashed()],

            'items' => ['required', 'array', 'min:1', 'max:100'],
            // المعروض وحده، كما يقبله طلب الطلبية: منتجٌ أُوقف لا يُسعَّر لسلةٍ لن تُقبل.
            'items.*.product_id' => [
                'required',
                'integer',
                Rule::exists('products', 'id')->where('is_active', true)->withoutTrashed(),
            ],
            'items.*.product_variant_id' => ['required', 'integer', Rule::exists('product_variants', 'id')->withoutTrashed()],
            'items.*.quantity' => ['required', 'numeric', 'decimal:0,3', 'min:0.001', 'max:999999999'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'city_id.exists' => 'المدينة غير موجودة',
            'items.required' => 'السلة فارغة',
            'items.min' => 'السلة فارغة',
            'items.*.product_id.required' => 'المنتج مطلوب',
            'items.*.product_id.exists' => 'المنتج غير متاح للطلب',
            'items.*.product_variant_id.required' => 'المقاس مطلوب',
            'items.*.quantity.required' => 'الكمية مطلوبة',
            'items.*.quantity.numeric' => 'الكمية يجب أن تكون رقماً',
            'items.*.quantity.decimal' => 'الكمية يجب أن تكون رقماً بثلاث خانات عشرية على الأكثر',
            'items.*.quantity.min' => 'الكمية يجب أن تكون أكبر من صفر',
        ];
    }
}
