<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\InternalTicket;

use Illuminate\Foundation\Http\FormRequest;

/**
 * تعديلُ نصّ رسالة — النصُّ وحده، كبريمولا: لا المرفقات ولا المقتبَس.
 */
class EditInternalMessageRequest extends FormRequest
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
