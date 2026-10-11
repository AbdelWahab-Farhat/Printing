<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Wallet;

use App\Domain\Wallet\Enums\TopUpMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «شحن المحفظة» at the counter. The order payment's rules, written out in full — Scramble reads
 * `rules()` without running it (RULES.md §7).
 */
class TopUpWalletRequest extends FormRequest
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
            'amount' => ['required', 'decimal:0,2', 'min:0.01', 'max:9999999999'],

            'method' => ['required', Rule::enum(TopUpMethod::class)],

            'reference' => ['nullable', 'string', 'max:100'],

            // When the money arrived. Back-dating is ordinary; the future is not money yet.
            'occurred_at' => ['nullable', 'date', 'before_or_equal:now'],

            'notes' => ['nullable', 'string', 'max:1000'],

            // Required for a transfer — `TopUpMethod::requiresReceipt()` and a CHECK say it too.
            'receipt' => [
                'required_if:method,'.TopUpMethod::BankTransfer->value,
                'nullable',
                'file',
                'mimetypes:'.implode(',', (array) config('media.payment_receipts.mimetypes')),
                'mimes:'.implode(',', (array) config('media.payment_receipts.mimes')),
                'max:'.config('media.payment_receipts.max_kilobytes'),
            ],

            // Where the money landed. Optional: the treasury decides, as for an order payment.
            'treasury_account_id' => [
                'nullable',
                'integer',
                Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at'),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'amount.required' => 'المبلغ مطلوب',
            'amount.decimal' => 'المبلغ بخانتين عشريتين على الأكثر',
            'amount.min' => 'المبلغ يجب أن يكون أكبر من صفر',
            'amount.max' => 'المبلغ أكبر من الحد المسموح',
            'method.required' => 'طريقة الشحن مطلوبة',
            'method.enum' => 'طريقة الشحن غير معروفة',
            'reference.max' => 'رقم المرجع طويل جداً',
            'occurred_at.date' => 'التاريخ غير صحيح',
            'occurred_at.before_or_equal' => 'التاريخ لا يمكن أن يكون في المستقبل',
            'notes.max' => 'الملاحظات طويلة جداً',
            'receipt.required_if' => 'الشحن بحوالة يتطلب إرفاق الواصل',
            'receipt.file' => 'الواصل يجب أن يكون ملفاً',
            'receipt.mimetypes' => 'الواصل يجب أن يكون ملف PDF أو صورة',
            'receipt.mimes' => 'الواصل يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP',
            'receipt.max' => 'حجم الواصل يجب ألا يتجاوز '.
                (int) (config('media.payment_receipts.max_kilobytes') / 1024).' ميجابايت',
        ];
    }
}
