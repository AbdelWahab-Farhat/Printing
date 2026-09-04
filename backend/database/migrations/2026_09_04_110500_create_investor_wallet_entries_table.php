<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * One append-only ledger per investor — his money and his profit, and where each of them is.
 *
 * Modelled on `order_payments` line for line, because that is how this project writes money:
 * a **positive** amount always, direction carried by the type rather than by a sign, correction
 * by a further row pointing back, `recorded_by` stamped rather than fillable, `occurred_at`
 * distinct from `created_at`, and the invariants in PostgreSQL rather than in validation alone.
 * There is no balance column anywhere, here or on `investors` or on `investor_deals`.
 *
 * **Two pots and two places.** The pot is capital or profit; the place is the wallet
 * (`investor_deal_id IS NULL`) or one deal. That is the whole model, and every figure the app
 * shows is one signed walk of this table:
 *
 * ```
 * capital in wallet = deposit − withdrawal − allocation + release
 * capital in deal D = allocation(D) − release(D)
 * profit in deal D  = profit(D) − loss(D) − profit_release(D)
 * profit in wallet  = profit_release − profit_withdrawal
 * ```
 *
 * **The withdrawal rule is structural, not a check somebody remembers.** Money only leaves
 * through `withdrawal` and `profit_withdrawal`, and both are wallet rows; profit only reaches
 * the wallet through `profit_release`, which only closing a deal writes. So «الربح يأتي
 * تدريجياً ولا يُسحب إلا عند انتهاء الصفقة» is enforced by the shape of the ledger — there is no
 * path that pays out a running deal, rather than a guard that could be forgotten.
 *
 * The same holds for capital: it goes into a deal by `allocation` and comes back by `release`,
 * so an investor cannot withdraw money that is currently financing goods on a shelf.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investor_wallet_entries', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investor_id')->constrained('investors')->restrictOnDelete();

            // Null means the wallet itself. Set means this row moved something into, out of, or
            // inside one deal.
            $table->foreignId('investor_deal_id')->nullable()
                ->constrained('investor_deals')->restrictOnDelete();

            $table->string('type', 20);

            $table->decimal('amount', 14, 2);

            // Only on a row where money actually crossed the counter.
            $table->string('method', 20)->nullable();
            $table->string('reference', 100)->nullable();

            // What produced this row — an order, for `profit` and `loss`. Named from the audit
            // morph map rather than free text, so the app resolves it the way it resolves every
            // other subject.
            $table->string('source_type', 40)->nullable();
            $table->unsignedBigInteger('source_id')->nullable();

            // When the money moved, not when somebody typed it in — the `order_payments` rule.
            // A profit row is stamped by the system and is never hand-dated.
            $table->timestamp('occurred_at');

            $table->text('notes')->nullable();

            $table->foreignId('reverses_entry_id')->nullable()
                ->constrained('investor_wallet_entries')->nullOnDelete();

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['investor_id', 'occurred_at']);
            $table->index(['investor_deal_id', 'type']);
            $table->index(['source_type', 'source_id']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_amount_positive CHECK (amount > 0)
        SQL);

        // Never reverse the same row twice — a database guarantee, not a race somebody loses.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investor_wallet_entries_reverses_entry_id_unique
            ON investor_wallet_entries (reverses_entry_id)
            WHERE reverses_entry_id IS NOT NULL AND deleted_at IS NULL
        SQL);

        // One order produces at most one earning row per deal. The same law
        // `journal_entries (source_type, source_id, kind)` states in the accounting design:
        // «لا يُرحَّل الحدث الواحد مرتين». Without it, a status walked twice pays twice.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investor_wallet_entries_one_earning_per_source
            ON investor_wallet_entries (investor_id, investor_deal_id, source_type, source_id, type)
            WHERE source_type IS NOT NULL AND deleted_at IS NULL
        SQL);

        // The four shapes that exist, written as their disjunction so each says which it permits.
        DB::statement(<<<'SQL'
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal', 'profit_withdrawal')
                    AND investor_deal_id IS NULL AND method IS NOT NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('allocation', 'release', 'profit_release')
                    AND investor_deal_id IS NOT NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('profit', 'loss')
                    AND investor_deal_id IS NOT NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NOT NULL AND source_id IS NOT NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investor_wallet_entries');
    }
};
