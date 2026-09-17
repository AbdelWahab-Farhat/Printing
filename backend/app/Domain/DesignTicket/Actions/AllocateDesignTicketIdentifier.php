<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\DTOs\DesignTicketIdentifier;
use Illuminate\Support\Facades\DB;

/**
 * Reserves the next ticket id and builds its code: D1, D2, D3 …
 *
 * The same mechanism customers, products, orders and shortages use — `nextval` on the table's own
 * sequence, pulled *before* the insert, so the row carries a final unique code rather than a
 * placeholder two concurrent inserts could briefly share.
 *
 * **With a letter, like a shortage.** A ticket is almost always named next to something else —
 * «تذكرة ٤ على طلبية ١٢٠٤» — and a bare number in that sentence is exactly the ambiguity the
 * letter removes. D is for تصميم, which is also what the screen is called.
 *
 * A rolled-back transaction leaves its number unused, so codes may skip one. They are
 * identifiers, not a count — the trade this schema has now accepted four times.
 */
final class AllocateDesignTicketIdentifier
{
    public function __invoke(): DesignTicketIdentifier
    {
        $id = (int) DB::scalar("select nextval(pg_get_serial_sequence('design_tickets', 'id'))");

        return new DesignTicketIdentifier($id, 'D'.$id);
    }
}
