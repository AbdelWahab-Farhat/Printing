<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Capital waiting at a period boundary — money in, and money out.
 *
 * **Why a queue exists at all.** Ownership of a pool is a plain capital ratio, and that is only
 * exact if capital does not move inside a period. So money offered late joins the *next* period,
 * and money asked for back leaves at the *close*. Without this table those two facts would have
 * nowhere to live between the day somebody decides and the day it takes effect.
 *
 * **The money is not held here.** A deposit lands in the investor's wallet exactly as it always
 * has; what is deferred is only the `allocation` into the pool. So a pending request is an
 * *intention*, and the investor can cancel it and withdraw his money — it was never trapped. The
 * ledger stays the one place money is, and this table says what is about to happen to it.
 *
 * **Both directions in one table.** An exit is the same shape as an entry — a person, a pool, an
 * amount, a boundary it takes effect at, and a row in the ledger once it does. Two tables would
 * have been the same six columns twice and two screens to keep in step.
 *
 * `applied_entry_id` is the receipt: the wallet row this request finally became. Null until then,
 * and what makes «has this already been applied?» a question about data rather than about timing.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_capital_requests', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investor_id')->constrained('investors')->restrictOnDelete();
            $table->foreignId('investor_deal_id')->constrained('investor_deals')->cascadeOnDelete();

            // 'in' — capital joining the pool. 'out' — capital coming back to the wallet.
            $table->string('direction', 3);

            $table->decimal('amount', 14, 2);

            // When the person asked, which is not when it takes effect — the `occurred_at` /
            // `created_at` split this schema already makes everywhere money is concerned.
            $table->timestamp('requested_at');

            // The period this request joins. **Null while it is pending**, and deliberately so:
            // the next period does not exist yet, and naming a row that has not been created
            // would be a promise this table cannot keep. Filled when the request is applied.
            $table->foreignId('effective_period_id')->nullable()
                ->constrained('investment_periods')->nullOnDelete();

            $table->string('status', 20)->default('pending');

            // The wallet row this became. The receipt, and the proof it was applied once.
            $table->foreignId('applied_entry_id')->nullable()
                ->constrained('investor_wallet_entries')->nullOnDelete();

            $table->text('notes')->nullable();

            $table->foreignId('requested_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            // What the period-open action asks for: every pending request for this pool.
            $table->index(['investor_deal_id', 'status']);
            $table->index(['investor_id', 'status']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_capital_requests
            ADD CONSTRAINT investment_capital_requests_direction_values
            CHECK (direction IN ('in', 'out'))
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE investment_capital_requests
            ADD CONSTRAINT investment_capital_requests_status_values
            CHECK (status IN ('pending', 'applied', 'cancelled'))
        SQL);

        // Every amount positive, as in `investor_wallet_entries`: the direction is a word, never
        // a sign. A request for nothing is not a request.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_capital_requests
            ADD CONSTRAINT investment_capital_requests_amount_positive
            CHECK (amount > 0)
        SQL);

        // The three states, each saying what it permits. An applied request has a receipt and a
        // period; a pending one has neither; a cancelled one never will.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_capital_requests
            ADD CONSTRAINT investment_capital_requests_shape CHECK (
                (status = 'pending' AND applied_entry_id IS NULL AND effective_period_id IS NULL)
                OR (status = 'applied' AND applied_entry_id IS NOT NULL AND effective_period_id IS NOT NULL)
                OR (status = 'cancelled' AND applied_entry_id IS NULL)
            )
        SQL);

        // One wallet row answers for one request. Without it a retried apply could pay the same
        // request twice and both rows would look equally legitimate — the law
        // `investor_wallet_entries_one_earning_per_source` already states for earnings.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_capital_requests_applied_entry_unique
            ON investment_capital_requests (applied_entry_id)
            WHERE applied_entry_id IS NOT NULL AND deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_capital_requests');
    }
};
