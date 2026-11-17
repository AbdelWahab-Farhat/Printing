<?php

declare(strict_types=1);

use App\Domain\DesignTicket\Models\DesignTicket;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * When a design ticket last changed status — what the list is ordered by.
 *
 * **Not `updated_at`.** That one also moves when somebody edits the pay or the title, and every
 * time somebody opens the conversation, because the read markers live on this row. A list ordered
 * by it would reshuffle for reasons that have nothing to do with where the work stands.
 *
 * **The backfill takes the latest of four dates**, because none of them is enough on its own:
 *
 * - `created_at` — a ticket nobody has touched;
 * - `accepted_at` — acceptance writes the status with a query-builder update, so it never
 *   reaches the audit log as a status change;
 * - `completed_at` — the approval;
 * - the newest audit entry whose changed attributes include `status` — submissions, reviews,
 *   withdrawals, cancellations, and a release back to the pool.
 *
 * Every status move happens at or after the event behind each of these, so the greatest of them
 * is the last move. Soft-deleted rows are filled too: the column is NOT NULL for all of them.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->timestamp('status_changed_at')->nullable()->after('status');
        });

        DB::statement(<<<'SQL'
            UPDATE design_tickets AS t
            SET status_changed_at = COALESCE(
                GREATEST(
                    t.created_at,
                    t.accepted_at,
                    t.completed_at,
                    (
                        SELECT MAX(a.created_at)
                        FROM activity_log AS a
                        WHERE a.subject_type = ?
                            AND a.subject_id = t.id
                            AND json_typeof(a.attribute_changes->'attributes') = 'object'
                            AND (a.attribute_changes->'attributes'->>'status') IS NOT NULL
                    )
                ),
                NOW()
            )
        SQL, [(new DesignTicket)->getMorphClass()]);

        Schema::table('design_tickets', function (Blueprint $table) {
            $table->timestamp('status_changed_at')->nullable(false)->change();

            // The list's order: last status change first, the id breaking ties.
            $table->index(['status_changed_at', 'id']);
        });
    }

    public function down(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->dropIndex(['status_changed_at', 'id']);
            $table->dropColumn('status_changed_at');
        });
    }
};
