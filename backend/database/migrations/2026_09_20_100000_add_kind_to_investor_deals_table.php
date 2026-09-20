<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The same table now holds two kinds of container: the صفقة that was, and the صندوق that is.
 *
 * **Why one table and not two.** Every row that points at a container points here —
 * `stock_batches.investor_deal_id`, `investor_wallet_entries.investor_deal_id`,
 * `investor_deal_expenses`, `investor_deal_supplies`, `investor_deal_shares`. A second table for
 * pools would mean a second nullable foreign key on each of them and a `CHECK` on every one
 * saying «exactly one of these two is set» — five places for a future writer to forget. A
 * discriminator column is one place, and the database can still say what is true of each kind.
 *
 * **`kind` defaults to `deal`, so the deploy changes nothing.** Every existing row is a legacy
 * deal and goes on behaving exactly as it did: its screens render, its ledger reads, its audit
 * trail stands. Nothing about this migration is destructive and nothing is rewritten — the
 * overriding constraint on the whole feature is that no existing deal is lost.
 *
 * **`name` comes back, for pools only.** It was dropped on 2026-09-05 because a deal born from a
 * purchase order had nothing to name — it was «that lorry», and the code said it better. A pool
 * is «ورق» or «حبر»: a thing the business talks about by name for years. The `CHECK` below makes
 * the column required of a pool and forbidden of nothing else, so the two kinds cannot drift into
 * each other by accident.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_deals', function (Blueprint $table) {
            // 10 is enough for both words and leaves room; the CHECK below is what actually
            // constrains it, the way `status` is constrained in this schema.
            $table->string('kind', 10)->default('deal');

            // Nullable in the column and required by the CHECK, rather than NOT NULL with a
            // meaningless default: a legacy deal genuinely has no name, and writing '' into
            // seventy rows to satisfy a constraint would invent data to describe history.
            $table->string('name', 120)->nullable();
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investor_deals
            ADD CONSTRAINT investor_deals_kind_values
            CHECK (kind IN ('deal', 'pool'))
        SQL);

        // A pool is always named; a legacy deal never is. Said here rather than in an action
        // because it is a fact about the row, and an action can be bypassed by a future writer
        // — which is the same reasoning `investor_wallet_entries_shape` already applies.
        DB::statement(<<<'SQL'
            ALTER TABLE investor_deals
            ADD CONSTRAINT investor_deals_pool_is_named
            CHECK (kind <> 'pool' OR name IS NOT NULL)
        SQL);

        // Two pools called «ورق» would be indistinguishable on every screen that lists them, and
        // the name is what staff say out loud — the same reason `investors.code` is unique.
        // Scoped to pools so the seventy unnamed legacy rows are untouched by it.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investor_deals_pool_name_unique
            ON investor_deals (name)
            WHERE kind = 'pool' AND deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            CREATE INDEX investor_deals_kind_index ON investor_deals (kind)
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS investor_deals_pool_name_unique');
        DB::statement('DROP INDEX IF EXISTS investor_deals_kind_index');
        DB::statement('ALTER TABLE investor_deals DROP CONSTRAINT IF EXISTS investor_deals_pool_is_named');
        DB::statement('ALTER TABLE investor_deals DROP CONSTRAINT IF EXISTS investor_deals_kind_values');

        Schema::table('investor_deals', function (Blueprint $table) {
            $table->dropColumn(['kind', 'name']);
        });
    }
};
