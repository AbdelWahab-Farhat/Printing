<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\PurchaseOrder;

use App\Domain\Order\Enums\PaymentMethod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * A payment to a vendor (`type=payment`, the default) or what was owed on opening day
 * (`type=opening_debt`, no method and no account — no money moved).
 */
class StoreVendorPaymentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['nullable', Rule::in(['payment', 'opening_debt'])],
            'amount' => ['required', 'numeric', 'gt:0', 'max:9999999999'],
            'method' => ['exclude_if:type,opening_debt', 'required', Rule::enum(PaymentMethod::class)],
            'treasury_account_id' => [
                'exclude_if:type,opening_debt',
                'nullable',
                'integer',
                Rule::exists('treasury_accounts', 'id')->whereNull('deleted_at'),
            ],
            'purchase_order_id' => ['nullable', 'integer', Rule::exists('purchase_orders', 'id')->whereNull('deleted_at')],
            'reference' => ['nullable', 'string', 'max:100'],
            'paid_at' => ['nullable', 'date', 'before_or_equal:now'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'receipt' => [
                'nullable',
                'file',
                'mimetypes:'.implode(',', (array) config('media.payment_receipts.mimetypes')),
                'mimes:'.implode(',', (array) config('media.payment_receipts.mimes')),
                'max:'.config('media.payment_receipts.max_kilobytes'),
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'amount.required' => 'المبلغ مطلوب',
            'amount.gt' => 'المبلغ يجب أن يكون أكبر من صفر',
            'method.required' => 'طريقة الدفع مطلوبة',
            'method.enum' => 'طريقة الدفع غير معروفة',
            'purchase_order_id.exists' => 'أمر الشراء غير موجود',
            'paid_at.before_or_equal' => 'تاريخ الدفع لا يكون في المستقبل',
        ];
    }

    public function attributes(): array
    {
        return [
            'type' => 'نوع الحركة',
            'amount' => 'المبلغ',
            'method' => 'طريقة الدفع',
            'treasury_account_id' => 'الحساب',
            'purchase_order_id' => 'أمر الشراء',
            'reference' => 'رقم المرجع',
            'paid_at' => 'تاريخ الدفع',
            'notes' => 'الملاحظات',
            'receipt' => 'الواصل',
        ];
    }
}
