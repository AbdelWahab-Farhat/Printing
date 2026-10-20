<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Order;

use App\Domain\Order\Enums\CheckoutPayment;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * The عربون of an accepted order, chosen from the app — the same fields as the basket's `deposit`
 * (see `RequestOrderRequest`), at the top level here. Its floor and ceiling need the order, so they
 * are the domain's — see `CheckoutDeposit`.
 */
class ChooseOrderDepositRequest extends FormRequest
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
            'payment' => ['required', Rule::enum(CheckoutPayment::class)],
            // **بالدينار الكامل** (صاحب العمل، 2026-10-19): لا كسور في العربون.
            'amount' => ['required', 'integer', 'min:1', 'max:999999999'],
            // The app's key for the wallet payment — the same key again pays nothing.
            'client_token' => ['nullable', 'string', 'max:64'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'payment.required' => 'اختر طريقة دفع العربون',
            'payment.enum' => 'طريقة دفع العربون غير معروفة',
            'amount.required' => 'قيمة العربون مطلوبة',
            'amount.integer' => 'العربون بالدينار الكامل، بلا كسور',
            'amount.min' => 'قيمة العربون يجب أن تكون أكبر من صفر',
        ];
    }
}
