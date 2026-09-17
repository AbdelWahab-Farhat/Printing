<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

class UpdateDesignTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Three fields, and the absences are the decision.
     *
     * **The customer cannot be changed**, because files, versions and a conversation hang off a
     * ticket by the time anybody notices the wrong one was picked — see `UpdateDesignTicket`.
     * **Nor can the designer**, which is `PATCH /designer` behind its own grant: routing work is a
     * different job from describing it, the same split `shortages.assign` makes.
     *
     * Written out in full rather than merged from the store request — Scramble reads this method
     * without running it, and a merged array publishes no request body at all (RULES §7).
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string', 'max:5000'],
            'instructions' => ['nullable', 'string', 'max:5000'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'title.required' => 'عنوان الطلب مطلوب',
            'description.required' => 'وصف طلب التصميم مطلوب',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'title' => 'عنوان الطلب',
            'description' => 'وصف الطلب',
            'instructions' => 'الملاحظات والتعليمات',
        ];
    }
}
