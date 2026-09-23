<?php

declare(strict_types=1);

use App\Domain\Investor\Actions\FoldDealIntoFund;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * صفقةٌ قديمة تدخل الصندوق — عمودٌ يقول إنها دخلت، ونوعُ نقدٍ يحمل مالَها إلى خزينته.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٠.٩، الشريحة ١١.
 * والفعلُ: {@see FoldDealIntoFund}.
 *
 * ## `folded_into_fund_at`
 *
 * **ليس زينة: الفترةُ تقرؤه لتعرف ما ليس من شأنها.** صفُّ الإفراج الذي يكتبه التحويلُ لا يعني
 * «ربحُ هذه الفترة دُفع» — ولو قرأه إقفالُ الفترة كذلك لرحّل على صاحبه خسارةً وهمية بحجم ربحه
 * في الصفقة، ولأفرج عن ربحها مرّةً ثانية. فصفقةٌ دخلت الصندوق تُسوّى بالتحويل ثم بإقفالها هي،
 * ولا تُسوّيها فترة.
 *
 * ## `legacy_transfer`
 *
 * صفقةٌ قديمة لا خزينةَ لها: ما باعته دخل صندوقَ الشركة. فحين تدخل الصندوق، ينتقل مالُ صاحبها من
 * صندوق الشركة إلى خزينة الصندوق بهذا النوع — نقدُه المحقَّق الذي صار وحدات، وربحُه الذي صار في
 * محفظته فيُسحب منها. **وبلا هذا الأخير يُصرف ربحُ الصفقة من نقد الصندوق**، لأن كلَّ سحبِ أرباحٍ
 * يخرج من هذه الخزينة.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_deals', function (Blueprint $table) {
            $table->timestamp('folded_into_fund_at')->nullable();
        });

        $this->shapeWith("'deposit', 'purchase', 'expense', 'sale_proceeds', 'profit_payout', 'company_payout', 'capital_return', 'stock_sold_to_press', 'legacy_transfer'");
    }

    public function down(): void
    {
        DB::table('investment_cash_entries')->where('type', 'legacy_transfer')->delete();

        $this->shapeWith("'deposit', 'purchase', 'expense', 'sale_proceeds', 'profit_payout', 'company_payout', 'capital_return', 'stock_sold_to_press'");

        Schema::table('investor_deals', function (Blueprint $table) {
            $table->dropColumn('folded_into_fund_at');
        });
    }

    private function shapeWith(string $types): void
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
