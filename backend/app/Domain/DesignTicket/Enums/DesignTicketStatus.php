<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Enums;

use App\Domain\DesignTicket\Actions\AcceptDesignTicket;
use App\Domain\DesignTicket\Actions\CancelDesignTicket;
use App\Domain\DesignTicket\Actions\ReviewDesignVersion;
use App\Domain\DesignTicket\Actions\SubmitDesignVersion;
use App\Domain\Shortage\Enums\ShortageStatus;

/**
 * Where a design request stands, and the only moves it may make from there.
 *
 * ```
 * New ──accept──► InProgress ──submit──► UnderReview ──approve──► Completed
 *                      ▲                      │
 *                      └───submit─── ChangesRequested ◄──request changes──┘
 * ```
 *
 * **There is no endpoint that changes a status, and that is this enum's whole shape.** Not one of
 * these is picked from a dropdown; each is written by the action that earns it — {@see
 * AcceptDesignTicket}, {@see SubmitDesignVersion}, {@see ReviewDesignVersion}, {@see
 * CancelDesignTicket}. {@see allowedNext()} is therefore not a source of buttons but the map
 * those actions refuse a move against, and the app draws its buttons from the `can_*` flags on
 * the resource instead.
 *
 * This is the same conclusion {@see ShortageStatus} states outright — "the status it must never
 * offer is the one the list never contains" — taken one step further. There, one status was
 * withheld from the map because arithmetic owned it. Here *every* status is owned by an action,
 * because every one of them is a claim about something a person did: somebody took the job,
 * somebody sent work, somebody judged it. A status a clerk could set from a list would let a
 * ticket say it was accepted with nobody's name against it.
 *
 * **{@see Completed} leads nowhere, and reopening is deliberately not offered.** Approval writes
 * the artwork onto the customer's account; undoing it would mean deciding what happens to that
 * row, and to any order already pointing at it. A customer who wants a change after approval is
 * asking for new work, which is a new ticket — and the old one stays as the record of what was
 * agreed.
 *
 * **{@see Cancelled} is the one ending that is not an outcome.** It says the request should not
 * have been made, or is no longer wanted, and it always carries a reason. It is not a way to
 * reject a design — that is «تعديل مطلوب», which keeps the ticket alive.
 */
enum DesignTicketStatus: string
{
    /** Written down and sent. Nobody has picked it up. Where every ticket begins. */
    case New = 'new';

    /** A named designer has taken it and is working. */
    case InProgress = 'in_progress';

    /** A version is with the employee who asked, waiting on their verdict. */
    case UnderReview = 'under_review';

    /** Turned back with what has to change. Still the same ticket, and still the designer's. */
    case ChangesRequested = 'changes_requested';

    /** A version was approved, the artwork is on the customer's account, and this is closed. */
    case Completed = 'completed';

    /** Called off, with a reason. Not a verdict on any design. */
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::New => 'جديد',
            self::InProgress => 'قيد التصميم',
            self::UnderReview => 'بانتظار المراجعة',
            self::ChangesRequested => 'تعديل مطلوب',
            self::Completed => 'مكتمل',
            self::Cancelled => 'ملغى',
        };
    }

    /**
     * Every state this one may legally become, whichever action does the writing.
     *
     * Read by the actions to refuse a move, and published on the resource so the app can grey a
     * button rather than discover the refusal by making a request.
     *
     * **{@see New} is unreachable from everywhere**, which is the same rule `ChangeShortageStatus`
     * spells out: "لم تبدأ متابعته بعد" stops being true the moment somebody starts, and a status
     * that could be un-started would make «جديد: ١٢» on the board a number that goes up for
     * reasons nobody did.
     *
     * @return list<self>
     */
    public function allowedNext(): array
    {
        return match ($this) {
            self::New => [self::InProgress, self::Cancelled],
            // Straight to UnderReview on a submission. A designer who has taken the job does not
            // announce that they are about to start.
            self::InProgress => [self::UnderReview, self::Cancelled],
            self::UnderReview => [self::ChangesRequested, self::Completed, self::Cancelled],
            // Back to InProgress when the designer picks the revision up, or straight to
            // UnderReview when they simply upload the next version — which is the usual path.
            self::ChangesRequested => [self::InProgress, self::UnderReview, self::Cancelled],
            self::Completed => [],
            self::Cancelled => [],
        };
    }

    public function canMoveTo(self $target): bool
    {
        return in_array($target, $this->allowedNext(), true);
    }

    /**
     * Finished — nothing more will be drawn, reviewed or said.
     *
     * Both endings, and they are the only two. Unlike a shortage's «غير متوفر», neither of these
     * reads like an ending without being one.
     */
    public function isClosed(): bool
    {
        return $this === self::Completed || $this === self::Cancelled;
    }

    /** Whether this ticket still counts as work outstanding. The inverse, never a second list. */
    public function isOpen(): bool
    {
        return ! $this->isClosed();
    }

    /**
     * Whether a designer may upload a version from here.
     *
     * Two states, and «تعديل مطلوب» is the one that matters: a revision must not need a second
     * acceptance, or every round trip would cost an extra tap for nothing. See
     * DESIGN-TICKETS-DESIGN.md §7.
     */
    public function acceptsSubmissions(): bool
    {
        return $this === self::InProgress || $this === self::ChangesRequested;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $status) => $status->value, self::cases());
    }
}
