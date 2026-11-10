<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The arrival rate of a dollar purchase order, and the currency of each of its costs —
 * USD-ACCOUNTS.md §٥ and §٧.
 *
 * **`arrival_rate`** is dinars per dollar, asked on the receive screen. It prices the stock that
 * arrived in dinars once; nothing paid afterwards changes it. Empty until the order is received,
 * emptied when the receipt is taken back, and never set on a dinar order.
 *
 * **A cost's `currency`** is the order's when it is on the vendor's bill, and the drawer's when it
 * was paid from one — shipping from China in dollars, customs in Libya in dinars. Every cost so
 * far is on a dinar order, so the default is right for all of them.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_orders', function ($table) {
            $table->decimal('arrival_rate', 12, 4)->nullable()->after('currency');
        });

        DB::statement("ALTER TABLE purchase_orders ADD CONSTRAINT purchase_orders_arrival_rate_check
            CHECK (arrival_rate IS NULL OR (currency = 'USD' AND arrival_rate > 0))");

        Schema::table('purchase_order_additional_costs', function ($table) {
            $table->char('currency', 3)->default('LYD')->after('amount');
        });

        DB::statement("ALTER TABLE purchase_order_additional_costs ADD CONSTRAINT purchase_order_additional_costs_currency_check
            CHECK (currency IN ('LYD', 'USD'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE purchase_order_additional_costs DROP CONSTRAINT purchase_order_additional_costs_currency_check');

        Schema::table('purchase_order_additional_costs', function ($table) {
            $table->dropColumn('currency');
        });

        DB::statement('ALTER TABLE purchase_orders DROP CONSTRAINT purchase_orders_arrival_rate_check');

        Schema::table('purchase_orders', function ($table) {
            $table->dropColumn('arrival_rate');
        });
    }
};
