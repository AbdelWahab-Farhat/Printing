<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * What an expense out of a dollar account came to in dinars — USD-ACCOUNTS.md §٨.
 *
 * **«المصاريف» adds dinars.** A movement's `amount` is in its account's currency, so an expense of
 * $100 out of a dollar drawer is `100` — added to the dinar ones it would read as 100 dinars. This
 * is its dinar figure at the rate it was recorded at, kept on the movement so the tab and its
 * total read one column, and a reversal carries it back.
 *
 * Null on every movement of a dinar account, and on a dollar one that is not an expense.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_movements', function ($table) {
            $table->decimal('dinar_amount', 14, 2)->nullable()->after('amount');
        });

        DB::statement('ALTER TABLE treasury_movements ADD CONSTRAINT treasury_movements_dinar_amount_positive
            CHECK (dinar_amount IS NULL OR dinar_amount > 0)');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE treasury_movements DROP CONSTRAINT treasury_movements_dinar_amount_positive');

        Schema::table('treasury_movements', function ($table) {
            $table->dropColumn('dinar_amount');
        });
    }
};
