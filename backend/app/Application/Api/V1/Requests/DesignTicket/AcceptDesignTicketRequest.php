<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

/**
 * القبول، ومعه «أجر التصميم» حين لا أجر على التذكرة: مَن يأخذها من الطابور هو من يعرفه.
 */
class AcceptDesignTicketRequest extends FormRequest
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
            'designer_pay' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
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
