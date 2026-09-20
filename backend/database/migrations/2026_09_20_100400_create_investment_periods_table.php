<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الفترة المحاسبية — what repeats, now that the صفقة does not.
 *
 * A pool never closes. Its **periods** do, and each one is a line in its history: what it sold,
 * what it cost, what it earned, and how that was divided. One row per (pool, period), created when
 * the period opens and completed when it closes.
 *
 * **Why this table lands with the capital slice rather than with the close.** The grace window has
 * nothing to anchor to without it: «capital added in the first three days joins *this* period, and
 * after that it waits for the *next* one» is a sentence about two periods, and neither exists until
 * something says when they begin. The close itself — net profit, distribution, the loss write-down
 * — is a later slice; this is only the calendar it will run on.
 *
 * ## The two halves of this table
 *
 * Everything up to `closed_by` is written when the period **opens** and is the calendar.
 * Everything after it is written once when it **closes** and is a snapshot — deliberately frozen,
 * and deliberately not a running balance.
 *
 * > **This is not a breach of «الرصيد لا يُخزَّن».** A stored balance is a claim about *now* that
 * > can drift from the rows beneath it. These are a claim about a moment that has passed and can
 * > never move again: the money was divided on these figures and paid out on them, so recomputing
 * > them later from today's data would be asking a different question. It is the same split
 * > `manufacturing_cost_rates` makes when it snapshots the rate that was actually applied.
 *
 * ## What the database guarantees
 *
 * **At most one open period per pool** — the partial unique index below. Two would make «the
 * current period» a question with two answers, and every capital request would have to pick one.
 *
 * **Non-overlap is enforced in PHP under the pool's row lock**, not by an `EXCLUDE` constraint:
 * that would need `btree_gist`, and no migration in this repository installs an extension. The
 * action creates each period starting the day after the last one ends, so a gap or an overlap
 * cannot arise from the only road in.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_periods', function (Blueprint $table) {
            $table->id();

            // The pool. Named `investor_deal_id` because that is the table it points at — pools
            // and legacy deals share it — and a second name for one foreign key would be a
            // riddle for whoever writes the next join.
            $table->foreignId('investor_deal_id')->constrained('investor_deals')->cascadeOnDelete();

            $table->date('starts_on');
            $table->date('ends_on');

            $table->string('status', 20)->default('open');

            $table->timestamp('closed_at')->nullable();
            $table->foreignId('closed_by')->nullable()->constrained('users')->nullOnDelete();

            // ── the snapshot, written once at the close ──────────────────────────────────────

            // Cash and stock at both ends, so a period states its own opening position rather
            // than leaving a reader to reconstruct it from the period before.
            $table->decimal('opening_cash', 16, 2)->nullable();
            $table->decimal('closing_cash', 16, 2)->nullable();
            $table->decimal('opening_stock_cost', 16, 2)->nullable();
            $table->decimal('closing_stock_cost', 16, 2)->nullable();

            // The four lines of the net-profit equation, each kept so the arithmetic can be read
            // back rather than trusted. Signed: a dear lorry makes a negative margin.
            $table->decimal('realized_margin', 16, 2)->nullable();
            $table->decimal('deductible_expenses', 16, 2)->nullable();
            $table->decimal('damage_cost', 16, 2)->nullable();
            $table->decimal('shortage_cost', 16, 2)->nullable();
            $table->decimal('net_profit', 16, 2)->nullable();

            // **The terms this period was actually divided on.** Read from the settings and the
            // ledger at the moment of closing and frozen here, so changing a setting next year
            // cannot make a closed period's arithmetic unreproducible.
            $table->decimal('investor_share_percent_applied', 5, 2)->nullable();
            $table->decimal('investor_capital_weight_applied', 9, 4)->nullable();
            $table->decimal('total_pool_capital', 16, 2)->nullable();
            $table->decimal('total_investor_capital', 16, 2)->nullable();

            $table->text('notes')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['investor_deal_id', 'starts_on']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_status_values
            CHECK (status IN ('open', 'closed'))
        SQL);

        // A period that ends before it begins is not a period.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_dates_ordered
            CHECK (ends_on >= starts_on)
        SQL);

        // «الفترة الحالية» has one answer per pool, or the grace window has nothing to measure
        // against and a capital request cannot say which period it joins.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_periods_one_open_per_pool
            ON investment_periods (investor_deal_id)
            WHERE status = 'open' AND deleted_at IS NULL
        SQL);

        // A closed period carries its whole snapshot, and an open one carries none of it. Stated
        // as one constraint rather than eleven nullable columns and a hope: a close that wrote
        // ten of the eleven would otherwise leave a period that looks settled and is not.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_closed_is_complete CHECK (
                (status = 'open'
                    AND closed_at IS NULL AND net_profit IS NULL)
                OR (status = 'closed'
                    AND closed_at IS NOT NULL
                    AND opening_cash IS NOT NULL AND closing_cash IS NOT NULL
                    AND opening_stock_cost IS NOT NULL AND closing_stock_cost IS NOT NULL
                    AND realized_margin IS NOT NULL AND deductible_expenses IS NOT NULL
                    AND damage_cost IS NOT NULL AND shortage_cost IS NOT NULL
                    AND net_profit IS NOT NULL
                    AND investor_share_percent_applied IS NOT NULL
                    AND investor_capital_weight_applied IS NOT NULL
                    AND total_pool_capital IS NOT NULL
                    AND total_investor_capital IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_periods');
    }
};
