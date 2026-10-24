<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\InternalTicket;

use App\Application\Rules\ChatAttachmentFile;
use Illuminate\Foundation\Http\FormRequest;

/**
 * رسالةٌ في تذكرةٍ داخلية: كلامٌ، أو صورة، أو صوت، أو كلامٌ مع ملف.
 *
 * **ملفٌّ واحد للرسالة**، كمحادثة الدعم: الاختيار المتعدّد في التطبيق يرسل كل ملفٍّ رسالة.
 * و`duration_seconds` و`waveform` يرسلهما الهاتف مع الصوت، للعرض وحده — الحدُّ الحقيقي حجمُ الملف.
 */
class PostInternalMessageRequest extends FormRequest
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
            'body' => ['nullable', 'required_without:file', 'string', 'max:5000'],
            'file' => ['nullable', 'file', new ChatAttachmentFile],
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
            'body.required_without' => 'اكتب رسالتك أو أرفق صورة أو رسالة صوتية',
            'body.max' => 'الرسالة أطول من ٥٠٠٠ حرف',
            'duration_seconds.max' => 'الرسالة الصوتية لا تتجاوز خمس دقائق',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return ['body' => 'الرسالة', 'file' => 'المرفق', 'duration_seconds' => 'المدة'];
    }
}
