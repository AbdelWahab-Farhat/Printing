<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * A pool's profit and loss as it happens, before anybody's share of it is known.
 *
 * ## Why this table exists at all
 *
 * Under the صفقة, an order's profit was split into per-investor wallet rows the moment it was
 * realized — it could be, because the percentages were frozen when the lorry was funded. A صندوق
 * recomputes ownership from capital **at the close**, so on the day a sale lands nobody knows yet
 * who gets what. The margin is therefore **earned into the period** and **divided at its end**, and
 * this is where it waits.
 *
 * That is why a row here names no investor. It is the pool's whole slice, and the only table in
 * this feature that holds an undivided figure.
 *
 * ## Signed, unlike the wallet
 *
 * `investor_wallet_entries.amount` is positive by CHECK because a row there moves value *between
 * pots* and the type must say which direction. This is one party's P&L, where a lorry that landed
 * dearer than the price agreed for it makes a genuinely negative margin — the same way
 * `orders.gross_profit` is already signed.
 *
 * ## Corrections do not reach back into a closed period
 *
 * A restated line or a cancelled order writes a **further row for the difference**, into whichever
 * period is open when the correction happens. It never edits or reverses the original.
 *
 * ```
 * Sept   order X realizes 4,000   → +4,000 in September
 * Sept   closes; the 4,000 is divided and paid into wallets
 * Oct    order X is restated to 3,000 → −1,000 in OCTOBER
 * ```
 *
 * Reversing September's row instead would change a period whose money has already been withdrawn.
 * The delta is what the ledger can honestly carry, and `source_sequence` keeps every attempt
 * distinguishable so the history reads as a sequence of facts rather than a figure that moved.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_realized_earnings', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investment_period_id')->constrained('investment_periods')->cascadeOnDelete();

            // What produced this figure — an order, or one of its lines. Named from the audit
            // morph map rather than free text, so the app resolves it the way it resolves every
            // other subject.
            $table->string('source_type', 40);
            $table->unsignedBigInteger('source_id');

            // Which attempt at this source this row is. A correction names the same source again,
            // so without this the unique key below would refuse the correction and leave the wrong
            // figure standing as the only one the database would accept.
            $table->smallInteger('source_sequence')->default(1);

            // **Signed** — see the class docblock. The delta this attempt contributes, not the
            // running total for the source.
            $table->decimal('amount', 16, 2);

            $table->timestamp('occurred_at');
            $table->text('notes')->nullable();

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            // «what has this source earned this pool, across every period?» — the question every
            // correction asks before it decides on a delta.
            $table->index(['source_type', 'source_id']);
            $table->index('investment_period_id');
        });

        // One attempt is recorded once. The law `investor_wallet_entries_one_earning_per_source`
        // already states for the wallet: «لا يُرحَّل الحدث الواحد مرتين».
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_realized_earnings_one_attempt_per_source
            ON investment_realized_earnings (investment_period_id, source_type, source_id, source_sequence)
            WHERE deleted_at IS NULL
        SQL);

        // Zero is not a fact worth a row: a source that earned nothing is a source with no row, and
        // an unchanged re-post writes nothing at all rather than a line of noise.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_realized_earnings
            ADD CONSTRAINT investment_realized_earnings_amount_not_zero CHECK (amount <> 0)
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_realized_earnings');
    }
};
