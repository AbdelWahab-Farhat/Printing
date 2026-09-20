<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * One question per **line and pool**, not per line.
 *
 * ## The case the narrower index silences
 *
 * A shelf may move between pools: `SyncPoolItems` lets a pool drop a material and another
 * claim it, and **the cost layers do not move with it** — they are what the
 * old pool's investors paid for, and they keep that pool for ever.
 *
 * So a shelf that moved from صندوق «أ» to صندوق «ب» carries layers of both at once, and a single
 * order line draws FIFO straight through the boundary:
 *
 * ```
 * line #430 takes 300 sheets  →  180 from أ's old layer
 *                                120 from ب's new layer
 * ```
 *
 * Cancel that order after it has been printed and **both pools have ruined paper** on the shelf.
 * Under `UNIQUE (order_item_id)` only the first could ever be asked about: the second insert would
 * be refused by the index, the question would never be raised, and صندوق «أ» would close its period
 * over goods it no longer has — its `stock_at_cost` still counting them, its deployable cash
 * overstated by exactly their cost, and the next lorry bought with money that was never there.
 *
 * Which is the failure the whole feature exists to prevent, surviving inside it.
 *
 * ## Why not forbid the move instead
 *
 * Because the move is legitimate and the design says so: re-pointing a shelf decides where the
 * **next** lorry's money comes from and moves nothing that is already bought. Forbidding it to keep
 * an index simple would trade a real business need for an implementation detail.
 *
 * The pair is still narrow enough to do its job — a cancellation walked twice, or a listener fired
 * twice, still finds the row standing and writes nothing.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('DROP INDEX IF EXISTS investment_returned_goods_questions_one_per_line');

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_returned_goods_questions_one_per_line_and_pool
            ON investment_returned_goods_questions (order_item_id, investor_deal_id)
            WHERE deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS investment_returned_goods_questions_one_per_line_and_pool');

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_returned_goods_questions_one_per_line
            ON investment_returned_goods_questions (order_item_id)
            WHERE deleted_at IS NULL
        SQL);
    }
};
