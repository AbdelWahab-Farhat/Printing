<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

/**
 * تعديلُ نصّ رسالةٍ في محادثة تذكرة تصميم — النصُّ وحده، كالتذاكر الداخلية: لا المرفقات ولا المقتبَس.
 */
class EditDesignTicketMessageRequest extends FormRequest
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
            'body' => ['required', 'string', 'max:5000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'body.required' => 'اكتب نص الرسالة',
            'body.max' => 'الرسالة أطول من ٥٠٠٠ حرف',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['body' => 'الرسالة'];
    }
}
