<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Customer;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Activating / deactivating a customer is its own request so a list screen's toggle does not
 * have to send the whole record back.
 */
class SetCustomerActivationRequest extends FormRequest
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
            'is_active' => ['required', 'boolean'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'is_active.required' => 'الحالة مطلوبة',
            'is_active.boolean' => 'الحالة يجب أن تكون صحيحة أو خاطئة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['is_active' => 'الحالة'];
    }
}
