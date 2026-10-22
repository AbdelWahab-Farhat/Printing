<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

/**
 * يضع صورةً أو رسالةً صوتية على القرص، ويُرجع ما يُختم به صفُّ المرفق.
 *
 * على طريقة `StoreTicketAttachment` في سياق الدعم، وللأسباب نفسها: النوعُ من البايتات، والاسمُ على القرص
 * يولّده الخادم، والملفُّ يُكتب قبل الصف وخارج معاملته.
 *
 * **المدّة والموجة للصوت وحده**، وتُقصّان إلى حدودهما: هاتفٌ يقول إن رسالته ساعة لا يُصدَّق،
 * وموجةٌ بأرقامٍ خارج ٠–١٠٠ لا تُرسم.
 */
final class StoreInternalAttachment
{
    /**
     * @param  list<int>|null  $waveform
     * @return array<string, mixed>
     */
    public function __invoke(int $ticketId, UploadedFile $file, ?int $durationSeconds = null, ?array $waveform = null): array
    {
        $mimeType = (string) $file->getMimeType();
        $kind = InternalAttachmentKind::fromMimeType($mimeType);
        $disk = (string) config('media.internal_ticket_attachments.disk');

        $path = $file->storeAs(
            "internal-ticket-attachments/{$ticketId}",
            Str::uuid()->toString().'.'.$this->extensionOf($file, $kind),
            ['disk' => $disk],
        );

        [$width, $height] = $kind === InternalAttachmentKind::Image ? $this->dimensionsOf($file) : [null, null];
        $isVoice = $kind === InternalAttachmentKind::Voice;

        return [
            'kind' => $kind,
            'disk' => $disk,
            'path' => $path,
            'filename' => $file->getClientOriginalName(),
            'mime_type' => $mimeType,
            'size_bytes' => $file->getSize(),
            'width_px' => $width,
            'height_px' => $height,
            'duration_seconds' => $isVoice && $durationSeconds !== null
                ? max(0, min($durationSeconds, (int) config('media.internal_ticket_attachments.voice_max_seconds')))
                : null,
            'waveform' => $isVoice && $waveform !== null ? $this->clampWaveform($waveform) : null,
        ];
    }

    /**
     * الامتدادُ من النوع حين يكون صوتاً: m4a يقرؤه finfo `video/mp4` أحياناً، وامتدادُ `mp4` على
     * القرص كان سيجعل الملف يبدو فيديو لكل من يفتح المجلد.
     */
    private function extensionOf(UploadedFile $file, InternalAttachmentKind $kind): string
    {
        $guessed = (string) $file->extension();

        if ($kind === InternalAttachmentKind::Voice && in_array($guessed, ['', 'mp4', 'bin'], true)) {
            return 'm4a';
        }

        return $guessed !== '' ? $guessed : 'bin';
    }

    /**
     * @return array{0: int|null, 1: int|null}
     */
    private function dimensionsOf(UploadedFile $file): array
    {
        $size = @getimagesize($file->getRealPath());

        return $size === false ? [null, null] : [$size[0], $size[1]];
    }

    /**
     * @param  list<int>  $waveform
     * @return list<int>
     */
    private function clampWaveform(array $waveform): array
    {
        $bars = array_slice($waveform, 0, (int) config('media.internal_ticket_attachments.waveform_bars'));

        return array_values(array_map(fn (int $bar) => max(0, min($bar, 100)), $bars));
    }
}
