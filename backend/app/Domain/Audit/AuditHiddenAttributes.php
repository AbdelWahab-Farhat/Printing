<?php

declare(strict_types=1);

namespace App\Domain\Audit;

use App\Support\Media\StoredFile;

/**
 * The columns a history screen leaves out.
 *
 * A row that stores a file carries two kinds of column, and only one of them is history.
 * «رقم النسخة», «الحالة», «رفعها» are what happened. `disk`, `path`, `mime_type`, `checksum`,
 * `width_px` are how the file is kept — and nobody in a printing shop in Tripoli has ever needed
 * to know that a JPEG lives on `local` at `design-tickets/1/34d4c062-….jpg` with a sha256 of
 * `cc1ff8c…`. The card drew nine such lines above the four worth reading, at the same weight, and
 * the noise is what the reader had to get past to find the verdict.
 *
 * **Nothing stops being logged.** {@see AuditAttributeLabels} argues that a trail which records
 * what *somebody decided to record* is not a trail; that argument still holds, so the columns are
 * written exactly as before and this file only narrows what the API draws. Which also means the
 * fix is retroactive — a row written last month is cleaned up by the same read as one written
 * this morning — and reversible by deleting a line, with no migration and no lost bytes. The
 * checksum of a file that turns out to be the wrong one is still in `activity_log` to be found.
 *
 * **The rule is a suffix, not a list of columns**, for the reason {@see AuditValueLabels} reads a
 * foreign key off the model's own relation rather than a registry: `receipt_checksum` on a
 * shortage supply and `image_path` on a stock item group are these same columns with a prefix,
 * and the next model that stores a file will name them the same way — {@see StoredFile} is the
 * one thing that writes them. A hand-kept list would be right until the morning somebody adds a
 * table and doesn't think to come here, which is precisely the morning nobody would notice.
 */
final class AuditHiddenAttributes
{
    /**
     * The columns {@see StoredFile} produces, minus the one a person chose.
     *
     * `original_filename` is deliberately absent: «شعار-الشركة.pdf» is a name somebody typed,
     * not a storage detail, and on an attachment it is the row's only handle — it is what
     * `DesignTicketFile::displayName()` falls back to for anything that is not a numbered
     * version. Hiding it would leave an entry that names no file at all.
     *
     * @var list<string>
     */
    private const STORAGE = [
        'disk',
        'path',
        'mime_type',
        'size_bytes',
        'checksum',
        'width_px',
        'height_px',
    ];

    /**
     * Whether this column describes where the bytes live rather than what happened.
     *
     * Matched whole or after a prefix — `checksum`, `receipt_checksum`. `_px` is the pixel
     * count of a stored image and never a measurement of the thing being printed: a bag's size
     * is `width_cm`, which is domain data and stays on the screen.
     */
    public static function hides(string $column): bool
    {
        foreach (self::STORAGE as $plumbing) {
            if ($column === $plumbing || str_ends_with($column, '_'.$plumbing)) {
                return true;
            }
        }

        return false;
    }

    /**
     * One half of a change with the plumbing taken out.
     *
     * Anything that is not an array comes back untouched, and that is the same latitude
     * {@see AuditValueLabels::forChanges()} takes with these halves: they come straight out of a
     * JSON column, `null` is how an entry says a half never existed — a creation has no `old` —
     * and a history screen is the last place that should 500 over its own oldest rows.
     */
    public static function strip(mixed $values): mixed
    {
        if (! is_array($values)) {
            return $values;
        }

        return array_filter(
            $values,
            fn (mixed $column): bool => ! self::hides((string) $column),
            ARRAY_FILTER_USE_KEY,
        );
    }
}
