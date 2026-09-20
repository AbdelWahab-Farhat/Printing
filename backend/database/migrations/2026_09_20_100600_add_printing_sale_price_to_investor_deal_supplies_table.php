<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * سعر السادة moves from the container to the purchase.
 *
 * **Why it has to move.** On a صفقة the price sat on the deal and was frozen for its whole life,
 * and that was right: a deal *was* one lorry, so one lorry had one agreed price. A صندوق outlives
 * every lorry it buys — 32/kg this shipment, 35 the next — and a single column on the pool would
 * either be a stale figure or a term that silently re-cut goods already on the shelf.
 *
 * So the price is agreed where the purchase is: on the row that already says «this order's line for
 * this shelf is financed by this container», one per lorry per shelf.
 *
 * **Nothing about the layers changes.** `stock_batches.printing_sale_price` already exists and is
 * still what every draw reads — `ReceivePurchaseOrder` stamps it at the gate, and from then on the
 * layer is the truth. All that moves is where the answer is read from one moment earlier.
 *
 * **Null keeps its meaning exactly**: «nobody said», which puts those goods on the other road —
 * their financier rides the sale itself and is paid from the delivered order's profit.
 *
 * `investor_deals.printing_sale_price` stays where it is and goes on meaning what it meant for
 * every legacy deal. A pool leaves it null and answers from here.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_deal_supplies', function (Blueprint $table) {
            // Three places, matching `stock_batches.unit_cost` and the column this feeds —
            // the price the press pays must be the same number on both sides of the stamp.
            $table->decimal('printing_sale_price', 12, 3)->nullable();
        });

        // The same floor `investor_deals.printing_sale_price` carries. A price of nothing is not a
        // price; «nobody said» is expressed by null, and the two must not be confusable.
        DB::statement(<<<'SQL'
            ALTER TABLE investor_deal_supplies
            ADD CONSTRAINT investor_deal_supplies_printing_sale_price_positive
            CHECK (printing_sale_price IS NULL OR printing_sale_price > 0)
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE investor_deal_supplies DROP CONSTRAINT IF EXISTS investor_deal_supplies_printing_sale_price_positive');

        Schema::table('investor_deal_supplies', function (Blueprint $table) {
            $table->dropColumn('printing_sale_price');
        });
    }
};
