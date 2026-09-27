<?php

declare(strict_types=1);

namespace App\Domain\Audit\Models;

use App\Domain\Audit\AuditField;
use App\Domain\Audit\AuditHiddenAttributes;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\Models\Activity;

/**
 * One entry in the audit trail.
 *
 * Extends the package's model so the Audit context owns the queries it needs, and so the rest
 * of the application never imports a vendor class to read its own history. `activitylog.php`
 * points `activity_model` here, which is what makes every logged event arrive as this class.
 *
 * **Append-only.** Nothing in the application updates or deletes a row: an audit trail that can
 * be edited is not one. There is deliberately no `Auditable` here either — logging the log
 * would recurse.
 *
 * @property-read Model|null $causer
 * @property-read Model|null $subject
 */
class ActivityLog extends Activity
{
    /**
     * Narrows the trail to one record's story: itself and anything it owns.
     *
     * Grouped by morph alias so the whole set costs one `where subject_type = ? and subject_id
     * in (?)` per kind, which the (subject_type, subject_id) index serves directly. The outer
     * closure keeps the OR set from escaping and swallowing the event and date filters.
     *
     * @param  Builder<$this>  $query
     * @param  array<string, list<int|string>>  $subjects  morph alias => ids
     * @return Builder<$this>
     */
    public function scopeForSubjects(Builder $query, array $subjects): Builder
    {
        return $query->where(function (Builder $query) use ($subjects): void {
            foreach ($subjects as $type => $ids) {
                if ($ids === []) {
                    continue;
                }

                $query->orWhere(function (Builder $query) use ($type, $ids): void {
                    $query->where('subject_type', $type)->whereIn('subject_id', $ids);
                });
            }

            // An empty set must match nothing. Without this an all-empty $subjects would leave
            // the closure with no conditions at all, and the trail of one record would quietly
            // become the trail of everything.
            $query->orWhereRaw('1 = 0');
        });
    }

    /**
     * Leaves out every update whose changes are all noise — see {@see AuditHiddenAttributes}.
     *
     * A ticket opened by a customer rewrites «قرأها العميل في» and nothing else. The screen hides
     * that line, and an entry with its only line hidden is an empty card that says «عُدّلت
     * التذكرة» forty times a day. The row stays in the table; it is just not listed, and not
     * counted under the chips either, since those share this query.
     *
     * Only updates. A creation or a deletion is an event however little of it is shown, and so
     * is an update that carried a storage column: a file replaced is still a file replaced.
     *
     * @param  Builder<$this>  $query
     * @return Builder<$this>
     */
    public function scopeWithoutNoiseOnlyUpdates(Builder $query): Builder
    {
        $noise = AuditHiddenAttributes::noise();
        $bindings = $noise['everywhere'];

        // A key is worth showing if it is noise neither everywhere nor on this row's subject.
        $visible = 'k.key not in ('.self::placeholders($noise['everywhere']).')';

        foreach ($noise['per_subject'] as $alias => $columns) {
            $visible .= ' and not (activity_log.subject_type = ? and k.key in ('.self::placeholders($columns).'))';
            $bindings = [...$bindings, $alias, ...$columns];
        }

        // Wrapped in coalesce because `event` is nullable, and a null there would make the whole
        // `not (…)` null — which a WHERE reads as false, silently dropping the row.
        return $query->whereRaw(
            "not coalesce((
                activity_log.event = 'updated'
                and json_typeof(activity_log.attribute_changes->'attributes') = 'object'
                and not exists (
                    select 1 from json_object_keys(activity_log.attribute_changes->'attributes') as k(key)
                    where {$visible}
                )
            ), false)",
            $bindings,
        );
    }

    /**
     * Only the entries that say something about one column of one kind of record.
     *
     * An update matches when the column moved. A creation or a deletion matches only when the
     * column held a value: a line created without a price has nothing to say about prices, and
     * listing it under «سعر الوحدة» would be every creation in the trail.
     *
     * One rule covers all three, because `->>` reads a JSON null as SQL null: an update always
     * has the column non-null on at least one side — null to null is not a change.
     *
     * @param  Builder<$this>  $query
     * @return Builder<$this>
     */
    public function scopeTouchingField(Builder $query, AuditField $field): Builder
    {
        return $query
            ->where('activity_log.subject_type', $field->subject->value)
            ->where(function (Builder $query) use ($field): void {
                $query->whereRaw("(activity_log.attribute_changes->'attributes'->>?) is not null", [$field->column])
                    ->orWhereRaw("(activity_log.attribute_changes->'old'->>?) is not null", [$field->column]);
            });
    }

    /**
     * @param  list<string>  $values
     */
    private static function placeholders(array $values): string
    {
        return $values === [] ? 'null' : implode(', ', array_fill(0, count($values), '?'));
    }
}
