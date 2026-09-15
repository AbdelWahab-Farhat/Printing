<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Queries;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Queries\Concerns\FiltersDesignTickets;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The design tickets list: newest first, narrowed to what the reader may see.
 *
 * **Newest first rather than open work first.** The other order is tempting, and it is the same
 * argument `ShortageListQuery` settled: «مكتمل» rows become the majority within a month of
 * shipping, and a list that buried them would make the historical record — the thing the brief's
 * «سجل التذكرة» section asks to keep — reachable only by filtering. Newest first with a status
 * chip row above it answers both.
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
            ->with(['requester', 'designer', 'acceptedBy'])
            ->withCount('versions')
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
