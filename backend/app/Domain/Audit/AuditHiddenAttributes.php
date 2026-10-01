<?php

declare(strict_types=1);

namespace App\Domain\Audit;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Audit\Models\ActivityLog;
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
     * Columns the application keeps up to date on its own, hidden from every kind of record.
     *
     * `sort_order` moves when somebody drags a row up a list, and on a catalogue it moves on
     * every row below it too. Nobody opens a product's history to find out it went from 7 to 8.
     *
     * @var list<string>
     */
    private const NOISE_EVERYWHERE = ['sort_order'];

    /**
     * The same idea per kind of record, keyed by {@see AuditSubject::value}.
     *
     * **Unlike the storage columns, these are named one by one.** They are not a family with a
     * shared suffix; each is here because its row moves it without anybody deciding anything:
     *
     * - read markers a ticket rewrites every time somebody opens it;
     * - totals and costs recomputed from rows that have their own entries — «المدفوع» rises
     *   because a payment was recorded, and the payment is already in the same trail;
     * - pointers and watermarks the code uses to find its place (`through_*_id`,
     *   `source_sequence`, `stock_movement_id`), which read as a bare number to anybody else.
     *
     * An update that touched nothing *but* these is dropped from the list altogether — see
     * {@see ActivityLog::scopeWithoutNoiseOnlyUpdates()} — because a card whose every line is hidden is an empty card.
     *
     * @var array<string, list<string>>
     */
    private const NOISE = [
        'user' => ['email_verified_at'],
        'product' => ['slug'],
        'nawris_parcel' => ['remote_status_code'],
        'order' => ['paid_amount', 'total_cogs', 'stock_deducted_at', 'delete_returned_stock_at'],
        'order_item' => [
            'material_cost',
            'material_cost_actual',
            'labor_cost',
            'overhead_cost',
            'cogs',
            'fulfillment_stock_movement_id',
        ],
        'stock_batch' => ['quantity_remaining', 'stock_movement_id'],
        'stock_batch_consumption' => ['stock_movement_id'],
        'stock_arrival_item' => ['stock_movement_id'],
        'shortage_supply' => ['stock_movement_id'],
        'investor_wallet_entry' => ['source_sequence'],
        'investment_cash_entry' => ['source_sequence'],
        'investment_period' => [
            'through_consumption_id',
            'through_movement_id',
            'through_wallet_entry_id',
            'through_cash_entry_id',
        ],
        'support_ticket' => [
            'customer_read_at',
            'staff_read_at',
            'customer_read_message_id',
            'staff_read_message_id',
            'last_message_at',
        ],
        'ticket_message' => ['client_token'],
        'treasury_operation' => ['client_token'],
        'vendor_payment' => ['client_token'],
        'notification' => ['dedupe_key'],
    ];

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
     *
     * Without a subject only the storage columns and {@see NOISE_EVERYWHERE} are known — the
     * per-record noise needs to know which record it is on.
     */
    public static function hides(string $column, ?AuditSubject $subject = null): bool
    {
        if (self::isNoise($column, $subject)) {
            return true;
        }

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
    public static function strip(mixed $values, ?AuditSubject $subject = null): mixed
    {
        if (! is_array($values)) {
            return $values;
        }

        return array_filter(
            $values,
            fn (mixed $column): bool => ! self::hides((string) $column, $subject),
            ARRAY_FILTER_USE_KEY,
        );
    }

    /**
     * Whether the application moves this column by itself on this kind of record.
     */
    public static function isNoise(string $column, ?AuditSubject $subject = null): bool
    {
        return in_array($column, self::NOISE_EVERYWHERE, true)
            || ($subject !== null && in_array($column, self::NOISE[$subject->value] ?? [], true));
    }

    /**
     * Every noise column, as the list query needs them to drop the updates made of nothing else.
     *
     * The storage columns are deliberately not part of it: a file replaced is an event worth a
     * card even with its lines hidden — the stored sentence says what happened.
     *
     * @return array{everywhere: list<string>, per_subject: array<string, list<string>>}
     */
    public static function noise(): array
    {
        return ['everywhere' => self::NOISE_EVERYWHERE, 'per_subject' => self::NOISE];
    }
}
