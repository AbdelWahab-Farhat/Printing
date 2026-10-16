<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\OnlinePayment;

use Illuminate\Foundation\Http\FormRequest;

/** A method switched on or off, and its limits — an empty limit is no cap. */
class UpdateOnlinePaymentMethodRequest extends FormRequest
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
            'is_active' => ['sometimes', 'boolean'],
            'daily_limit' => ['sometimes', 'nullable', 'decimal:0,2', 'min:1', 'max:9999999'],
            'monthly_limit' => ['sometimes', 'nullable', 'decimal:0,2', 'min:1', 'max:9999999'],
            'yearly_limit' => ['sometimes', 'nullable', 'decimal:0,2', 'min:1', 'max:99999999'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'daily_limit.min' => 'الحد دينارٌ على الأقل — أو اتركه فارغاً بلا حد',
            'monthly_limit.min' => 'الحد دينارٌ على الأقل — أو اتركه فارغاً بلا حد',
            'yearly_limit.min' => 'الحد دينارٌ على الأقل — أو اتركه فارغاً بلا حد',
        ];
    }
}
