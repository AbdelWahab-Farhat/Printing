<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The currency of a vendor payment, credit or opening debt — USD-ACCOUNTS.md §٦.
 *
 * **It is the debt's currency and the drawer's at once**: a dollar debt is paid from a dollar
 * account, in dollars, so one column says all three, and `amount` is in it. That the order and
 * the account agree with it is the Action's to check — a CHECK cannot read another row.
 *
 * Nothing existing changes: every payment so far is dinars.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('vendor_payments', function ($table) {
            $table->char('currency', 3)->default('LYD')->after('amount');
        });

        DB::statement("ALTER TABLE vendor_payments ADD CONSTRAINT vendor_payments_currency_check
            CHECK (currency IN ('LYD', 'USD'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE vendor_payments DROP CONSTRAINT vendor_payments_currency_check');

        Schema::table('vendor_payments', function ($table) {
            $table->dropColumn('currency');
        });
    }
};
