<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Which shelves a pool owns — and the one rule the whole feature rests on.
 *
 * > **Each investable stock item belongs to at most one pool.**
 *
 * That is the unique index below, and it is in the database rather than in an action because of
 * what a cost layer is: `stock_batches.investor_deal_id` holds **one** container id, and the
 * lookup that answers «which pool financed this shelf?» answers with the first row it finds. A
 * shelf claimed by two pools would not raise an error — it would quietly send one set of
 * investors' goods into the other set's accounts, and the ledger would balance while being
 * wrong. A guard in PHP is only as reliable as every future writer remembering to take the lock.
 *
 * **A table of its own rather than reusing `investor_deal_items`.** That index cannot be
 * expressed there: `kind` lives on the parent row, so «unique per stock item, but only among
 * pools» is a cross-table condition, and PostgreSQL will not index one. A second small table buys
 * a guarantee where the alternative buys a convention.
 *
 * `investor_deal_items` keeps its own job — the expected quantity and price a legacy deal was
 * written against. This table holds no figures at all: a pool's holdings are read from the cost
 * layers, as everything about stock in this schema is.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_pool_items', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investor_deal_id')->constrained('investor_deals')->cascadeOnDelete();
            $table->foreignId('stock_item_id')->constrained('stock_items')->restrictOnDelete();

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index('investor_deal_id');
        });

        // The rule, stated where it cannot be bypassed. Partial on `deleted_at` so a shelf
        // detached from one pool can later join another — the soft-deleted row is history, not a
        // claim.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_pool_items_one_pool_per_stock_item
            ON investment_pool_items (stock_item_id)
            WHERE deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_pool_items');
    }
};
