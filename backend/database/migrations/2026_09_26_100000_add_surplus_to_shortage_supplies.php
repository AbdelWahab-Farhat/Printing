<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * What a purchase brought in beyond what the shortage was missing.
 *
 * **A supply used to be capped at the remainder, and the cap was the wrong answer to a real
 * thing.** Somebody short twenty kilos buys a thirty-kilo sack, because that is the size the shop
 * sells, and the sack lands on the shelf whatever the ledger says. Refusing the entry pushed the
 * extra ten through a second screen as a second purchase of the same sack.
 *
 * So a supply may now carry more than is missing, and this column is the part that did not go
 * toward the shortage. `quantity` stays what physically arrived — the number the stock movement
 * posted and the number `amount` was paid for — and `quantity − surplus_quantity` is what the
 * shortage counts as supplied. See `Shortage::liveSuppliedQuantity()` and SHORTAGES-DESIGN §٧٫١.
 *
 * The two caches on `shortages` are the same figures summed over the live ledger, written by
 * `RecalculateShortageTotals` beside `supplied_quantity` and `total_paid` — «منها للمخزن» on the
 * screen, and what the extra's share of the money was.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shortage_supplies', function (Blueprint $table) {
            // Zero, not null, on every row that fitted — which is every row written before this.
            $table->decimal('surplus_quantity', 12, 3)->default(0)->after('quantity');
        });

        // The part left over can be none of the arrival, or some of it — never all of it, since a
        // supply that covered nothing was refused at a shortage already «مكتمل» — and never more.
        DB::statement(<<<'SQL'
            ALTER TABLE shortage_supplies
                ADD CONSTRAINT shortage_supplies_surplus_within_quantity CHECK (
                    surplus_quantity >= 0 AND surplus_quantity < quantity
                )
        SQL);

        Schema::table('shortages', function (Blueprint $table) {
            $table->decimal('surplus_quantity', 12, 3)->default(0)->after('supplied_quantity');
            $table->decimal('surplus_value', 14, 2)->default(0)->after('total_paid');
        });

        DB::statement(<<<'SQL'
            ALTER TABLE shortages
                ADD CONSTRAINT shortages_surplus_not_negative CHECK (
                    surplus_quantity >= 0 AND surplus_value >= 0 AND surplus_value <= total_paid
                )
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE shortages DROP CONSTRAINT IF EXISTS shortages_surplus_not_negative');
        DB::statement('ALTER TABLE shortage_supplies DROP CONSTRAINT IF EXISTS shortage_supplies_surplus_within_quantity');

        Schema::table('shortages', function (Blueprint $table) {
            $table->dropColumn(['surplus_quantity', 'surplus_value']);
        });

        Schema::table('shortage_supplies', function (Blueprint $table) {
            $table->dropColumn('surplus_quantity');
        });
    }
};
