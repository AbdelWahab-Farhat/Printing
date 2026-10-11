<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «الدفع من المحفظة» — staff at the counter, or the customer from the app.
 *
 * `amount` may be left out: the wallet then pays as much as it holds, up to what the order owes.
 */
class PayOrderFromWalletRequest extends FormRequest
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
            'amount' => ['nullable', 'decimal:0,2', 'min:0.01', 'max:9999999999'],

            // The app's key for this request, kept until the payment succeeds: the same key again
            // is answered with the first payment (200) and pays nothing.
            'client_token' => ['nullable', 'string', 'max:64'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'amount.decimal' => 'المبلغ بخانتين عشريتين على الأكثر',
            'amount.min' => 'المبلغ يجب أن يكون أكبر من صفر',
            'amount.max' => 'المبلغ أكبر من الحد المسموح',
            'client_token.max' => 'رمز الإرسال غير صالح',
        ];
    }
}
