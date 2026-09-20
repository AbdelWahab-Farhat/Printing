<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * `deleted_at` على نصيبِ الفترة — القاعدةُ الثابتة في هذا المشروع: لا جدولَ يُحذف منه صفٌّ حقاً.
 *
 * «الحذفُ هو التغيير الوحيد الذي لا يستطيع سجلُّ التدقيق التراجعَ عنه» — وهذا الصفُّ بعينه هو
 * النسبةُ التي وُزّع بها مالُ شهرٍ على ناس. ضياعُه يعني أن «بأيّ نسبةٍ قُسِّم سبتمبر؟» لا جواب له.
 *
 * والفهرسُ الفريد يُعاد بناؤه **جزئياً** معه (`WHERE deleted_at IS NULL`): بغيره لا يمكن أن
 * تُعاد كتابةُ نصيبٍ حُذف حذفاً ناعماً، لأن الصفَّ المحذوف يبقى في الفهرس ويمنع بديلَه.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investment_period_shares', function (Blueprint $table) {
            $table->softDeletes()->index();
        });

        DB::statement('ALTER TABLE investment_period_shares DROP CONSTRAINT IF EXISTS investment_period_shares_investment_period_id_investor_id_unique');

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_period_shares_one_per_investor
            ON investment_period_shares (investment_period_id, investor_id)
            WHERE deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS investment_period_shares_one_per_investor');

        DB::statement(<<<'SQL'
            ALTER TABLE investment_period_shares
            ADD CONSTRAINT investment_period_shares_investment_period_id_investor_id_unique
            UNIQUE (investment_period_id, investor_id)
        SQL);

        Schema::table('investment_period_shares', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }
};
