<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * التسوية — the periodic assertion that the books match the goods.
 *
 * ## What a settlement is, and what it is not
 *
 * **It is a review and approval point.** It does not close the pool, it does not liquidate stock,
 * and it moves no money. A pool goes on trading through and past it. What it produces is a dated,
 * signed statement of where the pool's money is — and, crucially, the **drift**: the difference
 * between what the ledger says the pool is worth and what an independent walk of its movements can
 * account for.
 *
 * ## Why the drift is the only interesting column
 *
 * Every other figure here can be derived on demand, and most screens do derive them. Storing them
 * is a snapshot, not a cache — the same standing `manufacturing_cost_rates` has, and for the same
 * reason: what somebody approved in March must still read in March's terms in December.
 *
 * The drift cannot be derived on demand in any useful sense, because **it is the comparison of two
 * derivations**:
 *
 * ```
 * book side   = Σ capital + Σ undivided profit               ← the wallet ledger and the periods
 * walked side = capital in − capital out
 *             + earnings to date − profit released
 *             − expenses charged
 *             − cost of every layer bought + cost of every layer sold
 *             + stock still on the shelf at cost             ← the cost layers and the draw ledger
 *
 * drift       = book side − walked side
 * ```
 *
 * Two sources that never consult each other. In a healthy pool they agree to the fils, and the
 * arithmetic proving it is in `SettlementSnapshot`.
 *
 * **A non-zero drift is a finding, not an error to absorb.** It is what a stock adjustment posted
 * outside the investment flow looks like: goods leave the shelf, no loss is ever charged, and the
 * pool's apparent cash quietly rises by their cost. Nothing else in the system would ever mention
 * it. That is the whole reason this table exists.
 *
 * ## `undeployed_current_profit` is named rather than hidden
 *
 * The open period's undivided profit is real money the company is holding, but `PoolDeployableCash`
 * does not count it as spendable — it reads the wallet ledger, where a pool's profit appears only
 * at the close and leaves again in the same transaction. Whether that margin *should* be spendable
 * on the next lorry is the owner's decision, not this table's; what this table refuses to do is let
 * the figure go unmentioned. It is a line of its own, so the difference has a name.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_settlements', function (Blueprint $table) {
            $table->id();
            $table->string('code', 20)->nullable();

            $table->foreignId('investor_deal_id')->constrained('investor_deals')->cascadeOnDelete();

            // The span reviewed, by period rather than by date: a settlement is an assertion about
            // whole closes, and half a period has no distribution to assert anything about. Both
            // nullable, because the first settlement of a pool that has never closed one still has
            // a position worth signing.
            $table->foreignId('period_from_id')->nullable()
                ->constrained('investment_periods')->nullOnDelete();
            $table->foreignId('period_to_id')->nullable()
                ->constrained('investment_periods')->nullOnDelete();

            $table->date('settled_on');
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();

            // ── the book side ────────────────────────────────────────────────────────────
            $table->decimal('total_capital', 16, 2)->default('0');
            $table->decimal('investor_capital', 16, 2)->default('0');
            $table->decimal('company_capital', 16, 2)->default('0');

            // ── where that money is ──────────────────────────────────────────────────────
            $table->decimal('deployable_cash', 16, 2)->default('0');
            $table->decimal('stock_at_cost', 16, 2)->default('0');

            // Real money the pool has earned and nobody has divided yet. Excluded from
            // `deployable_cash` by the query that computes it — see the class docblock.
            $table->decimal('undeployed_current_profit', 16, 2)->default('0');

            // Booked as earned, not yet collected from the customer. Profit is recognised at
            // delivery, so `deployable_cash` counts an uncollected sale as though the money were
            // in hand; this is the size of that assumption.
            $table->decimal('receivables', 16, 2)->default('0');

            // Undrawn profit sitting in wallets — money the company holds and does not own. The
            // owner's ruling: it is never working capital.
            $table->decimal('liabilities', 16, 2)->default('0');

            // ── what the pool has done, cumulatively ─────────────────────────────────────
            $table->decimal('distributed_profit_to_date', 16, 2)->default('0');
            $table->decimal('damage_to_date', 16, 2)->default('0');
            $table->decimal('shortage_to_date', 16, 2)->default('0');

            // ── the comparison ───────────────────────────────────────────────────────────
            // Stored beside the drift rather than left implicit: a drift with no working shown is
            // a number somebody has to reproduce before they can act on it, and by then the shelf
            // has moved.
            $table->decimal('reconstructed_cash', 16, 2)->default('0');
            $table->decimal('drift', 16, 2)->default('0');

            $table->text('notes')->nullable();

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['investor_deal_id', 'settled_on']);
        });

        // Partial, like every unique index in this schema: a removed settlement releases its code.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_settlements_code_unique
            ON investment_settlements (code)
            WHERE deleted_at IS NULL
        SQL);

        // A span that runs backwards is not a span. Equal ids are fine — a settlement covering one
        // period is the ordinary case.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_settlements
            ADD CONSTRAINT investment_settlements_span_runs_forwards CHECK (
                period_from_id IS NULL
                OR period_to_id IS NULL
                OR period_from_id <= period_to_id
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_settlements');
    }
};
