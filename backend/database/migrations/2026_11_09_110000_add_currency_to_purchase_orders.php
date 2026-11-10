<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Dollar purchase orders and the vendor's dollar «علينا» — USD-ACCOUNTS.md §٤.
 *
 * **Every amount on an order is in its currency**: line costs, extra costs, the total and what
 * the vendor is owed. The currency is picked when the order is raised and never changes, so a
 * dollar order's debt sits on a second payable for the vendor, in dollars — one payable per
 * vendor *per currency*, which is what the widened unique index says.
 *
 * Nothing existing changes: every order is `LYD` by default, and every vendor payable already is.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_orders', function ($table) {
            $table->char('currency', 3)->default('LYD')->after('status');
        });

        DB::statement("ALTER TABLE purchase_orders ADD CONSTRAINT purchase_orders_currency_check
            CHECK (currency IN ('LYD', 'USD'))");

        // A vendor's payable may be dollars too; the system's own payables stay dinars.
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_dollar_shape');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_dollar_shape CHECK (
            currency = 'LYD'
            OR (kind IN ('cash', 'bank') AND NOT is_default AND pickup_city_id IS NULL)
            OR (kind = 'payable' AND vendor_id IS NOT NULL)
        )");

        DB::statement('DROP INDEX treasury_accounts_one_per_vendor');
        DB::statement('CREATE UNIQUE INDEX treasury_accounts_one_per_vendor
            ON treasury_accounts (vendor_id, currency) WHERE vendor_id IS NOT NULL AND deleted_at IS NULL');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX treasury_accounts_one_per_vendor');
        DB::statement('CREATE UNIQUE INDEX treasury_accounts_one_per_vendor
            ON treasury_accounts (vendor_id) WHERE vendor_id IS NOT NULL AND deleted_at IS NULL');

        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_dollar_shape');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_dollar_shape
            CHECK (currency = 'LYD' OR (kind IN ('cash', 'bank') AND NOT is_default AND pickup_city_id IS NULL))");

        DB::statement('ALTER TABLE purchase_orders DROP CONSTRAINT purchase_orders_currency_check');

        Schema::table('purchase_orders', function ($table) {
            $table->dropColumn('currency');
        });
    }
};
