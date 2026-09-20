<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «الحد الأدنى للبقاء» — how long an investor's capital must stay in a pool before he may ask for
 * it back.
 *
 * ## The gap this closes
 *
 * Until now there was **no minimum term at all**. A man could join a pool in January, take his
 * share of January's profit at the close, and have his capital back at the same close — a month's
 * earnings for a month's money, with the pool left to find the cash. Nothing in the design ever
 * settled this; it simply was not asked.
 *
 * ## Measured from his **first** capital into that pool
 *
 * Not from the latest top-up, which would restart the clock every time he added money and make
 * paying more into a pool a reason to be locked in longer — the opposite of what anybody intends.
 * Not per tranche either: that turns one man's stake into a row of separately-maturing parcels,
 * and «كم أستطيع أن أسحب اليوم؟» stops having one answer.
 *
 * So: the earliest `allocation` row for that investor and that pool, and everything he has put in
 * since rides on it.
 *
 * ## Zero means what it has always meant
 *
 * The default is **0**, which is exactly today's behaviour — an exit may be asked for at any time
 * and is paid at the next close. Nothing changes until somebody sets it, and a pool that has been
 * running under the old rule does not suddenly lock anybody in.
 *
 * ## Global, like every other period setting
 *
 * One number for every investor and every pool, beside `profit_period_months` and
 * `entry_grace_days` (§4.2). A term agreed per person is a different feature with a column on the
 * share row, a field on the capital form, and a rule that reads differently on every screen that
 * mentions leaving — and the owner chose the one number.
 *
 * **It gates the request, not the payout.** An exit that is already queued was legitimate when it
 * was made, and a settings change must not strand it — the same standing every other setting here
 * has: it decides what happens next and never rewrites what already did.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            $table->unsignedSmallInteger('minimum_term_months')->default(0);
        });

        // Between nothing and two years, matching how the sibling intervals are bounded. The
        // upper limit is not a business rule so much as a typo guard: «120» where «12» was meant
        // would lock a man in for a decade, and the refusal to store it is cheaper than the
        // conversation afterwards.
        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_minimum_term_months_range
            CHECK (minimum_term_months BETWEEN 0 AND 24)
        SQL);
    }

    public function down(): void
    {
        DB::statement(
            'ALTER TABLE company_settings DROP CONSTRAINT IF EXISTS company_settings_minimum_term_months_range'
        );

        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn('minimum_term_months');
        });
    }
};
