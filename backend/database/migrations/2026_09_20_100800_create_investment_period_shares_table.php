<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * How one period's profit was divided — «حصة كل مستثمر», frozen.
 *
 * **This is the row that replaces `investor_deal_shares.share_percent`.** A صفقة froze its
 * percentages once, at funding, and every split for the rest of its life read them. A صندوق has no
 * such number: ownership is recomputed from capital at every close, so the percentage is an
 * *outcome* of a period rather than a term of the container — and it belongs beside the period that
 * produced it, not on a roster that would have to be rewritten every month.
 *
 * Written once, at the close, and never again. It is what the money was actually divided on, so
 * recomputing it later from today's capital would answer a different question — the same reasoning
 * the period's own snapshot rests on.
 *
 * `is_company` marks the participant that is also the operator: it takes a capital weight like
 * anybody else **and** the profit share on top. Kept as a flag on the row rather than resolved by
 * looking the investor up later, so a historical split can be read without knowing what the
 * company's account happens to be today.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_period_shares', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investment_period_id')->constrained('investment_periods')->cascadeOnDelete();
            $table->foreignId('investor_id')->constrained('investors')->restrictOnDelete();

            // What he had in the pool for this period — the numerator of his weight, and the figure
            // somebody will check the arithmetic against by hand.
            $table->decimal('capital', 16, 2);

            // His slice **of the investors' side**, not of the whole profit. Two multiplications
            // rather than one number doing both jobs — the split `investor_deal_shares` always
            // made, kept here for the same reason.
            $table->decimal('share_percent', 9, 4);

            // Signed: a losing period gives him a negative share, and that is what was written
            // down against his capital.
            $table->decimal('net_share', 16, 2);

            $table->boolean('is_company')->default(false);

            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_period_shares_one_row_per_investor
            ON investment_period_shares (investment_period_id, investor_id)
            WHERE deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE investment_period_shares
            ADD CONSTRAINT investment_period_shares_percent_range
            CHECK (share_percent >= 0 AND share_percent <= 100)
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_period_shares');
    }
};
