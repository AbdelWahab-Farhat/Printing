<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Customer;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;

class StoreCustomerDesignRequest extends FormRequest
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
            'file' => [
                'required',
                'file',
                // **No `image` rule.** That is the one that rejects a PDF outright, and its job
                // is done better below: `mimetypes` reads the magic bytes with finfo instead of
                // trusting the extension or the client's Content-Type header.
                //
                // `svg` is absent and must stay absent: an SVG is an HTML document, and one
                // served from our own origin is stored XSS.
                'mimetypes:application/pdf,image/jpeg,image/png,image/webp',
                // A second reading of the same bytes, not a check of the filename — Laravel's
                // `mimes` guesses the extension from the *content* too. It is kept because it
                // is the rule whose Arabic message names extensions, which is what a person
                // needs to be told; the client's own filename is never trusted anywhere.
                'mimes:pdf,jpg,jpeg,png,webp',
                'max:'.config('media.customer_designs.max_kilobytes'),
            ],
            // How staff tell two designs apart. Optional here because the action falls back to
            // the filename rather than leaving a row with no name at all.
            'label' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string', 'max:2000'],
            // «ألوان الطباعة» — optional, as `print_colors[0][name]` in the multipart body.
            'print_colors' => ['nullable', 'array', 'max:'.PrintColors::MAX],
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
            'file.required' => 'الملف مطلوب',
            'file.mimetypes' => 'الملف يجب أن يكون صورة أو PDF',
            'file.mimes' => 'الملف يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP',
            'file.max' => 'حجم الملف يجب ألا يتجاوز '.
                (int) (config('media.customer_designs.max_kilobytes') / 1024).' ميجابايت',
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
            'file' => 'ملف التصميم',
            'label' => 'اسم التصميم',
            'notes' => 'ملاحظات',
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.code' => 'رمز اللون',
            'print_colors.*.hex' => 'لون العيّنة',
        ];
    }
}
