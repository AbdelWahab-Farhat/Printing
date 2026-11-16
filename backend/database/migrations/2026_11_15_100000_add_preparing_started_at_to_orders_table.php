<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * When the warehouse last started gathering an order's goods — «تجهيز للطباعة».
 *
 * Read against `ready_to_print_at` to answer «كم يأخذ التجهيز؟», the question the status was
 * added for. Denormalised on the same terms as the milestone columns beside it.
 *
 * **Nothing is backfilled.** Orders taken before the status existed never passed through it, and
 * null is the truthful answer for them.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // In the order the milestones happen, so the row reads like the journey.
            $table->timestamp('preparing_started_at')->nullable()->after('placed_at');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('preparing_started_at');
        });
    }
};
