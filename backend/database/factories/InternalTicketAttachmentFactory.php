<?php

namespace Database\Factories;

use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use App\Domain\InternalTicket\Models\InternalTicketAttachment;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<InternalTicketAttachment>
 *
 * صورةٌ افتراضاً، و`voice()` لرسالةٍ صوتية. الملفُّ نفسه لا يُكتب على قرص: الاختبار الذي يحتاجه
 * يرفعه عبر المسار.
 */
class InternalTicketAttachmentFactory extends Factory
{
    /** @var class-string<InternalTicketAttachment> */
    protected $model = InternalTicketAttachment::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'message_id' => InternalTicketMessage::factory(),
            'kind' => InternalAttachmentKind::Image,
            'disk' => 'local',
            'path' => 'internal-ticket-attachments/'.Str::uuid()->toString().'.jpg',
            'filename' => 'photo.jpg',
            'mime_type' => 'image/jpeg',
            'size_bytes' => 120_000,
            'width_px' => 800,
            'height_px' => 600,
        ];
    }

    public function voice(int $seconds = 12): static
    {
        return $this->state(fn () => [
            'kind' => InternalAttachmentKind::Voice,
            'path' => 'internal-ticket-attachments/'.Str::uuid()->toString().'.m4a',
            'filename' => 'voice.m4a',
            'mime_type' => 'audio/mp4',
            'size_bytes' => 6_000 * $seconds,
            'width_px' => null,
            'height_px' => null,
            'duration_seconds' => $seconds,
            'waveform' => array_fill(0, 48, 40),
        ]);
    }
}
