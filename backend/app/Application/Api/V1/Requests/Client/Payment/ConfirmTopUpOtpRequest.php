<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Payment;

use Illuminate\Foundation\Http\FormRequest;

/** The code the provider texted. */
class ConfirmTopUpOtpRequest extends FormRequest
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
            'otp' => ['required', 'string', 'regex:/^[0-9]{3,10}$/'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'otp.required' => 'رمز التحقق مطلوب',
            'otp.regex' => 'رمز التحقق أرقام فقط',
        ];
    }
}
