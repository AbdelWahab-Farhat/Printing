<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

/**
 * «أجر التصميم» على تذكرةٍ قائمة. مَن يكتبه سؤالٌ عن هذه التذكرة بعينها، فجوابه في الفعل.
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
            'designer_pay.present' => 'أجر التصميم مطلوب — أرسل قيمة أو فارغاً',
            'designer_pay.numeric' => 'أجر التصميم يجب أن يكون رقماً',
            'designer_pay.min' => 'أجر التصميم لا يمكن أن يكون سالباً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['designer_pay' => 'أجر التصميم'];
    }

    /** نصٌّ عشري لا float، كأيّ مبلغ. */
    public function designerPay(): ?string
    {
        $pay = $this->validated('designer_pay');

        return $pay === null ? null : (string) $pay;
    }
}
