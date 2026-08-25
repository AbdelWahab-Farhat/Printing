<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Gives every size that already exists a shelf of its own, so a database with stock in it can
 * cross into the stock-item world without losing any of it.
 *
 * **The four re-key migrations after this one refused to run on a populated database, and said
 * so on purpose:** «there is no correct automatic answer to "which of these two balances was the
 * real pile" — adding them is a guess, keeping one loses stock». That reasoning is right, and it
 * is about *merging*. This does not merge anything.
 *
 * **One shelf per (product name, size), which is exactly the shape the data already had.** Every
 * balance, movement, batch and purchase line keeps pointing at the same physical thing it always
 * pointed at, under a new key. Two products that share a pile in real life end up with two
 * shelves here — and that is the honest outcome, because the system was never told they were one
 * pile. Consolidating them is the deliberate act the groups are for: name both products the same
 * material and every size files itself, once a person has decided it is true.
 *
 * **The unit comes from `products.stock_unit`**, which is still standing at this point — it is
 * dropped two migrations later. So a shelf inherits precisely the unit its stock was counted in,
 * and nothing is re-interpreted.
 *
 * **A no-op on an empty database**, which is every test run: `RefreshDatabase` migrates a schema
 * with no rows, so there is nothing to select and the four NOT NULL columns downstream still land
 * as NOT NULL from the first moment. That is why this could not have been caught by the suite —
 * only by running `php artisan migrate` against a database somebody had actually used.
 */
return new class extends Migration
{
    public function up(): void
    {
        // `nextval` per row so the code and the id agree — a shelf whose id is 7 always reads S7,
        // the same guarantee `AllocateStockItemIdentifier` gives at runtime. The same move the
        // group backfill makes; see `add_stock_item_group_id_to_stock_items_table`.
        //
        // DISTINCT ON collapses the (name, size) duplicates the unique index would refuse
        // anyway: two variants of one product at one size, or two products that happen to share
        // a name. `COALESCE(…, 0)` mirrors `stock_items_name_size_unique` exactly, so what this
        // considers "the same shelf" and what the index considers the same shelf cannot differ.
        DB::statement(
            "WITH shelves AS (
                 SELECT DISTINCT ON (p.name, COALESCE(v.width_cm, 0), COALESCE(v.height_cm, 0))
                        p.name        AS name,
                        v.width_cm    AS width_cm,
                        v.height_cm   AS height_cm,
                        p.stock_unit  AS unit
                 FROM product_variants v
                 JOIN products p ON p.id = v.product_id
                 WHERE v.stock_item_id IS NULL
                 ORDER BY p.name, COALESCE(v.width_cm, 0), COALESCE(v.height_cm, 0), v.id
             ),
             numbered AS (
                 SELECT name, width_cm, height_cm, unit,
                        nextval(pg_get_serial_sequence('stock_items', 'id')) AS id
                 FROM shelves
             )
             INSERT INTO stock_items
                 (id, code, name, width_cm, height_cm, unit, is_active, sort_order,
                  created_at, updated_at)
             SELECT id, 'S' || id, name, width_cm, height_cm, unit, true, 0, now(), now()
             FROM numbered"
        );

        // Matched on the same three expressions the shelves were keyed by, so a size can only
        // land on the row that was minted for it.
        DB::statement(
            'UPDATE product_variants v
             SET stock_item_id = s.id
             FROM stock_items s, products p
             WHERE p.id = v.product_id
               AND v.stock_item_id IS NULL
               AND s.name = p.name
               AND COALESCE(s.width_cm, 0)  = COALESCE(v.width_cm, 0)
               AND COALESCE(s.height_cm, 0) = COALESCE(v.height_cm, 0)
               AND s.deleted_at IS NULL'
        );
    }

    /**
     * Releases the sizes, and leaves the shelves standing.
     *
     * Deleting them would be a guess in the other direction: by the time anyone rolls back, a
     * shelf minted here may have taken arrivals, been renamed, or been filed under a group, and
     * nothing distinguishes it from one somebody created by hand. The way back to the old world
     * is `add_stock_item_id_to_product_variants_table::down()`, which drops the column, and
     * `create_stock_items_table::down()`, which drops the table with everything in it.
     */
    public function down(): void
    {
        DB::statement('UPDATE product_variants SET stock_item_id = NULL');
    }
};
