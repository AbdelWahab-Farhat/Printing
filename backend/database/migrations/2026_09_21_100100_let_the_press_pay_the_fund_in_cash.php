<?php

use App\Domain\Investor\Queries\FundValuation;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * طريقٌ ثامنٌ يدخل به نقدٌ إلى الخزينة: المطبعةُ تشتري سادةَ الصندوق.
 *
 * بقيّةُ بضاعة الصندوق تُحصَّل من **العميل**، فيدخل نقدُها بـ`sale_proceeds` بنسبة ما دفعه.
 * والسادةُ المسعَّرة تُباع عند باب المخزن لا عند باب العميل: «استلم الزبون ما استلمش، المطبعة
 * تتحمّل». فالمشتري المطبعةُ نفسُها، والثمنُ يُستحقّ لحظةَ خروج البضاعة.
 *
 * **ولولا هذا الصفّ لانكمش الصندوقُ بكل كيلو تشتريه مطبعتُه:** البضاعةُ تغادر الرفّ فتسقط من
 * {@see FundValuation}، والمستثمرُ يُقيَّد له الهامشُ وحدَه —
 * ورأسُ المال الذي اشتراها لا يعود من أيّ باب.
 *
 * والمبلغُ **الثمنُ كاملاً** لا الهامش: التكلفةُ خرجت من هذه الخزينة يومَ الشراء، فتعود إليها
 * مع ربحها، ويخرج الهامشُ منها بعدُ إلى المحافظ بـ`profit_payout` كأيّ ربحٍ آخر.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE investment_cash_entries DROP CONSTRAINT IF EXISTS investment_cash_entries_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investment_cash_entries
            ADD CONSTRAINT investment_cash_entries_shape CHECK (
                (type IN ('deposit', 'purchase', 'expense', 'sale_proceeds',
                          'profit_payout', 'company_payout', 'capital_return',
                          'stock_sold_to_press')
                    AND source_type IS NOT NULL AND source_id IS NOT NULL
                    AND reverses_entry_id IS NULL)
                OR (type = 'reversal'
                    AND source_type IS NULL AND source_id IS NULL
                    AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE investment_cash_entries DROP CONSTRAINT IF EXISTS investment_cash_entries_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investment_cash_entries
            ADD CONSTRAINT investment_cash_entries_shape CHECK (
                (type IN ('deposit', 'purchase', 'expense', 'sale_proceeds',
                          'profit_payout', 'company_payout', 'capital_return')
                    AND source_type IS NOT NULL AND source_id IS NOT NULL
                    AND reverses_entry_id IS NULL)
                OR (type = 'reversal'
                    AND source_type IS NULL AND source_id IS NULL
                    AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }
};
