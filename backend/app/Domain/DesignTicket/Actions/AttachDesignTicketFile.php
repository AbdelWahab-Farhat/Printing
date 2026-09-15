<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\Customer\Enums\DesignKind;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Models\User;
use App\Support\Media\StoreUploadedFile;
use Illuminate\Http\UploadedFile;

/**
 * Adds one of the employee's reference files to a ticket — the logo, a photo of a similar bag.
 *
 * **A brief, not a version.** It carries no number and no verdict, and the CHECK constraint on
 * the table enforces that rather than trusting this action to remember.
 *
 * **Allowed for as long as the ticket is open**, not only at creation. «كبّر الشعار — هذا مثال
 * لما أقصده» arrives in the middle of a revision round far more often than it arrives with the
 * original request, and forcing the employee to describe a picture in words would be a worse
 * system than the WhatsApp thread it is replacing.
 *
 * The bytes go through {@see StoreUploadedFile}: sniffed type, checksum before the move,
 * generated name. What types are allowed and how large they may be is the FormRequest's business,
 * where it produces a readable 422.
 */
final class AttachDesignTicketFile
{
    public function __construct(private readonly StoreUploadedFile $storeFile) {}

    /**
     * @throws DesignTicketIsClosed
     */
    public function __invoke(
        DesignTicket $ticket,
        UploadedFile $file,
        ?User $actor = null,
        ?string $note = null,
    ): DesignTicketFile {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        $stored = ($this->storeFile)(
            $file,
            (string) config('media.design_tickets.disk'),
            "design-tickets/{$ticket->getKey()}",
        );

        $ticketFile = $ticket->files()->make(['note' => $note]);

        $ticketFile->forceFill([
            'kind' => DesignTicketFileKind::Brief,
            'disk' => $stored->disk,
            'path' => $stored->path,
            'original_filename' => $stored->originalFilename,
            'mime_type' => $stored->mimeType,
            'file_kind' => DesignKind::fromMimeType($stored->mimeType),
            'size_bytes' => $stored->sizeBytes,
            'checksum' => $stored->checksum,
            'width_px' => $stored->widthPx,
            'height_px' => $stored->heightPx,
            'uploaded_by_user_id' => $actor?->getKey(),
        ])->save();

        return $ticketFile->refresh();
    }
}
