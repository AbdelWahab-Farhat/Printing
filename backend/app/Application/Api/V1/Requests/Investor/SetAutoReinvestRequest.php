<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Investor;

use Illuminate\Foundation\Http\FormRequest;

/** زرُّ «إعادة استثمار الأرباح تلقائياً» — §١٤. */
class SetAutoReinvestRequest extends FormRequest
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
            'enabled' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'enabled.required' => 'حالة الزرّ مطلوبة',
            'enabled.boolean' => 'حالة الزرّ يجب أن تكون صحيحة أو خاطئة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['enabled' => 'إعادة استثمار الأرباح تلقائياً'];
    }
}
