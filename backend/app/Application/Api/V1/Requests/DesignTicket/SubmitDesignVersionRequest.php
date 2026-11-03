<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;

class SubmitDesignVersionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Identical to the attachment rules, and separate anyway.
     *
     * Written out in full rather than merged or inherited: Scramble reads `rules()` without
     * running it, and an `array_merge(parent::rules(), …)` publishes the endpoint with no request
     * body at all (RULES §7). Two endpoints that happen to agree today are also two endpoints
     * that may not tomorrow — a version may one day carry a source file where a brief never will.
     *
     * **No `version` field, and there never will be one.** The number is allocated by the action
     * from `max(version) + 1`; a client that could choose it could overwrite the conversation.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'file' => [
                'required',
                'file',
                // Read from config rather than spelled out, like every other upload in the
                // application. These two were the only endpoints carrying their own copy of
                // the list, so widening it for HEIC would have missed them.
                'mimetypes:'.implode(',', (array) config('media.design_tickets.mimetypes')),
                'mimes:'.implode(',', (array) config('media.design_tickets.mimes')),
                'max:'.config('media.design_tickets.max_kilobytes'),
            ],
            // What the designer wants to say with the version — «غيّرت الخط، قوليلي رأيك».
            'note' => ['nullable', 'string', 'max:2000'],
            // The inks this version was drawn in — `print_colors[0][name]` in the multipart body.
            // The app starts the list from the ticket's; the approved version's go into the
            // customer's library with the file.
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
            'file.required' => 'ملف التصميم مطلوب',
            'file.mimetypes' => 'الملف يجب أن يكون صورة أو PDF',
            'file.mimes' => 'الملف يجب أن يكون صورة أو PDF',
            'file.max' => 'حجم الملف يجب ألا يتجاوز '.
                (int) (config('media.design_tickets.max_kilobytes') / 1024).' ميجابايت',
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
            'note' => 'ملاحظة المصمم',
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.code' => 'رمز اللون',
            'print_colors.*.hex' => 'لون العيّنة',
        ];
    }
}
