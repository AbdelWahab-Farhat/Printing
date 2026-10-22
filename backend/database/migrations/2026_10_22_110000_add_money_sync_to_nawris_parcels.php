<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Whether Nawris actually heard about the last change to a parcel's money.
 *
 * **A refused edit used to vanish.** A payment taken while the parcel was out sent an edit-order;
 * Nawris refused it; the refusal was swallowed without a log line, and the courier went on to
 * collect the old amount — a customer paying twice, with nothing anywhere to say so. These columns
 * keep the refusal until it is put right: by a later edit they accept, or by someone at Nawris
 * correcting the amount by hand, which their webhook then reports.
 *
 * `door_amount` is their latest figure for the door from *any* event, where `collected_amount`
 * is only ever written on delivery — it is what the red line on the order quotes, and what a hand
 * correction is recognised by.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('nawris_parcels', function (Blueprint $table) {
            $table->timestamp('sync_failed_at')->nullable()->after('shipment_on_sender');

            // Their own words, as their response gave them.
            $table->string('sync_error', 500)->nullable()->after('sync_failed_at');

            $table->decimal('door_amount', 12, 2)->nullable()->after('sync_error');

            // The «لم تُبلَّغ نورس» filter on the parcels list.
            $table->index('sync_failed_at');
        });
    }

    public function down(): void
    {
        Schema::table('nawris_parcels', function (Blueprint $table) {
            $table->dropIndex(['sync_failed_at']);
            $table->dropColumn(['sync_failed_at', 'sync_error', 'door_amount']);
        });
    }
};
