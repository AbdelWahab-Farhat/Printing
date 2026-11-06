<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\EmployeeWallet;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/** «مستحق» — كم، وتحت أيّ تصنيف. أيُّ التصنيفات يصلح قرارُ الخزينة، لا هذا الطلب. */
class CreditEmployeeWalletRequest extends FormRequest
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
            'category_id' => [
                'required',
                'integer',
                Rule::exists('treasury_expense_categories', 'id')->whereNull('deleted_at'),
            ],
            'occurred_at' => ['nullable', 'date', 'before_or_equal:now'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'client_token' => ['nullable', 'string', 'max:64'],
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
            'category_id.required' => 'التصنيف مطلوب',
            'category_id.exists' => 'التصنيف غير موجود',
            'occurred_at.date' => 'التاريخ غير صحيح',
            'occurred_at.before_or_equal' => 'التاريخ لا يمكن أن يكون في المستقبل',
            'notes.max' => 'الملاحظات طويلة جداً',
            'client_token.max' => 'رمز الإرسال طويل جداً',
        ];
    }
}
