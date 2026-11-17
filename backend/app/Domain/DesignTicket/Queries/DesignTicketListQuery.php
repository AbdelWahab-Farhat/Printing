<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Queries;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Queries\Concerns\FiltersDesignTickets;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The design tickets list: the last status change first, narrowed to what the reader may see.
 *
 * **By `status_changed_at`, not by `id`.** A ticket opened a month ago that has just come back
 * for review is the one somebody needs to see now, and ordering by creation buried it. The column
 * moves on status changes only — not on a message, a pay edit or the conversation being opened —
 * so the list says where the work stands rather than where the chatter is. Unread messages have
 * their own badge.
 *
 * **Still not open work first.** That order is tempting, and it is the same argument
 * `ShortageListQuery` settled: «مكتمل» rows become the majority within a month of shipping, and a
 * list that buried them would make the historical record — the thing the brief's «سجل التذكرة»
 * section asks to keep — reachable only by filtering. A ticket that closed sinks on its own as
 * newer moves land above it, and the status chip row above the list answers the rest.
 *
 * The eager loads are the resource's whole appetite. `customer` is *not* among them, deliberately:
 * the card renders `customer_name` off the snapshot, so a designer's list costs no read of a table
 * they hold no grant on.
 */
final class DesignTicketListQuery
{
    use FiltersDesignTickets;

    /**
     * @return LengthAwarePaginator<int, DesignTicket>
     */
    public function __invoke(DesignTicketFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return $this->applyFilters(DesignTicket::query(), $filters)
            ->with(['customer:id,code', 'requester', 'designer', 'acceptedBy', 'latestVersion'])
            ->withCount('versions')
            ->orderByDesc('status_changed_at')
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
