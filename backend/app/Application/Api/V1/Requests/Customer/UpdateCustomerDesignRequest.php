<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Customer;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Renaming a design, rewriting its notes or correcting its print colors — never its file.
 *
 * **There is no endpoint that swaps the file.** A design is what an order points at, so
 * replacing the bytes under a stable id would silently change what an old order says was
 * printed. A new version is a new upload.
 *
 * The colors may change, because every order holds its own copy of them — see
 * `UpdateCustomerDesign`.
 */
class UpdateCustomerDesignRequest extends FormRequest
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
        // Written out rather than borrowed from the store request: Scramble analyses this
        // method statically, and anything it cannot follow publishes an endpoint with no
        // request body at all.
        return [
            'label' => ['sometimes', 'nullable', 'string', 'max:255'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:2000'],
            // Left out, the colors stay; an empty list or null clears them.
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
            'label' => 'اسم التصميم',
            'notes' => 'ملاحظات',
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.code' => 'رمز اللون',
            'print_colors.*.hex' => 'لون العيّنة',
        ];
    }
}
