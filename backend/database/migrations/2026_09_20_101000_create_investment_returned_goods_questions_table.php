<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «بضاعة راجعة من طلبية ملغاة: صالحة أم تالفة؟» — the one thing the system cannot know.
 *
 * ## The gap this closes, which exists today
 *
 * When a printed order is cancelled, `ReverseOrderStockDeduction` credits its material back to the
 * shelf **as good stock**. Paper that has already been through a press is not good stock. Nothing
 * in the system can tell the difference — the movement ledger records quantities, not whether there
 * is ink on them — so until now the ruin had to be noticed and written off by a person who happened
 * to remember.
 *
 * Unremembered, the pool's period shows profit it did not earn and stock it does not really have,
 * and the error is only found when somebody counts the shelf.
 *
 * ## So the close refuses to proceed while one of these is open
 *
 * A question is raised automatically, answered by a person, and **blocks the period's close** until
 * it is. That is a deliberate piece of friction: the alternative is a distribution computed on
 * goods that do not exist, paid into wallets it can be withdrawn from.
 *
 * ## Only where the question is real
 *
 * Raised **only** for a printed line whose material was unpriced — the single case where returned
 * goods land back on a pool's own layers and may be ruined:
 *
 * - **وسيط** — no purchase order, no layer, nothing of the pool's was ever involved.
 * - **سادة** — sold off the shelf as it stands, never printed, so it comes back intact.
 * - **priced (سعر السادة)** — the investor was paid the day it left; a cancellation hands those
 *   goods to the **company**, not back to the pool.
 *
 * A prompt with one possible answer is noise, and noise is what trains people to click through
 * prompts that matter.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_returned_goods_questions', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investor_deal_id')->constrained('investor_deals')->cascadeOnDelete();

            // The order and the line whose goods came back. Both, because an order may have several
            // printed lines and each is its own question with its own answer.
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('order_item_id')->constrained('order_items')->cascadeOnDelete();
            $table->foreignId('stock_item_id')->constrained('stock_items')->restrictOnDelete();

            // What came back, and what it cost — read off the credit-back at the moment the
            // question was raised, so the answer does not depend on the shelf being unchanged.
            $table->decimal('quantity', 14, 3);
            $table->decimal('cost', 16, 2);

            // 'open' until somebody says; then 'good' or 'damaged'.
            $table->string('verdict', 10)->default('open');

            $table->timestamp('answered_at')->nullable();
            $table->foreignId('answered_by')->nullable()->constrained('users')->nullOnDelete();

            // **The stock adjustment «تالفة» produced**, when it produced one.
            //
            // A movement and not an expense, and the difference matters: ruined paper has to leave
            // the shelf. Booked as a cost only, the pool's `stock_at_cost` would still count goods
            // that do not exist, its deployable cash would be overstated by the same amount, and
            // the next lorry would be bought with money that was never there. Written as a damage
            // adjustment it lands in `DealStockPosition`'s damaged bucket by the ordinary road, and
            // the period's `damage_cost` reads it there with everything else that spoiled.
            //
            // «صالحة» writes nothing and leaves this null — the difference between «we checked» and
            // «nothing happened».
            $table->foreignId('damage_movement_id')->nullable()
                ->constrained('stock_movements')->nullOnDelete();

            $table->text('notes')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            // What the close asks: «has this pool any unanswered question?»
            $table->index(['investor_deal_id', 'verdict']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_returned_goods_questions
            ADD CONSTRAINT investment_returned_goods_questions_verdict_values
            CHECK (verdict IN ('open', 'good', 'damaged'))
        SQL);

        // An answered question names who answered it and when; an open one names neither. And only
        // «تالفة» may carry a write-off — «صالحة» that produced an expense would be a contradiction
        // nobody could read.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_returned_goods_questions
            ADD CONSTRAINT investment_returned_goods_questions_shape CHECK (
                (verdict = 'open' AND answered_at IS NULL AND damage_movement_id IS NULL)
                OR (verdict = 'good' AND answered_at IS NOT NULL AND damage_movement_id IS NULL)
                OR (verdict = 'damaged' AND answered_at IS NOT NULL)
            )
        SQL);

        // One question per line. A line's goods come back once.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_returned_goods_questions_one_per_line
            ON investment_returned_goods_questions (order_item_id)
            WHERE deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_returned_goods_questions');
    }
};
