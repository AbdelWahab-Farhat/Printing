<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Payment;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Topping up the wallet online. The shape is checked here; which fields a method needs, and the
 * limits, are the domain's — answered under the same field names.
 */
class StartOnlineTopUpRequest extends FormRequest
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
            /** EzonePay's method id — 111 Libyana, 101 bank cards… (`GET client/payments/methods`). */
            'method' => ['required', 'integer', Rule::enum(OnlineMethod::class)],
            /** What the wallet should receive; the fee is on top when the customer pays it. */
            'amount' => ['required', 'decimal:0,2', 'min:1', 'max:100000'],
            /** «اشحن وادفع»: an order of the customer's, paid from the wallet once it is topped up. */
            'order_id' => ['nullable', 'integer'],
            /** How much of the wallet that order is paid — the عربون chosen in the basket. Absent: as much as the wallet can. */
            'order_amount' => [
                'nullable',
                Rule::prohibitedIf(fn (): bool => $this->input('order_id') === null),
                'decimal:0,2',
                'min:0.01',
                'max:999999999',
            ],
            'card_number' => ['nullable', 'string', 'regex:/^[0-9 ]{4,32}$/'],
            'service_mobile_number' => ['nullable', 'string', 'regex:/^[0-9+ ]{9,16}$/'],
            'birth_year' => ['nullable', 'digits:4'],
            'qr_content' => ['nullable', 'string', 'max:2000'],
            /** The app's key for this request — the same key again returns the first attempt. */
            'client_token' => ['nullable', 'string', 'max:64'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'method.required' => 'طريقة الدفع مطلوبة',
            'method.enum' => 'طريقة الدفع غير معروفة',
            'amount.required' => 'المبلغ مطلوب',
            'amount.decimal' => 'المبلغ بخانتين عشريتين على الأكثر',
            'amount.min' => 'أقل مبلغ للشحن دينار واحد',
            'amount.max' => 'المبلغ أكبر من الحد المسموح',
            'card_number.regex' => 'رقم البطاقة غير صحيح',
            'service_mobile_number.regex' => 'رقم الهاتف غير صحيح',
            'birth_year.digits' => 'سنة الميلاد أربعة أرقام',
            'qr_content.max' => 'رمز QR غير صالح',
            'order_amount.prohibited' => 'مبلغ الطلبية يحتاج طلبية',
            'order_amount.decimal' => 'مبلغ الطلبية بخانتين عشريتين على الأكثر',
        ];
    }
}
