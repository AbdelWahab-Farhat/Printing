<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Dollar accounts and «صرف عملة» — USD-ACCOUNTS.md §٣.
 *
 * **The currency column was there from the first day**, locked to dinars by a CHECK that said
 * so; this widens it rather than adding anything to `treasury_accounts`. A dollar account is a
 * cash box or a bank, and never the default of its kind: a default is where a payment nobody
 * placed falls, and every such payment is dinars.
 *
 * **«صرف عملة» is the one operation with two amounts.** `amount` stays what left, in the
 * currency of the account it left; `counter_amount` is what arrived, in the other's; `rate` is
 * dinars per dollar. That the two accounts differ in currency is the Action's to check — a CHECK
 * cannot read another row.
 *
 * Nothing existing changes: every account is `LYD` already, and no operation is an exchange.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_currency_check');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_currency_check
            CHECK (currency IN ('LYD', 'USD'))");

        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_dollar_shape
            CHECK (currency = 'LYD' OR (kind IN ('cash', 'bank') AND NOT is_default AND pickup_city_id IS NULL))");

        Schema::table('treasury_operations', function ($table) {
            // «صرف عملة» alone: what arrived, in the receiving account's currency.
            $table->decimal('counter_amount', 14, 2)->nullable()->after('amount');
            // Dinars per dollar, as typed or as worked out from the two amounts.
            $table->decimal('rate', 12, 4)->nullable()->after('counter_amount');
        });

        DB::statement('ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_exchange_figures
            CHECK ((counter_amount IS NULL OR counter_amount > 0) AND (rate IS NULL OR rate > 0))');

        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_shape');
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type = 'opening' AND (from_account_id IS NULL) <> (to_account_id IS NULL))
            OR (type = 'deposit' AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type IN ('expense', 'wallet_expense') AND from_account_id IS NOT NULL AND to_account_id IS NULL
                AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'exchange' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id AND counter_amount IS NOT NULL AND rate IS NOT NULL)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");

        Schema::table('treasury_settings', function ($table) {
            // «سعر النظام» — dinars per dollar, what a dollar is worth in the totals. Null until
            // the owner writes one; the totals then show dollars beside dinars, unconverted.
            $table->decimal('usd_rate', 12, 4)->nullable()->after('online_fee_payer');
        });

        DB::statement('ALTER TABLE treasury_settings ADD CONSTRAINT treasury_settings_usd_rate_positive
            CHECK (usd_rate IS NULL OR usd_rate > 0)');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE treasury_settings DROP CONSTRAINT treasury_settings_usd_rate_positive');

        Schema::table('treasury_settings', function ($table) {
            $table->dropColumn('usd_rate');
        });

        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_shape');
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type = 'opening' AND (from_account_id IS NULL) <> (to_account_id IS NULL))
            OR (type = 'deposit' AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type IN ('expense', 'wallet_expense') AND from_account_id IS NOT NULL AND to_account_id IS NULL
                AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");

        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_exchange_figures');

        Schema::table('treasury_operations', function ($table) {
            $table->dropColumn(['counter_amount', 'rate']);
        });

        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_dollar_shape');
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_currency_check');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_currency_check
            CHECK (currency = 'LYD')");
    }
};
