<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use App\Domain\Customer\Support\PrintColors;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\UploadedFile;
use Illuminate\Validation\Validator;

class SubmitDesignVersionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Separate from the attachment rules, and no longer the same as them: a brief is one file of
     * any kind, a version is two images or more.
     *
     * Written out in full rather than merged or inherited: Scramble reads `rules()` without
     * running it, and an `array_merge(parent::rules(), …)` publishes the endpoint with no request
     * body at all (RULES §7).
     *
     * **No `version` field, and there never will be one.** The number is allocated by the action
     * from `max(version) + 1`; a client that could choose it could overwrite the conversation.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            // **Two images or more** (DESIGN-VERSION-IMAGES.md, owner 2026-11-20). Every image of
            // the approved version is drawn on the order card, so they are images only.
            'files' => [
                'required',
                'array',
                'min:'.config('media.design_tickets.min_version_images'),
                'max:'.config('media.design_tickets.max_version_images'),
            ],
            'files.*' => [
                'required',
                'file',
                'mimetypes:'.implode(',', (array) config('media.design_tickets.version_mimetypes')),
                'mimes:'.implode(',', (array) config('media.design_tickets.version_mimes')),
                'max:'.config('media.design_tickets.max_kilobytes'),
            ],
            // **The single-file field of the app before 2026-11-20, refused with a sentence.** A
            // version of one file is exactly what the owner ruled out, and an old app reading
            // «files مطلوب» would not know it has to be updated.
            'file' => ['prohibited'],
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
        $atLeastTwo = 'أدخل صورتين على الأقل للتصميم';

        return [
            'file.prohibited' => 'حدّث التطبيق — التصميم يحتاج صورتين على الأقل',
            'files.required' => $atLeastTwo,
            'files.array' => $atLeastTwo,
            'files.min' => $atLeastTwo,
            'files.max' => 'لا تزيد صور التصميم على :max',
            'files.*.mimetypes' => 'صور التصميم يجب أن تكون JPG أو PNG أو WEBP',
            'files.*.mimes' => 'صور التصميم يجب أن تكون JPG أو PNG أو WEBP',
            'files.*.max' => 'حجم الصورة يجب ألا يتجاوز '.
                (int) (config('media.design_tickets.max_kilobytes') / 1024).' ميجابايت',
            'print_colors.max' => 'لا تزيد ألوان الطباعة على :max',
            'print_colors.*.name.required' => 'اسم اللون مطلوب',
            'print_colors.*.hex.regex' => 'لون العيّنة يجب أن يكون بصيغة #RRGGBB',
        ];
    }

    /**
     * **The same image twice is refused** (owner, 2026-11-20): it would show twice on the order
     * card. Compared by contents, the way the library dedupes, not by filename.
     *
     * @return list<callable(Validator): void>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                if ($validator->errors()->isNotEmpty()) {
                    return;
                }

                $seen = [];

                foreach ((array) $this->file('files', []) as $file) {
                    if (! $file instanceof UploadedFile) {
                        continue;
                    }

                    $checksum = (string) hash_file('sha256', $file->getRealPath());

                    if (isset($seen[$checksum])) {
                        $validator->errors()->add('files', 'الصورة نفسها مكرّرة في التصميم');

                        return;
                    }

                    $seen[$checksum] = true;
                }
            },
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'file' => 'ملف التصميم',
            'files' => 'صور التصميم',
            'files.*' => 'صورة التصميم',
            'note' => 'ملاحظة المصمم',
            'print_colors' => 'ألوان الطباعة',
            'print_colors.*.name' => 'اسم اللون',
            'print_colors.*.code' => 'رمز اللون',
            'print_colors.*.hex' => 'لون العيّنة',
        ];
    }
}
