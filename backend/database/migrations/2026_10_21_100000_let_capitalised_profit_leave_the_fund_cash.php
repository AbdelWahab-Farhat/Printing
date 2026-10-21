<?php

use App\Domain\Investor\Enums\CashEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * الربحُ الذي صار رأسَ مالٍ يخرج من نقد الصندوق — نوعٌ جديدٌ في خزينة الصندوق.
 *
 * {@see CashEntryType::ProfitCapitalised}: كان «تحويل أرباح إلى رأس مال» يُنقص دَينَ الصندوق ولا
 * يُنقص نقدَه، فيرفع سعرَ الوحدة لكلِّ الشركاء، ثم يدخل النقدَ مرّةً ثانية حين يُكتتب به.
 * والصفوفُ السابقة يكتب لها `investment:post-capitalised-profit`.
 */
return new class extends Migration
{
    private const CASH = "'deposit', 'purchase', 'expense', 'sale_proceeds', 'profit_payout', 'company_payout', 'capital_return', 'stock_sold_to_press', 'legacy_transfer', 'write_off_covered_by_company', 'expense_covered_by_company'";

    public function up(): void
    {
        $this->cashShapeWith(self::CASH.", 'profit_capitalised'");
    }

    public function down(): void
    {
        // حذفٌ ناعمٌ لا محو، كما في رجوع الترحيل السابق: الشرطُ السابق لا يعرف النوع.
        DB::table('investment_cash_entries')
            ->where('type', 'profit_capitalised')
            ->whereNull('deleted_at')
            ->update(['deleted_at' => now()]);

        $this->cashShapeWith(self::CASH);
    }

    private function cashShapeWith(string $types): void
    {
        DB::statement('ALTER TABLE investment_cash_entries DROP CONSTRAINT IF EXISTS investment_cash_entries_shape');

        DB::statement(<<<SQL
            ALTER TABLE investment_cash_entries
            ADD CONSTRAINT investment_cash_entries_shape CHECK (
                (type IN ({$types})
                    AND source_type IS NOT NULL AND source_id IS NOT NULL
                    AND reverses_entry_id IS NULL)
                OR (type = 'reversal'
                    AND source_type IS NULL AND source_id IS NULL
                    AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }
};
