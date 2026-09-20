<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * A pool's roster has no frozen percentage, because a pool has no frozen percentages.
 *
 * `investor_deal_shares.share_percent` is the whole of ownership on a صفقة: agreed when the lorry
 * was funded, frozen when the deal opened, and read by every split for the rest of its life. On a
 * صندوق it is **nothing at all** — ownership is recomputed from capital at every period close and
 * written to `investment_period_shares`, and a number sitting on the roster could only ever be a
 * second answer to a question that already has one.
 *
 * So the column becomes nullable, and a pool's roster rows carry null. **Not zero and not an even
 * split**: both are figures, and a figure invites a screen to draw it and a reader to believe it.
 * Null says «this is not where the answer lives», which is the truth.
 *
 * The existing row-level `CHECK (share_percent > 0 AND share_percent <= 100)` needs no change — a
 * null compares to null in SQL and the constraint passes, which is exactly the behaviour wanted
 * here. That a deal's row must *not* be null stays where it already is, in `SyncDealShares`,
 * along with the «must sum to 100» rule that a row-level check could never see anyway.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE investor_deal_shares ALTER COLUMN share_percent DROP NOT NULL');
    }

    public function down(): void
    {
        // A pool roster's nulls would refuse the NOT NULL, so they are given the only value that
        // cannot be mistaken for a real stake before the column is tightened again.
        DB::statement(<<<'SQL'
            UPDATE investor_deal_shares SET share_percent = 100
            WHERE share_percent IS NULL
        SQL);

        DB::statement('ALTER TABLE investor_deal_shares ALTER COLUMN share_percent SET NOT NULL');
    }
};
