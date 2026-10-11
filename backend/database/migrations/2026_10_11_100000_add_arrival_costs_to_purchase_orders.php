<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «مصاريف عند وصول البضاعة» — Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md.
 *
 * - **`purchase_order_additional_costs.stock_arrival_id`** — the receipt a cost was added on.
 *   Null is a cost planned on the order, which is every row written before today.
 * - **`.treasury_account_id`** — who was paid. Null is the vendor's bill, as every existing cost
 *   was; a drawer is money paid out now; a manual payable is money owed to somebody else.
 * - **`purchase_order_items.arrival_additional_cost` / `landed_unit_cost`** — the line's share
 *   of the arrival costs, and the unit cost its layer actually opened at. Null until received.
 * - **`purchase_orders.vendor_amount`** — what the vendor is owed: the total less what was paid to
 *   somebody else. Backfilled equal to `total_amount`, since every existing cost was on the
 *   vendor's bill.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_order_additional_costs', function (Blueprint $table) {
            $table->foreignId('stock_arrival_id')->nullable()->after('purchase_order_id')
                ->constrained('stock_arrivals')->nullOnDelete();
            $table->foreignId('treasury_account_id')->nullable()->after('amount')
                ->constrained('treasury_accounts');
            $table->foreignId('recorded_by')->nullable()->after('treasury_account_id')
                ->constrained('users')->nullOnDelete();
        });

        Schema::table('purchase_order_items', function (Blueprint $table) {
            $table->decimal('arrival_additional_cost', 14, 2)->nullable()->after('final_total_cost');
            $table->decimal('landed_unit_cost', 12, 3)->nullable()->after('arrival_additional_cost');
        });

        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->decimal('vendor_amount', 14, 2)->nullable()->after('total_additional_cost');
        });

        DB::statement('ALTER TABLE purchase_order_items
            ADD CONSTRAINT purchase_order_items_arrival_additional_cost_not_negative
            CHECK (arrival_additional_cost IS NULL OR arrival_additional_cost >= 0)');
        DB::statement('ALTER TABLE purchase_order_items
            ADD CONSTRAINT purchase_order_items_landed_unit_cost_not_negative
            CHECK (landed_unit_cost IS NULL OR landed_unit_cost >= 0)');
        DB::statement('ALTER TABLE purchase_orders
            ADD CONSTRAINT purchase_orders_vendor_amount_not_negative
            CHECK (vendor_amount IS NULL OR vendor_amount >= 0)');

        DB::statement('UPDATE purchase_orders SET vendor_amount = total_amount');
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE purchase_orders DROP CONSTRAINT purchase_orders_vendor_amount_not_negative');
        DB::statement('ALTER TABLE purchase_order_items DROP CONSTRAINT purchase_order_items_landed_unit_cost_not_negative');
        DB::statement('ALTER TABLE purchase_order_items DROP CONSTRAINT purchase_order_items_arrival_additional_cost_not_negative');

        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->dropColumn('vendor_amount');
        });

        Schema::table('purchase_order_items', function (Blueprint $table) {
            $table->dropColumn(['arrival_additional_cost', 'landed_unit_cost']);
        });

        Schema::table('purchase_order_additional_costs', function (Blueprint $table) {
            $table->dropConstrainedForeignId('recorded_by');
            $table->dropConstrainedForeignId('treasury_account_id');
            $table->dropConstrainedForeignId('stock_arrival_id');
        });
    }
};
