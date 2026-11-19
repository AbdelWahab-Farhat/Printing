<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «أجرة المصمم» على تذكرةٍ قائمة. مَن يكتبه سؤالٌ عن هذه التذكرة بعينها، فجوابه في الفعل.
 */
class SetDesignTicketPayRequest extends FormRequest
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
            'designer_pay' => ['present', 'nullable', 'numeric', 'min:0', 'max:9999999999.99'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'designer_pay.present' => 'أجرة المصمم مطلوبة — أرسل قيمة أو فارغاً',
            'designer_pay.numeric' => 'أجرة المصمم يجب أن تكون رقماً',
            'designer_pay.min' => 'أجرة المصمم لا يمكن أن تكون سالبة',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['designer_pay' => 'أجرة المصمم'];
    }

    /** نصٌّ عشري لا float، كأيّ مبلغ. */
    public function designerPay(): ?string
    {
        $pay = $this->validated('designer_pay');

        return $pay === null ? null : (string) $pay;
    }
}
