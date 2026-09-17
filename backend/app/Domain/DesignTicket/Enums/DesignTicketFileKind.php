<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Enums;

/**
 * Which half of the conversation a file on a ticket belongs to.
 *
 * The column that lets `design_ticket_files` be one table instead of two. The ticket screen draws
 * an attachment strip and a version timeline from one fetch, so splitting the table would buy a
 * distinction this enum buys with a string — at the cost of a second model, a second resource and
 * a second set of routes. The database enforces the difference with a CHECK constraint: only a
 * submission carries a version number and a verdict.
 */
enum DesignTicketFileKind: string
{
    /** What the employee sent with the request — the logo, a photo of a similar design. */
    case Brief = 'brief';

    /** What the designer drew. Numbered, and judged. */
    case Submission = 'submission';

    public function label(): string
    {
        return match ($this) {
            self::Brief => 'مرفق',
            self::Submission => 'تصميم',
        };
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $kind) => $kind->value, self::cases());
    }
}
