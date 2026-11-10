<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The rate a dollar purchase order was funded at — USD-ACCOUNTS.md §٥, the owner's decision of
 * 2026-11-10.
 *
 * Funding is decided before the goods arrive, so its dinar figures — what the fund pays, what
 * caps the partners' money, the company's stake — are worked out at a rate asked on the funding
 * screen («سعر النظام» unless changed). The funded goods keep that rate when they arrive; the
 * company's own goods take the arrival rate. A difference between the two writes nothing — the
 * order's screen says it.
 *
 * Set by the first funding of the order; a second one on its other lines uses the same rate.
 *
 * **`purchase_order_items.funded_cost`** is what a funded line of a dollar order cost in dinars at
 * that rate — the figure the fund paid, or the partners' money was held against. Written when the
 * line is funded, and read wherever a funded line's dinar cost is needed: the layer it opens at,
 * and «بضاعة مشتراة لم تصل». Null on every other line, whose `final_total_cost` already is dinars.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_orders', function ($table) {
            $table->decimal('funding_rate', 12, 4)->nullable()->after('arrival_rate');
        });

        DB::statement("ALTER TABLE purchase_orders ADD CONSTRAINT purchase_orders_funding_rate_check
            CHECK (funding_rate IS NULL OR (currency = 'USD' AND funding_rate > 0))");

        Schema::table('purchase_order_items', function ($table) {
            $table->decimal('funded_cost', 14, 2)->nullable()->after('final_total_cost');
        });
    }

    public function down(): void
    {
        Schema::table('purchase_order_items', function ($table) {
            $table->dropColumn('funded_cost');
        });

        DB::statement('ALTER TABLE purchase_orders DROP CONSTRAINT purchase_orders_funding_rate_check');

        Schema::table('purchase_orders', function ($table) {
            $table->dropColumn('funding_rate');
        });
    }
};
