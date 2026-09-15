<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Queries;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Queries\Concerns\FiltersDesignTickets;

/**
 * How many tickets stand in each status — «جديد ٣ | قيد التصميم ٥ | بانتظار المراجعة ٢ …».
 *
 * **The status filter itself is dropped, and every other filter is kept.** A chip row exists to
 * say what else there is; counting only the status already selected would make every chip but one
 * read zero, and the row would answer a question nobody asked. Every *other* filter stays, because
 * «قيد التصميم ٥» under a customer filter has to mean five of that customer's.
 *
 * **Including the visibility narrowing**, which is exactly why the two queries share a trait: a
 * count that saw a colleague's tickets while the list below it did not would tell a designer how
 * much work exists that they may not open.
 *
 * Every status is present in the result, zeros included, so the app draws a stable row rather than
 * one whose chips appear and disappear as work moves.
 */
final class DesignTicketStatusCountsQuery
{
    use FiltersDesignTickets;

    /**
     * @return array<string, int>
     */
    public function __invoke(DesignTicketFilters $filters): array
    {
        $counts = $this->applyFilters(DesignTicket::query(), $filters->withoutStatuses())
            ->selectRaw('status, count(*) as aggregate')
            ->groupBy('status')
            ->pluck('aggregate', 'status');

        $result = [];

        foreach (DesignTicketStatus::cases() as $status) {
            $result[$status->value] = (int) ($counts[$status->value] ?? 0);
        }

        return $result;
    }
}
