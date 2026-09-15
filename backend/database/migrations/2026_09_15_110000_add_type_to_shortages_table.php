<?php

declare(strict_types=1);

use App\Domain\Shortage\Enums\ShortageSource;
use App\Domain\Shortage\Enums\ShortageType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * What kind of thing is short, beside who wrote the row down.
 *
 * **`source` was already answering half of this question and could not be made to answer the
 * other half.** It says «يدوي» or «من طلبية» — who owns the numbers — and that is a fact about
 * the record. What the shop is actually out of is a fact about the goods: «ورق طباعة», «حبر»،
 * «صيانة». A shortage of paper somebody typed by hand is both, and one column cannot hold two
 * answers without «أرِني كل نواقص الورق» needing to know who entered each one first.
 *
 * So two columns, two questions — see {@see ShortageType}.
 *
 * **Backfilled rather than nullable**, because a type nobody set is a row the filter silently
 * drops: order-born rows take `order`, which is what they have always been, and every manual row
 * takes `other`. «أخرى» is the honest answer for them — nothing in the data says whether an old
 * «شريط لاصق عريض» was maintenance or something else, and guessing would put an invention in the
 * column that reports «على ماذا ننفق؟». Whoever cares can reclassify by hand.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shortages', function (Blueprint $table): void {
            // Thirty characters like `source` beside it, and a string rather than an enum type:
            // the same choice every status column in this schema makes, so a case added in PHP
            // needs no migration.
            $table->string('type', 30)->nullable()->after('source');
        });

        $order = ShortageType::Order->value;
        $other = ShortageType::Other->value;
        $fromOrder = ShortageSource::FromOrder->value;

        // Before the column is made NOT NULL, and in one statement rather than a chunked loop:
        // this table is small and the whole point is that no row is left without an answer.
        DB::statement(<<<SQL
            UPDATE shortages
               SET type = CASE WHEN source = '{$fromOrder}' THEN '{$order}' ELSE '{$other}' END
        SQL);

        Schema::table('shortages', function (Blueprint $table): void {
            $table->string('type', 30)->nullable(false)->change();
        });

        /*
         * **«نقص طلبية» belongs to the sync and to nothing else.**
         *
         * `source` and `type` are two halves of one fact for an order-born row, and the pair has
         * to hold or the list screen's one readable column starts lying: a clerk typing «نقص
         * طلبية» onto a roll of tape would put it on the board beside no order at all, and a
         * shortage mirrored from a line would be indistinguishable from it.
         *
         * Stated here as well as in the form and the enum — the three-layer arrangement RULES.md
         * §8 asks for, where validation gives the readable 422 and this gives the guarantee.
         */
        DB::statement(<<<SQL
            ALTER TABLE shortages
                ADD CONSTRAINT shortages_type_matches_source CHECK (
                    (source = '{$fromOrder}' AND type = '{$order}')
                    OR
                    (source <> '{$fromOrder}' AND type <> '{$order}')
                )
        SQL);

        Schema::table('shortages', function (Blueprint $table): void {
            // «أرِني كل نواقص الورق» — the query this column exists for, and the same shape the
            // `status` index beside it takes.
            $table->index(['type', 'created_at']);
        });
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE shortages DROP CONSTRAINT IF EXISTS shortages_type_matches_source');

        Schema::table('shortages', function (Blueprint $table): void {
            $table->dropIndex(['type', 'created_at']);
            $table->dropColumn('type');
        });
    }
};
