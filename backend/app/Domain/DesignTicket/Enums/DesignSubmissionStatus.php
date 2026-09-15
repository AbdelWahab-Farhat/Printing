<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Enums;

use App\Domain\DesignTicket\Actions\ReviewDesignVersion;
use App\Domain\Order\Enums\OrderDesignStatus;

/**
 * Where one *version* of a ticket's artwork stands with the employee who asked for it.
 *
 * Deliberately close to {@see OrderDesignStatus} and deliberately not the same enum. That one
 * records a conversation with the **customer** about which version to print, and its third case
 * is `Rejected` — an ending for that version. This one records a conversation with a
 * **colleague**, and its third case is {@see ChangesRequested}, which is not an ending at all: it
 * is an instruction, it carries the words, and the ticket stays open on the designer's desk.
 * Sharing one enum would have meant a value named «مرفوض» appearing on a screen where nothing
 * was rejected.
 *
 * Like its neighbour, **a version is judged once** — see {@see ReviewDesignVersion}. Changing a
 * verdict afterwards would erase the reason the next version exists, and that trail is the entire
 * value of keeping versions at all.
 */
enum DesignSubmissionStatus: string
{
    /** Sent up for review, waiting on the employee. Where every version starts. */
    case Proposed = 'proposed';

    /** Signed off. The one that goes onto the customer's account. */
    case Approved = 'approved';

    /** Turned back, with `review_note` saying what has to change. */
    case ChangesRequested = 'changes_requested';

    public function label(): string
    {
        return match ($this) {
            self::Proposed => 'بانتظار المراجعة',
            self::Approved => 'معتمد',
            self::ChangesRequested => 'تعديل مطلوب',
        };
    }

    /** Decided one way or the other — no longer waiting on the reviewer. */
    public function isReviewed(): bool
    {
        return $this !== self::Proposed;
    }

    /**
     * Whether a note must accompany this verdict.
     *
     * The whole value of tracking versions is knowing *why* one was replaced; a change request
     * with no words turns the history into a count. The argument
     * `DesignRejectionRequiresReason` already makes, applied to the verdict that is an
     * instruction rather than a refusal — which needs it more, not less.
     */
    public function requiresNote(): bool
    {
        return $this === self::ChangesRequested;
    }

    /**
     * The two a reviewer may choose.
     *
     * {@see Proposed} is not among them: it is where a version arrives, never somewhere a person
     * sends one.
     *
     * @return list<self>
     */
    public static function verdicts(): array
    {
        return [self::Approved, self::ChangesRequested];
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $status) => $status->value, self::cases());
    }
}
