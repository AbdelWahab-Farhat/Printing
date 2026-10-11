<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Wallet;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** «تعديل الرصيد» — a direction, an amount, and the reason, which is required. */
class AdjustWalletRequest extends FormRequest
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
            /** `credit` adds to the wallet, `debit` takes from it. */
            'direction' => ['required', Rule::in(['credit', 'debit'])],
            'amount' => ['required', 'decimal:0,2', 'min:0.01', 'max:9999999999'],
            'reason' => ['required', 'string', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'direction.required' => 'اختر زيادة أو نقصاً',
            'direction.in' => 'اختر زيادة أو نقصاً',
            'amount.required' => 'المبلغ مطلوب',
            'amount.decimal' => 'المبلغ بخانتين عشريتين على الأكثر',
            'amount.min' => 'المبلغ يجب أن يكون أكبر من صفر',
            'amount.max' => 'المبلغ أكبر من الحد المسموح',
            'reason.required' => 'سبب التعديل مطلوب',
            'reason.max' => 'السبب طويل جداً',
        ];
    }
}
