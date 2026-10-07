<?php

use App\Domain\Investor\Enums\CashEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * نصيبُ الشركة من مصروف الصندوق تدفعه الشركة — نوعٌ جديدٌ في خزينة الصندوق.
 *
 * قرارُ المالك، ٥ أكتوبر ٢٠٢٦ (CONTINUOUS-FUND-DESIGN §١٠، الخيار ب): المصروفُ يخرج كاملاً من نقد
 * الصندوق، والشركاءُ يُحمَّلون نصيبَهم وحده — فكان نصيبُ الشركة يقع على المستثمرين من طريق سعر
 * الوحدة دون أن يُكتب عليهم. {@see CashEntryType::ExpenseCoveredByCompany} يُدخله من مال الشركة
 * يومَ المصروف، كما يُدخل {@see CashEntryType::WriteOffCoveredByCompany} نصيبَ الشطب.
 */
return new class extends Migration
{
    private const CASH = "'deposit', 'purchase', 'expense', 'sale_proceeds', 'profit_payout', 'company_payout', 'capital_return', 'stock_sold_to_press', 'legacy_transfer', 'write_off_covered_by_company'";

    public function up(): void
    {
        $this->cashShapeWith(self::CASH.", 'expense_covered_by_company'");
    }

    public function down(): void
    {
        // حذفٌ ناعمٌ لا محو، كما في رجوع الترحيل السابق: الشرطُ السابق لا يعرف النوع.
        DB::table('investment_cash_entries')
            ->where('type', 'expense_covered_by_company')
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
