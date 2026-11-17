<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Moves the tickets that are addressed to a designer but not yet accepted from «جديد» to the new
 * «مُسنَد» status.
 *
 * Before this status existed, assigning a ticket left it at «جديد», so these rows are exactly the
 * ones `AssignDesignTicket` would now have written as `assigned`.
 *
 * `status_changed_at` is left alone: the moment of the assignment is not recorded anywhere this
 * could read it from, and stamping every row with the deploy time would reshuffle the list.
 *
 * Soft-deleted rows are included, so a restored ticket is consistent too.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::table('design_tickets')
            ->where('status', 'new')
            ->whereNotNull('assigned_designer_id')
            ->whereNull('accepted_at')
            ->update(['status' => 'assigned']);
    }

    public function down(): void
    {
        DB::table('design_tickets')
            ->where('status', 'assigned')
            ->update(['status' => 'new']);
    }
};
