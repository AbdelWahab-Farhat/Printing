<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Where an approved design came from, on the design itself.
 *
 * The brief asks that each design on a customer's account keep its file, its name, the date it
 * was approved, the ticket it came from, the designer, and any notes. Four of those six were
 * already there — the file, `label`, `notes`, and `created_at`. These three are the rest.
 *
 * **Purely additive, and every existing row stays NULL.** NULL here means "uploaded by hand",
 * which is exactly what those rows are: a design put straight into the library by an employee,
 * with no ticket and no designer behind it. That reading is why these are not backfilled and why
 * they will never be NOT NULL — the hand-upload path is not going away, and forcing a ticket onto
 * it would mean opening a ticket to record artwork the customer just sent over WhatsApp.
 *
 * **No existing endpoint changes behaviour.** `CustomerDesignResource` gains three fields that
 * are read and never written; `StoreCustomerDesignRequest` does not accept them, and neither
 * column is fillable. They are set by `PromoteApprovedDesign` and by nothing else.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customer_designs', function (Blueprint $table) {
            /*
             * The ticket whose approval produced this row.
             *
             * `nullOnDelete` rather than a cascade, and the asymmetry is deliberate: deleting a
             * ticket must never take the customer's artwork with it. The design outlives the
             * conversation that produced it — that is the whole premise of keeping it on the
             * customer's account rather than inside one request.
             */
            $table->foreignId('design_ticket_id')->nullable()->after('notes')
                ->constrained('design_tickets')->nullOnDelete();

            // Who drew it. Copied here rather than read through the ticket, because it is shown
            // on the design card and the ticket may be gone — see above.
            $table->foreignId('designer_user_id')->nullable()->after('design_ticket_id')
                ->constrained('users')->nullOnDelete();

            /*
             * When it was signed off — **not `created_at`**, which is when the row was written.
             *
             * They are within a transaction of each other today, and a separate column still
             * earns its place: `created_at` is a fact about this table, and the day a design is
             * promoted from an old ticket, or re-linked after a correction, the approval date is
             * the one the customer's screen has to keep showing.
             */
            $table->timestamp('approved_at')->nullable()->after('designer_user_id');
        });
    }

    public function down(): void
    {
        Schema::table('customer_designs', function (Blueprint $table) {
            $table->dropConstrainedForeignId('design_ticket_id');
            $table->dropConstrainedForeignId('designer_user_id');
            $table->dropColumn('approved_at');
        });
    }
};
