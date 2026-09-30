<?php

use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * خطرُ العميل على الشركة لا على المستثمر — نوعان جديدان في الدفترين.
 *
 * قرارُ المالك، ٢٤ سبتمبر ٢٠٢٦، بعد سؤال «من يتحمّل حين لا يدفع العميل؟»: الشركة، كما تتحمّل
 * الإلغاء اليوم — «استلم الزبون ما استلمش، المطبعة تتحمّل».
 *
 * - {@see CashEntryType::WriteOffCoveredByCompany} في الخزينة: الشطبُ يُدخلها نصيبَ الصندوق من
 *   الفرق من مال الشركة. مصدرُه الطلبية، فذراعُه في `_shape` ذراعُ بقيّة الأنواع ذوات المصدر.
 * - {@see WalletEntryType::ProfitWithheld} في المحافظ: ربحٌ أُفرِج عنه في فترةٍ «قيد الإغلاق» ثم
 *   عُكس مالُه، فيعود محجوزاً. صفُّ تسويةٍ بلا مصدرٍ ولا طريقة دفع، فذراعُه ذراعُ `profit_release`.
 */
return new class extends Migration
{
    private const CASH = "'deposit', 'purchase', 'expense', 'sale_proceeds', 'profit_payout', 'company_payout', 'capital_return', 'stock_sold_to_press', 'legacy_transfer'";

    private const WALLET = "'allocation', 'release', 'profit_release',\n                             'capital_writedown', 'loss_absorbed_by_company', 'loss_carried_out', 'loss_carried_in'";

    public function up(): void
    {
        $this->cashShapeWith(self::CASH.", 'write_off_covered_by_company'");
        $this->walletShapeWith(self::WALLET.", 'profit_withheld'");
    }

    public function down(): void
    {
        // حذفٌ ناعمٌ لا محو، كما في رجوع الترحيل: الشرطُ السابق لا يعرف النوعين.
        DB::table('investment_cash_entries')
            ->where('type', 'write_off_covered_by_company')
            ->whereNull('deleted_at')
            ->update(['deleted_at' => now()]);

        DB::table('investor_wallet_entries')
            ->where('type', 'profit_withheld')
            ->whereNull('deleted_at')
            ->update(['deleted_at' => now()]);

        $this->cashShapeWith(self::CASH);
        $this->walletShapeWith(self::WALLET);
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

    private function walletShapeWith(string $settlementTypes): void
    {
        DB::statement('ALTER TABLE investor_wallet_entries DROP CONSTRAINT investor_wallet_entries_shape');

        DB::statement(<<<SQL
            ALTER TABLE investor_wallet_entries
            ADD CONSTRAINT investor_wallet_entries_shape CHECK (
                (type IN ('deposit', 'withdrawal', 'profit_withdrawal')
                    AND investor_deal_id IS NULL AND method IS NOT NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type = 'profit_capitalisation'
                    AND investor_deal_id IS NULL AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ({$settlementTypes})
                    AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NULL)
                OR (type IN ('profit', 'loss')
                    AND method IS NULL
                    AND reverses_entry_id IS NULL AND source_type IS NOT NULL AND source_id IS NOT NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }
};
