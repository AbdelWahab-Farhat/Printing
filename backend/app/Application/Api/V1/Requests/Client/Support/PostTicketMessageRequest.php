<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Client\Support;

use Illuminate\Foundation\Http\FormRequest;

/**
 * رسالةٌ من أيّ الطرفين: كلامٌ، أو ملفٌّ، أو كلاهما.
 *
 * **الملف يُعرف من بايتاته.** `mimetypes` تقرأ البايتات بـfinfo، و`mimes` قراءةٌ ثانية للبايتات
 * نفسها — تبقى لأن رسالتها العربية تسمّي الامتدادات، وهو ما يحتاج المرسل أن يُقال له. واسمُ
 * الملف الذي اختاره صاحبه لا يُصدَّق في شيء. و`svg` غائبٌ ويبقى غائباً.
 *
 * `client_token` رمزٌ يولّده التطبيق قبل الإرسال ليجعل الإعادة آمنة — انظر PostTicketMessage.
 */
class PostTicketMessageRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'body' => ['nullable', 'required_without:file', 'string', 'max:2000'],
            'file' => [
                'nullable',
                'file',
                'mimetypes:'.implode(',', (array) config('media.ticket_attachments.mimetypes')),
                'mimes:'.implode(',', (array) config('media.ticket_attachments.mimes')),
                'max:'.config('media.ticket_attachments.max_kilobytes'),
            ],
            'client_token' => ['nullable', 'string', 'max:64'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'body.required_without' => 'اكتب رسالتك أو أرفق ملفاً',
            'file.mimetypes' => 'الملف يجب أن يكون صورة أو PDF',
            'file.mimes' => 'الملف يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP',
            'file.max' => 'حجم الملف يجب ألا يتجاوز '.
                (int) ((int) config('media.ticket_attachments.max_kilobytes') / 1024).' ميجابايت',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['body' => 'الرسالة', 'file' => 'المرفق'];
    }
}
