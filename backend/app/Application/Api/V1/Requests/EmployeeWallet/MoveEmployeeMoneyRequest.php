<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\EmployeeWallet;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * مالٌ عبر الطاولة: «إيداع» سلّمه الموظف أو «سحب» قبضه — الحقول نفسها في الاتجاهين، مكتوبةً كاملةً
 * لأن Scramble يقرأ `rules()` بلا تشغيل (RULES §7).
 */
class MoveEmployeeMoneyRequest extends FormRequest
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

            // طرق المكتب الأربع في الاتجاهين — قرار صاحب العمل ٢٠٢٦-١١-٠٥.
            'method' => ['required', Rule::enum(EmployeeWalletMethod::class)],

            'reference' => ['nullable', 'string', 'max:100'],

            // متى تحرّك المال. التاريخُ الماضي عاديّ، والمستقبلُ ليس مالاً بعد.
            'occurred_at' => ['nullable', 'date', 'before_or_equal:now'],

            'notes' => ['nullable', 'string', 'max:1000'],

            // إجباريٌّ للحوالة — `EmployeeWalletMethod::requiresReceipt()` وقيدٌ في القاعدة يقولانه أيضاً.
            'receipt' => [
                'required_if:method,'.EmployeeWalletMethod::BankTransfer->value,
                'nullable',
                'file',
                'mimetypes:'.implode(',', (array) config('media.payment_receipts.mimetypes')),
                'mimes:'.implode(',', (array) config('media.payment_receipts.mimes')),
                'max:'.config('media.payment_receipts.max_kilobytes'),
            ],

            // أين نزل المال أو من أين خرج. اختياريّ: الخزينة تقرّر، كما في دفعة الطلبية.
            'treasury_account_id' => [
                'nullable',
                'integer',
                Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at'),
            ],

            // رمزٌ يولّده التطبيق قبل الإرسال، فلا تكتب الضغطةُ الثانية حركةً ثانية.
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
            'method.required' => 'الطريقة مطلوبة',
            'method.enum' => 'الطريقة غير معروفة',
            'reference.max' => 'رقم المرجع طويل جداً',
            'occurred_at.date' => 'التاريخ غير صحيح',
            'occurred_at.before_or_equal' => 'التاريخ لا يمكن أن يكون في المستقبل',
            'notes.max' => 'الملاحظات طويلة جداً',
            'receipt.required_if' => 'الحوالة تتطلب إرفاق الواصل',
            'receipt.file' => 'الواصل يجب أن يكون ملفاً',
            'receipt.mimetypes' => 'الواصل يجب أن يكون ملف PDF أو صورة',
            'receipt.mimes' => 'الواصل يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP',
            'receipt.max' => 'حجم الواصل يجب ألا يتجاوز '.
                (int) (config('media.payment_receipts.max_kilobytes') / 1024).' ميجابايت',
            'treasury_account_id.exists' => 'الحساب غير موجود',
            'client_token.max' => 'رمز الإرسال طويل جداً',
        ];
    }
}
