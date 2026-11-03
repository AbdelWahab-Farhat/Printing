<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;

class UpdateDesignTicketRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Three fields and the print colors, and the absences are the decision.
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
            // `sometimes`, unlike the three above: an app that predates the colors sends this
            // PUT without them, and that must leave them alone rather than clear them.
            'print_colors' => ['sometimes', 'nullable', 'array', 'max:'.PrintColors::MAX],
            'print_colors.*.name' => ['required', 'string', 'max:'.PrintColors::NAME_MAX],
            'print_colors.*.code' => ['nullable', 'string', 'max:'.PrintColors::CODE_MAX],
            'print_colors.*.hex' => ['nullable', 'string', 'regex:'.PrintColors::HEX_PATTERN],
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
            'print_colors.max' => 'لا تزيد ألوان الطباعة على :max',
            'print_colors.*.name.required' => 'اسم اللون مطلوب',
            'print_colors.*.hex.regex' => 'لون العيّنة يجب أن يكون بصيغة #RRGGBB',
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
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.code' => 'رمز اللون',
            'print_colors.*.hex' => 'لون العيّنة',
        ];
    }
}
