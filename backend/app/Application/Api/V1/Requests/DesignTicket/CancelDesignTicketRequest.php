<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

class CancelDesignTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * The reason is required, and it is the whole content of a cancellation.
     *
     * «الزبون غيّر رأيه» and «فُتحت بالخطأ» are the same status and entirely different facts, and
     * a designer whose job disappeared overnight is owed the difference. Guarded again in the
     * action and a third time by `design_tickets_cancellation_shape` — validation gives the
     * readable 422, the constraint is the guarantee.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'reason' => ['required', 'string', 'min:3', 'max:1000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'reason.required' => 'اكتب سبب إلغاء التذكرة',
            'reason.min' => 'السبب قصير جداً',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['reason' => 'سبب الإلغاء'];
    }
}
