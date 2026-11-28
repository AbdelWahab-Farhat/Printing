<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * A delivery cost an administrator typed by hand.
 *
 * `delivery_cost` is derived, and re-derived by five actions (an edit, a status move, a change
 * of payer, settling and unsettling), so a hand-typed figure written straight into it would be
 * overwritten by the next of them. The override lives beside it instead, and
 * RecalculateDeliveryCost prefers it whenever we pay the courier. Null means "derive it", which
 * is every existing row, so nothing needs backfilling.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('delivery_cost_override', 12, 2)->nullable()->after('delivery_cost');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('delivery_cost_override');
        });
    }
};
