<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\DesignTicket;

use App\Application\Rules\ChatAttachmentFile;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Http\UploadedFile;

/**
 * رسالةٌ في محادثة تذكرة تصميم: كلامٌ، أو صورة، أو صوت، أو كلامٌ مع صورة — بقواعد رسالة التذكرة
 * الداخلية نفسها وحدودها (DESIGN-TICKET-CHAT §٣).
 *
 * **الصورُ ألبومٌ في رسالةٍ واحدة** (`files[]`، حتى عشر)، كبريمولا: الصورُ وتعليقُها رسالةٌ واحدة لا
 * رسائلُ متفرّقة. و`file` يبقى للصوت، وللنسخ القديمة من التطبيق التي ترسل صورةً واحدة.
 * و`duration_seconds` و`waveform` يرسلهما الهاتف مع الصوت، للعرض وحده — الحدُّ الحقيقي حجمُ الملف.
 */
class PostDesignTicketMessageRequest extends FormRequest
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
            'body' => ['nullable', 'required_without_all:file,files', 'string', 'max:5000'],
            'file' => ['nullable', 'file', new ChatAttachmentFile],
            'files' => ['nullable', 'array', 'max:'.config('media.chat_attachments.max_images_per_message'), 'prohibits:file'],
            'files.*' => ['file', new ChatAttachmentFile(imagesOnly: true)],
            // حتى خمس دقائق، كبريمولا.
            'duration_seconds' => ['nullable', 'integer', 'min:0', 'max:'.config('media.chat_attachments.voice_max_seconds')],
            // ٤٨ عموداً من ٠ إلى ١٠٠.
            'waveform' => ['nullable', 'array', 'max:'.config('media.chat_attachments.waveform_bars')],
            'waveform.*' => ['integer', 'min:0', 'max:100'],
            // من التذكرة نفسها — يحرسه الفعل، لأن `exists:` لا يعرف أيّ محادثة.
            'reply_to_message_id' => ['nullable', 'integer'],
            'client_token' => ['nullable', 'string', 'max:64'],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'body.required_without_all' => 'اكتب رسالتك أو أرفق صورة أو رسالة صوتية',
            'files.max' => 'عشر صور على الأكثر في الرسالة',
            'body.max' => 'الرسالة أطول من ٥٠٠٠ حرف',
            'duration_seconds.max' => 'الرسالة الصوتية لا تتجاوز خمس دقائق',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['body' => 'الرسالة', 'file' => 'المرفق', 'files' => 'الصور', 'duration_seconds' => 'المدة'];
    }

    /**
     * ما أُرفق، بالترتيب الذي اختيرت به الصور: الصوتُ أو الصورةُ الواحدة في `file`، أو الألبوم.
     *
     * @return list<UploadedFile>
     */
    public function attachedFiles(): array
    {
        $file = $this->file('file');

        if ($file instanceof UploadedFile) {
            return [$file];
        }

        return array_values(array_filter(
            (array) $this->file('files', []),
            fn (mixed $image): bool => $image instanceof UploadedFile,
        ));
    }
}
