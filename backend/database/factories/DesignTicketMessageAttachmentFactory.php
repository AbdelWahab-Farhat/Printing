<?php

namespace Database\Factories;

use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\DesignTicket\Models\DesignTicketMessageAttachment;
use App\Support\Media\ChatAttachmentKind;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<DesignTicketMessageAttachment>
 *
 * صورةٌ افتراضاً، و`voice()` لرسالةٍ صوتية. الملفُّ نفسه لا يُكتب على قرص: الاختبار الذي يحتاجه
 * يرفعه عبر المسار.
 */
class DesignTicketMessageAttachmentFactory extends Factory
{
    /** @var class-string<DesignTicketMessageAttachment> */
    protected $model = DesignTicketMessageAttachment::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'message_id' => DesignTicketMessage::factory(),
            'kind' => ChatAttachmentKind::Image,
            'disk' => 'local',
            'path' => 'design-ticket-messages/'.Str::uuid()->toString().'.jpg',
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
            'kind' => ChatAttachmentKind::Voice,
            'path' => 'design-ticket-messages/'.Str::uuid()->toString().'.m4a',
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
