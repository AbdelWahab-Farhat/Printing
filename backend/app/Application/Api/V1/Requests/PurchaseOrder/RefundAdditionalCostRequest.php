<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\PurchaseOrder;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Money coming back on a purchase order's cost. Who may is the route's business
 * (`treasury.reverse`); how much is left to come back is the domain's.
 */
class RefundAdditionalCostRequest extends FormRequest
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
            'amount' => ['required', 'numeric', 'gt:0', 'decimal:0,2', 'max:999999999999.99'],
            'reason' => ['required', 'string', 'min:3', 'max:500'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'amount.required' => 'المبلغ المسترد مطلوب',
            'amount.numeric' => 'المبلغ المسترد يجب أن يكون رقماً',
            'amount.gt' => 'المبلغ المسترد يجب أن يكون أكبر من صفر',
            'amount.decimal' => 'المبلغ المسترد لا يتجاوز رقمين بعد الفاصلة',
            'amount.max' => 'المبلغ المسترد أكبر من الحد المسموح',
            'reason.required' => 'سبب الاسترداد مطلوب',
            'reason.min' => 'سبب الاسترداد قصير جداً',
            'reason.max' => 'سبب الاسترداد طويل جداً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'amount' => 'المبلغ المسترد',
            'reason' => 'سبب الاسترداد',
        ];
    }
}
