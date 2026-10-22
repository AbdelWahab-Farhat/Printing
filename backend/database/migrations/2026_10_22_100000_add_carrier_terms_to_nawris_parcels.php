<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Nawris's own fee on a parcel, and who pays it.
 *
 * **Reverses NAWRIS-INTEGRATION.md §5.2's "derived, never stored".** The fee was to be read as
 * `collected_amount − amount_to_collect` at delivery, which only holds while nobody edits the
 * amount on their side — and they do. The fee is fixed when the parcel is created, so the parcel's
 * first event is the only place it can be read from; see `ReadNawrisParcelTerms`.
 *
 * Both columns are a reading of the stored webhook history, refreshed on every event, so neither
 * can drift from what Nawris actually sent. Nullable: a parcel with no usable event has neither.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('nawris_parcels', function (Blueprint $table) {
            // What Nawris adds on top of our amount when the customer pays it. Null until known.
            $table->decimal('carrier_fee', 12, 2)->nullable()->after('collected_amount');

            // **Their webhook numbering, not their API's**: 1 the customer pays the fee, 2 we do.
            // We always send 0 at dispatch and it comes back as 1. See `NawrisParcelTerms`.
            $table->smallInteger('shipment_on_sender')->nullable()->after('carrier_fee');
        });
    }

    public function down(): void
    {
        Schema::table('nawris_parcels', function (Blueprint $table) {
            $table->dropColumn(['carrier_fee', 'shipment_on_sender']);
        });
    }
};
