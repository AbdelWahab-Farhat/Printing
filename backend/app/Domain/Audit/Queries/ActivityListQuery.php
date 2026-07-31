<?php

declare(strict_types=1);

namespace App\Domain\Audit\Queries;

use App\Domain\Audit\Models\ActivityLog;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

/**
 * Reading the audit trail — either one record's history, or the whole feed.
 *
 * One class for both, because they differ by a single `where`: the same filters, ordering and
 * eager loading apply to a product's history and to everything that happened yesterday.
 */
final class ActivityListQuery
{
    /**
     * @param  array<string, list<int|string>>|null  $subjects  morph alias => ids; null for the
     *                                                          unrestricted feed
     * @return LengthAwarePaginator<int, ActivityLog>
     */
    public function __invoke(?array $subjects, ActivityFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ActivityLog::query()
            // The causer is rendered on every row. Strict mode turns a forgotten eager load
            // into an exception rather than one query per entry, but only where a causer
            // exists — plenty of rows are the system's own work and have none.
            ->with('causer')
            ->when($subjects !== null, fn (Builder $q) => $q->forSubjects($subjects ?? []))
            ->when($filters->event !== null, fn (Builder $q) => $q->where('event', $filters->event?->value))
            ->when($filters->subjectType !== null, fn (Builder $q) => $q->where('subject_type', $filters->subjectType?->value))
            ->when($filters->causerId !== null, fn (Builder $q) => $q->where('causer_id', $filters->causerId))
            ->when($filters->from !== null, fn (Builder $q) => $q->where('created_at', '>=', $filters->from))
            ->when($filters->to !== null, fn (Builder $q) => $q->where('created_at', '<=', $filters->to))
            // Newest first, and by id rather than by created_at: several entries written inside
            // one transaction share a timestamp to the second, and ordering by it alone would
            // shuffle them between pages. The id is the only total order there is.
            ->orderByDesc('id')
            ->paginate($perPage);
    }
}
