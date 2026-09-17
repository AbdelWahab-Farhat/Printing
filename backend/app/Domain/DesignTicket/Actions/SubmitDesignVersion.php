<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\Customer\Enums\DesignKind;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Exceptions\DesignTicketBelongsToAnotherDesigner;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Exceptions\DesignTicketNotAcceptedYet;
use App\Domain\DesignTicket\Exceptions\DesignTicketTransitionNotAllowed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Models\User;
use App\Support\Media\StoreUploadedFile;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

/**
 * The designer sends work up for review — the first version, or the next one.
 *
 * **One action for both, and that is an acceptance criterion rather than a convenience.** «طلب
 * التعديل يعيد التذكرة للمصمم دون إنشاء تذكرة جديدة» and «يمكن تنفيذ أكثر من دورة تعديل لنفس
 * الطلب» are the same requirement read twice: a revision is a row, not a new ticket, so this is
 * called identically from «قيد التصميم» and from «تعديل مطلوب».
 *
 * **The version number is allocated, not counted.** `max(version) + 1` including trashed rows,
 * so removing version 2 does not make the next upload a second version 3 — «التصميم الثالث» keeps
 * meaning the file it meant in the conversation. `AddOrderDesign`'s rule, and the partial unique
 * index is what makes it a guarantee rather than an intention.
 *
 * **Nothing is ever replaced.** There is no endpoint that swaps a version's bytes; a different
 * file is a new row with a new number, and every earlier one stays readable for ever. That is the
 * brief's «لا يتم استبدال التصميم القديم عند رفع نسخة جديدة» stated as a shape rather than a
 * habit.
 *
 * Wrapped in a transaction because the insert and the ticket's move are one fact: a version that
 * existed while the ticket still read «قيد التصميم» would sit in nobody's queue.
 */
final class SubmitDesignVersion
{
    public function __construct(private readonly StoreUploadedFile $storeFile) {}

    /**
     * @throws DesignTicketIsClosed
     * @throws DesignTicketNotAcceptedYet
     * @throws DesignTicketBelongsToAnotherDesigner
     * @throws DesignTicketTransitionNotAllowed
     */
    public function __invoke(
        DesignTicket $ticket,
        UploadedFile $file,
        User $designer,
        ?string $note = null,
    ): DesignTicketFile {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        if (! $ticket->isAccepted()) {
            throw DesignTicketNotAcceptedYet::make();
        }

        if (! $ticket->isWorkableBy($designer)) {
            throw DesignTicketBelongsToAnotherDesigner::make();
        }

        // Catches the one remaining case the checks above do not: a second upload while a version
        // is already under review. Refused against the map rather than with a bespoke message,
        // because it is a mistake only a stale screen makes.
        if (! $ticket->status->acceptsSubmissions()) {
            throw DesignTicketTransitionNotAllowed::make($ticket->status, DesignTicketStatus::UnderReview);
        }

        // Outside the transaction on purpose: a failed insert afterwards leaves an orphaned
        // object, which costs storage, where the reverse leaves a row pointing at nothing — a
        // version the designer can see listed and nobody can open.
        $stored = ($this->storeFile)(
            $file,
            (string) config('media.design_tickets.disk'),
            "design-tickets/{$ticket->getKey()}",
        );

        return DB::transaction(function () use ($ticket, $stored, $designer, $note): DesignTicketFile {
            // withTrashed: a removed version still used its number, and reusing it would collide
            // with the partial unique index the moment that row were restored.
            $nextVersion = (int) $ticket->files()->withTrashed()
                ->where('kind', DesignTicketFileKind::Submission)
                ->max('version') + 1;

            $version = $ticket->files()->make(['note' => $note]);

            $version->forceFill([
                'kind' => DesignTicketFileKind::Submission,
                'version' => $nextVersion,
                'status' => DesignSubmissionStatus::Proposed,
                'disk' => $stored->disk,
                'path' => $stored->path,
                'original_filename' => $stored->originalFilename,
                'mime_type' => $stored->mimeType,
                'file_kind' => DesignKind::fromMimeType($stored->mimeType),
                'size_bytes' => $stored->sizeBytes,
                'checksum' => $stored->checksum,
                'width_px' => $stored->widthPx,
                'height_px' => $stored->heightPx,
                'uploaded_by_user_id' => $designer->getKey(),
            ])->save();

            $ticket->forceFill(['status' => DesignTicketStatus::UnderReview])->save();

            DesignTicketProgressed::dispatch(
                (int) $ticket->getKey(),
                DesignTicketStatus::UnderReview,
                (int) $designer->getKey(),
            );

            return $version->refresh();
        });
    }
}
