<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * The three numbers that govern every pool's calendar.
 *
 * **Global, and therefore shared by every pool.** Per-pool calendars would mean N different close
 * dates to remember and no common boundary for a settlement that spans pools to stand on. One
 * calendar means «أقفل سبتمبر» is a single act over every pool.
 *
 * **They affect the future only, and that is structural rather than guarded.** The date of the
 * next close is the open period's `ends_on`, and the date of the next settlement is the last one
 * plus the interval — both *derived* when asked. There is no stored «next close» column for a
 * settings change to invalidate, and a closed period is unreachable from here because nothing
 * here is ever read backwards. That is the same split `manufacturing_cost_rates` and
 * `investor_profit_share_percent` already make: a rate changed today cannot move what was costed
 * yesterday.
 *
 * **`entry_grace_days` is the one that is easy to misread.** It is not a deadline for paying; it
 * is how long after a period opens that money may still join *that* period. Inside it, capital
 * participates for the whole period and ownership stays a plain ratio; outside it, the money
 * waits for the next period. Zero makes the boundary strict, which is the behaviour the
 * arithmetic in the design document assumes and the reason the rest of it needs no NAV.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            // «كل شهر» by default, because that is the arrangement the business already has.
            $table->smallInteger('profit_period_months')->default(1);

            // «كل ٦ أشهر» — the comprehensive review, deliberately rarer than the close.
            $table->smallInteger('settlement_period_months')->default(6);

            $table->smallInteger('entry_grace_days')->default(3);
        });

        // Ranges rather than bare integers: a period of zero months has no end date to derive,
        // and a grace window longer than the shortest period would let money join a period that
        // had already closed.
        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_profit_period_range
            CHECK (profit_period_months >= 1 AND profit_period_months <= 12)
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_settlement_period_range
            CHECK (settlement_period_months >= 1 AND settlement_period_months <= 24)
        SQL);

        // 28, not 31: the shortest month has 28 days, and a window that could outlast February
        // would be a window that sometimes swallows a whole period.
        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_entry_grace_days_range
            CHECK (entry_grace_days >= 0 AND entry_grace_days <= 28)
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT IF EXISTS company_settings_entry_grace_days_range');
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT IF EXISTS company_settings_settlement_period_range');
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT IF EXISTS company_settings_profit_period_range');

        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn([
                'profit_period_months',
                'settlement_period_months',
                'entry_grace_days',
            ]);
        });
    }
};
