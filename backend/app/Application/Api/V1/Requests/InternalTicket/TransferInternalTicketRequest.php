<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\InternalTicket;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * «تحويل»: مَن يصير صاحب التذكرة بدل صاحبها. موظفٌ نشط — والباقي (ليس الصاحب نفسه ولا الزميل)
 * يحرسه الفعل، لأنه يعرف التذكرة.
 */
class TransferInternalTicketRequest extends FormRequest
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
            'new_owner_id' => [
                'required', 'integer',
                Rule::exists('users', 'id')->where('is_active', true)->withoutTrashed(),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'new_owner_id.required' => 'اختر الموظف الذي تحوّل إليه التذكرة',
            'new_owner_id.exists' => 'هذا الموظف غير موجود أو حسابه معطّل',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['new_owner_id' => 'الموظف'];
    }
}
