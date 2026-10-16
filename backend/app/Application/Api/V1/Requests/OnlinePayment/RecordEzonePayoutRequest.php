<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\OnlinePayment;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** «تحويل Ezone إلى المصرف» — what arrived, what EzonePay kept, into which account. */
class RecordEzonePayoutRequest extends FormRequest
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
            /** What reached the bank. */
            'amount' => ['required', 'decimal:0,2', 'min:0.01', 'max:9999999999'],
            /** What EzonePay kept at payout, beyond the fees already recorded per top-up. */
            'kept' => ['nullable', 'decimal:0,2', 'min:0', 'max:9999999999'],
            /** Where it arrived. Left out: the bank's default — «تلقائي», as on a payment. */
            'to_account_id' => ['nullable', 'integer', Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at')],
            'occurred_at' => ['nullable', 'date', 'before_or_equal:now'],
            'reference' => ['nullable', 'string', 'max:100'],
            'client_token' => ['nullable', 'string', 'max:64'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'amount.required' => 'المبلغ الواصل مطلوب',
            'amount.min' => 'المبلغ يجب أن يكون أكبر من صفر',
            'to_account_id.exists' => 'الحساب غير موجود',
            'occurred_at.before_or_equal' => 'التاريخ لا يمكن أن يكون في المستقبل',
        ];
    }
}
