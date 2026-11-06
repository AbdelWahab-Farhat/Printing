<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\EmployeeWallet;

use Illuminate\Foundation\Http\FormRequest;

/** إلغاءُ سطرٍ من المحفظة — السبب إجباري، كما في كل عكس. */
class ReverseEmployeeWalletEntryRequest extends FormRequest
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
            'reason' => ['required', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reason.required' => 'سبب العكس مطلوب',
            'reason.max' => 'السبب طويل جداً',
        ];
    }
}
