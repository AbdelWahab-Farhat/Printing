<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\DTOs;

use Illuminate\Http\UploadedFile;

/**
 * رسالةٌ في طريقها إلى محادثة التذكرة: كلامٌ، أو ملفّ — صوتٌ أو صورٌ — أو كلاهما، ومعها ما يقوله
 * الهاتف عن الصوت.
 *
 * كـ`InternalMessageData`: **المدّة والموجة ادّعاءٌ من الهاتف**، للعرض وحده. الحدُّ الذي يُعتمد
 * عليه حجمُ الملف، يحرسه الطلب بالبايتات.
 */
final readonly class DesignTicketMessageData
{
    /**
     * @param  list<UploadedFile>  $files
     * @param  list<int>|null  $waveform
     */
    public function __construct(
        public ?string $body = null,
        public array $files = [],
        public ?int $durationSeconds = null,
        public ?array $waveform = null,
        public ?int $replyToMessageId = null,
        public ?string $clientToken = null,
    ) {}

    /**
     * @param  array<string, mixed>  $data  already-validated request data
     * @param  list<UploadedFile>  $files  بالترتيب الذي اختيرت به
     */
    public static function fromArray(array $data, array $files = []): self
    {
        $body = trim((string) ($data['body'] ?? ''));

        return new self(
            body: $body !== '' ? $body : null,
            files: $files,
            durationSeconds: isset($data['duration_seconds']) ? (int) $data['duration_seconds'] : null,
            waveform: isset($data['waveform'])
                ? array_values(array_map(fn ($bar) => (int) $bar, (array) $data['waveform']))
                : null,
            replyToMessageId: isset($data['reply_to_message_id']) ? (int) $data['reply_to_message_id'] : null,
            clientToken: isset($data['client_token']) && $data['client_token'] !== ''
                ? (string) $data['client_token']
                : null,
        );
    }
}
