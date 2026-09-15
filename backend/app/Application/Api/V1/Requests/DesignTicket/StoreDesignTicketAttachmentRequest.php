<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use Illuminate\Foundation\Http\FormRequest;

class StoreDesignTicketAttachmentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * The same file rules a customer design carries, and deliberately the same numbers.
     *
     * A brief becomes the reference a version is drawn from, and a version becomes a customer
     * design — two different limits would mean a file that could be attached and then refused at
     * the moment it mattered.
     *
     * **No `image` rule**: that is the one that rejects a PDF outright, and its job is done better
     * by `mimetypes`, which reads the magic bytes with finfo rather than trusting the extension or
     * the client's Content-Type header.
     *
     * `svg` is absent and must stay absent: an SVG is an HTML document, and one served from our
     * own origin is stored XSS.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'file' => [
                'required',
                'file',
                'mimetypes:application/pdf,image/jpeg,image/png,image/webp',
                // A second reading of the same bytes, kept because it is the rule whose Arabic
                // message names extensions — which is what a person needs to be told.
                'mimes:pdf,jpg,jpeg,png,webp',
                'max:'.config('media.design_tickets.max_kilobytes'),
            ],
            'note' => ['nullable', 'string', 'max:2000'],
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
                (int) (config('media.design_tickets.max_kilobytes') / 1024).' ميجابايت',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'file' => 'الملف',
            'note' => 'ملاحظة',
        ];
    }
}
