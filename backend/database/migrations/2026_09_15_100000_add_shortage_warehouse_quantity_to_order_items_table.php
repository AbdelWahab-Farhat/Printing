<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * What is missing from this line **in the unit the warehouse counts it in**.
 *
 * **`shortage_quantity` beside it is a fact about the invoice, and cannot be anything else.** It
 * is subtracted from `quantity` in `OrderItem::billableQuantity()` and the remainder is
 * multiplied by `unit_price` — a price *per selling unit*. Put kilograms in that column on a line
 * sold by the piece and a customer short thirty bags of three hundred is credited 19.38 د.ل
 * instead of 46.50.
 *
 * **But the chase is a warehouse errand, and «النواقص» is denominated for the person doing it.**
 * Whoever goes out to cover this buys what the shelf is counted in, the warehouse receives it in
 * that unit, and the cost layer it opens is priced per that unit. A section that told them «٣٠
 * قطعة» when the pile is weighed would be asking them to do a conversion nobody can do — see
 * below.
 *
 * So the line carries both, and each answers to its own reader: this one is what
 * `SyncShortagesFromOrder` mirrors into `shortages.required_quantity`, and `shortage_quantity` is
 * what the invoice is cut from.
 *
 * **Null means «the two units agree», exactly as on `warehouse_quantity` three columns away.**
 * That column made the same decision about the same question and a second convention for it would
 * cost more than it bought. It also means every row written before today reads correctly: those
 * lines are stocked in the unit they were sold in, so one number always answered both.
 *
 * **And it is never derived.** There is no قطعة→كجم factor in the catalogue and deliberately none
 * — bags weighed together have no per-bag weight, which is why `DeductOrderStock` refuses to
 * multiply one out and why `warehouse_quantity` is read off a scale. The pair is stated once, by
 * the person declaring the shortage, and the ratio between the two is then held constant as
 * supplies come in. See `SetOrderShortages`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_items', function (Blueprint $table): void {
            // Three places and a decimal, like every quantity in this schema — `12.500` on a
            // scale, and never a float, because this is summed into a warehouse balance.
            $table->decimal('shortage_warehouse_quantity', 12, 3)
                ->nullable()
                ->after('shortage_quantity');
        });

        // An arrival of nothing is not a shortage. Null stays legal — that is «the same number as
        // `shortage_quantity`», not «none» — and zero is refused for the reason the column beside
        // it is nullable rather than defaulted: «لا ينقص شيء» is said by clearing both, not by
        // writing a zero that every report then has to tell apart from a real measurement.
        DB::statement(<<<'SQL'
            ALTER TABLE order_items
                ADD CONSTRAINT order_items_shortage_warehouse_quantity_positive CHECK (
                    shortage_warehouse_quantity IS NULL OR shortage_warehouse_quantity > 0
                )
        SQL);

        /*
         * **A weight for a shortage that does not exist is a measurement of nothing.**
         *
         * The two are written together by one action — `SetOrderShortages` is the only writer of
         * either — so a row carrying a warehouse figure with no `shortage_quantity` behind it is
         * a bug rather than a state: most likely a line credited back to the invoice while the
         * chase was left standing, which would leave «النواقص» pursuing goods the customer has
         * already been billed for.
         */
        DB::statement(<<<'SQL'
            ALTER TABLE order_items
                ADD CONSTRAINT order_items_shortage_warehouse_quantity_needs_a_shortage CHECK (
                    shortage_warehouse_quantity IS NULL OR shortage_quantity IS NOT NULL
                )
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE order_items DROP CONSTRAINT IF EXISTS order_items_shortage_warehouse_quantity_needs_a_shortage');
        DB::statement('ALTER TABLE order_items DROP CONSTRAINT IF EXISTS order_items_shortage_warehouse_quantity_positive');

        Schema::table('order_items', function (Blueprint $table): void {
            $table->dropColumn('shortage_warehouse_quantity');
        });
    }
};
