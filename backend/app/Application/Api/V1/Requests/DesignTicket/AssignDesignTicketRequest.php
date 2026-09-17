<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AssignDesignTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * **`present` rather than `required`**, which is what lets null mean something.
     *
     * Unassigning is `{"assigned_designer_id": null}`, and `required` rejects null — so the field
     * must be *present* and may be empty. An omitted key is then a mistake rather than an
     * instruction, which is the distinction that stops a half-built request quietly clearing
     * somebody's queue. The shape `AssignShortageRequest` settled on.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'assigned_designer_id' => [
                'present', 'nullable', 'integer',
                Rule::exists('users', 'id')->withoutTrashed(),
            ],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'assigned_designer_id.present' => 'حدّد المصمم أو أرسل قيمة فارغة لإلغاء الإسناد',
            'assigned_designer_id.exists' => 'المصمم غير موجود',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['assigned_designer_id' => 'المصمم'];
    }
}
