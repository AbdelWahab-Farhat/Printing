<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\PurchaseOrder;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Taking back a refund recorded in error. One required field, the reason.
 */
class ReverseCostRefundRequest extends FormRequest
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
            'reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reason.required' => 'سبب التراجع مطلوب',
            'reason.min' => 'سبب التراجع قصير جداً',
            'reason.max' => 'سبب التراجع طويل جداً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'reason' => 'سبب التراجع',
        ];
    }
}
