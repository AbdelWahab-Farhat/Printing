<?php

use App\Domain\Inventory\Actions\ApplyStockChange;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * A balance is of a *shelf*, not of a size.
 *
 * `product_variant_id` gave every product its own private pile of what was physically one pile:
 * كيس شحن سادة 25*35 and كيس شحن مطبوع 25*35 each had a row, and an order drawing on both weighed
 * itself against two of them. The key becomes `stock_item_id` and the two rows become one.
 *
 * **No data is migrated, deliberately.** There is no correct automatic answer to "which of these
 * two balances was the real pile" — adding them is a guess, keeping one loses stock, and deciding
 * is a business call, not a silent side effect of a schema change (RULES.md §8). On a table that
 * already holds rows the NOT NULL column below therefore fails, loudly, which is the honest
 * outcome; `migrate:fresh` is the intended path while this is still local.
 *
 * The unique index is the reason the whole context is safe: {@see ApplyStockChange} locks exactly
 * one row per (warehouse, item) and increments it, and a duplicate would let two movements update
 * different rows and lose one of them. It is rebuilt under the new key and renamed with it —
 * PostgreSQL keeps an index's original name through a column change, and a name still saying
 * "variant" would be a lie the next reader has to disprove.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('DROP INDEX IF EXISTS warehouse_stocks_one_row_per_variant_per_warehouse');

        Schema::table('warehouse_stocks', function (Blueprint $table) {
            $table->dropIndex(['warehouse_id', 'product_variant_id']);
            $table->dropConstrainedForeignId('product_variant_id');

            $table->foreignId('stock_item_id')->after('warehouse_id')
                ->constrained('stock_items')->cascadeOnDelete();

            // Serves the per-warehouse listing, which is the only way this table is read.
            $table->index(['warehouse_id', 'stock_item_id']);
        });

        DB::statement(
            'CREATE UNIQUE INDEX warehouse_stocks_one_row_per_item_per_warehouse
             ON warehouse_stocks (warehouse_id, stock_item_id) WHERE deleted_at IS NULL'
        );
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS warehouse_stocks_one_row_per_item_per_warehouse');

        Schema::table('warehouse_stocks', function (Blueprint $table) {
            $table->dropIndex(['warehouse_id', 'stock_item_id']);
            $table->dropConstrainedForeignId('stock_item_id');

            $table->foreignId('product_variant_id')->after('warehouse_id')
                ->constrained('product_variants')->cascadeOnDelete();

            $table->index(['warehouse_id', 'product_variant_id']);
        });

        DB::statement(
            'CREATE UNIQUE INDEX warehouse_stocks_one_row_per_variant_per_warehouse
             ON warehouse_stocks (warehouse_id, product_variant_id) WHERE deleted_at IS NULL'
        );
    }
};
