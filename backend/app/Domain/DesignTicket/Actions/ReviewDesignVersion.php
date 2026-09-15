<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Exceptions\DesignerCannotReviewOwnWork;
use App\Domain\DesignTicket\Exceptions\DesignReviewRequiresNote;
use App\Domain\DesignTicket\Exceptions\DesignTicketIsClosed;
use App\Domain\DesignTicket\Exceptions\DesignVersionAlreadyReviewed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * The employee's verdict on one version — and, when it is «موافقة», the end of the ticket.
 *
 * **Approving is not a status change followed by some bookkeeping; it is one fact with four
 * parts**, which is why they share a transaction: the version is sealed, the artwork lands on the
 * customer's account, the ticket closes, and the row that closed it is named. The database
 * refuses any partial version of that through `design_tickets_completion_shape` — «مكتمل» with no
 * `approved_customer_design_id` cannot be written at all. That constraint is what makes the
 * brief's headline promise unrepresentable when wrong rather than a step somebody can forget.
 *
 * **The reviewer may not be the uploader**, and this is the one guard that is not about
 * correctness. Withholding `design_tickets.review` from the designer role is necessary and not
 * sufficient — an administrator holds every permission by rule — so the separation of execution
 * from approval has to be a domain refusal or it is not real. `ConfirmDepositReceipt` draws the
 * same line in the same place for the same reason.
 *
 * **A version is judged once.** Changing a verdict afterwards would erase the reason the next
 * version exists, and that trail is the entire value of keeping versions at all.
 *
 * **A change request must say what to change.** The whole point of a revision round is the words.
 */
final class ReviewDesignVersion
{
    public function __construct(private readonly PromoteApprovedDesign $promote) {}

    /**
     * @throws DesignTicketIsClosed
     * @throws DesignVersionAlreadyReviewed
     * @throws DesignerCannotReviewOwnWork
     * @throws DesignReviewRequiresNote
     */
    public function __invoke(
        DesignTicket $ticket,
        DesignTicketFile $version,
        DesignSubmissionStatus $verdict,
        ?string $note = null,
        ?User $actor = null,
    ): DesignTicketFile {
        if (! $ticket->isOpen()) {
            throw DesignTicketIsClosed::make($ticket->status);
        }

        if ($version->status?->isReviewed() === true) {
            throw DesignVersionAlreadyReviewed::make((int) $version->version, $version->status);
        }

        // Before the note check, so somebody reviewing their own work is told the real reason
        // rather than being sent to write a note that will be refused anyway.
        if ($actor !== null
            && $version->uploaded_by_user_id !== null
            && (int) $version->uploaded_by_user_id === (int) $actor->getKey()) {
            throw DesignerCannotReviewOwnWork::make();
        }

        $note = $note === null ? null : (trim($note) !== '' ? trim($note) : null);

        if ($verdict->requiresNote() && $note === null) {
            throw DesignReviewRequiresNote::make();
        }

        return DB::transaction(function () use ($ticket, $version, $verdict, $note, $actor): DesignTicketFile {
            $version->forceFill([
                'status' => $verdict,
                'review_note' => $note,
                'reviewed_at' => now(),
                'reviewed_by' => $actor?->getKey(),
            ])->save();

            $status = $verdict === DesignSubmissionStatus::Approved
                ? DesignTicketStatus::Completed
                : DesignTicketStatus::ChangesRequested;

            $attributes = ['status' => $status];

            if ($verdict === DesignSubmissionStatus::Approved) {
                $design = ($this->promote)($ticket, $version);

                $attributes['completed_at'] = now();
                $attributes['approved_by_user_id'] = $actor?->getKey();
                $attributes['approved_customer_design_id'] = $design->getKey();
            }

            $ticket->forceFill($attributes)->save();

            DesignTicketProgressed::dispatch(
                (int) $ticket->getKey(),
                $status,
                $actor === null ? null : (int) $actor->getKey(),
            );

            return $version->refresh();
        });
    }
}
