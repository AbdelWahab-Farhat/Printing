<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Order;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;

/**
 * The print colors on one version of an order's artwork — for this order alone.
 *
 * **`present`, not `sometimes`.** It is the only field, so leaving it out is a half-built request
 * rather than "change nothing"; an empty list or null clears the colors.
 */
class UpdateOrderDesignColorsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Written out in full rather than borrowed — Scramble reads this method without running it
     * (RULES §7). The same four lines stand in every request that takes print colors.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'print_colors' => ['present', 'nullable', 'array', 'max:'.PrintColors::MAX],
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
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.code' => 'رمز اللون',
            'print_colors.*.hex' => 'لون العيّنة',
        ];
    }
}
