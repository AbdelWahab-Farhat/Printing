<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * The ledger follows the balance it explains.
 *
 * `warehouse_stocks` is now keyed on the shelf rather than the size, and a movement that named a
 * size could no longer be reconciled against the row it moved — the balance-equals-ledger
 * invariant `StockLedgerTest` holds would have nothing to sum over.
 *
 * Everything else about this table is untouched: quantity still positive, direction still carried
 * by which end is filled, the three CHECK constraints still stand, and nothing updates or deletes
 * a row. Only what moved is renamed.
 *
 * The `(product_variant_id, created_at)` index goes with the column and comes back as
 * `(stock_item_id, created_at)` — one shelf's history is still the question this table is asked.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('stock_movements', function (Blueprint $table) {
            $table->dropIndex(['product_variant_id', 'created_at']);
            $table->dropConstrainedForeignId('product_variant_id');

            $table->foreignId('stock_item_id')->after('id')
                ->constrained('stock_items')->cascadeOnDelete();

            $table->index(['stock_item_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::table('stock_movements', function (Blueprint $table) {
            $table->dropIndex(['stock_item_id', 'created_at']);
            $table->dropConstrainedForeignId('stock_item_id');

            $table->foreignId('product_variant_id')->after('id')
                ->constrained('product_variants')->cascadeOnDelete();

            $table->index(['product_variant_id', 'created_at']);
        });
    }
};
