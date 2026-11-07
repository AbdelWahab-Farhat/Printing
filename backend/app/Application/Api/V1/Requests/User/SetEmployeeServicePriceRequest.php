<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\User;

use Illuminate\Foundation\Http\FormRequest;

/**
 * السعر المقترح لموظف في خدمة. الصلاحية على المسار، وقيد «مَن يقدّم الخدمة» في `AccessService`.
 */
class SetEmployeeServicePriceRequest extends FormRequest
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
            'suggested_price' => ['present', 'nullable', 'numeric', 'min:0', 'max:9999999999.99'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'suggested_price.present' => 'السعر مطلوب — أرسل قيمة أو فارغاً',
            'suggested_price.numeric' => 'السعر يجب أن يكون رقماً',
            'suggested_price.min' => 'السعر لا يمكن أن يكون سالباً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['suggested_price' => 'السعر المقترح'];
    }

    /** نصٌّ عشري لا float، كأيّ مبلغ. */
    public function suggestedPrice(): ?string
    {
        $price = $this->validated('suggested_price');

        return $price === null ? null : (string) $price;
    }
}
