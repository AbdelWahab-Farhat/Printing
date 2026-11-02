<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Design;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;

/**
 * A customer choosing the inks on their own design — a name and a swatch each, and no code.
 *
 * **`present`**: it is the only field, so leaving it out is a half-built request; an empty list
 * clears them. A `code` sent anyway is not refused but never stored — `ChooseDesignColors`
 * strips it. Refused with 422 once an employee has put a code on the list.
 */
class UpdateClientDesignColorsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Written out in full — Scramble reads this method without running it (RULES §7).
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'print_colors' => ['present', 'nullable', 'array', 'max:'.PrintColors::MAX],
            'print_colors.*.name' => ['required', 'string', 'max:'.PrintColors::NAME_MAX],
            'print_colors.*.hex' => ['required', 'string', 'regex:'.PrintColors::HEX_PATTERN],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'print_colors.max' => 'لا تزيد ألوان الطباعة على :max',
            'print_colors.*.name.required' => 'اسم اللون مطلوب',
            'print_colors.*.hex.required' => 'اختر لون كل حبر',
            'print_colors.*.hex.regex' => 'لون العيّنة يجب أن يكون بصيغة #RRGGBB',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.hex' => 'اللون',
        ];
    }
}
