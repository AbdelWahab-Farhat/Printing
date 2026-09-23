<?php

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Enums\PeriodStatus;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * الحالةُ الثالثة: «قيد الإغلاق» — فترةٌ انتهت نافذتُها ولم تصل آخرُ طلبياتها.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٠.٧، الشريحة ١٠.
 *
 * ## ما كان، ولماذا نُقض
 *
 * كانت الفترةُ تبقى `open` بعد نهاية نافذتها حتى تُسلَّم آخرُ طلبياتها، و{@see
 * CloseInvestmentPeriod} يرفض الإقفال ما دامت واحدةٌ طائرة. **فطلبيةٌ واحدة تحبس أرباحَ كلّ
 * المستثمرين** إلى ما بعد نهاية الشهر — وهي الحالةُ التي واجهها المالك فنقض القاعدة:
 * «النافذةُ تنتهي في موعدها، والطلبيةُ المتأخّرة تُدفَع وحدَها يوم تصل».
 *
 * ## ولماذا حالةٌ ثالثة ولا تكفي الاثنتان
 *
 * الفترةُ بعد موعدها تفعل شيئين متناقضين في عين `open` و`closed` معاً: **لا تقبل قيداً جديداً**
 * — أيُّ طلبيةٍ اليوم تاريخُها يضعها في التالية — **وتقبل ربحَ طلبياتها هي**. و`open` تقبل
 * كلَّ شيء، و`closed` ترفض كلَّ شيء، فليس في الاثنتين موضعٌ لهذا التفريق.
 *
 * ## والقيدُ يسوّيها بالمفتوحة لا بالمغلقة — عمداً
 *
 * أرقامُها ما زالت تتحرّك: طلبيةٌ تُسلَّم غداً ترفع `net_profit`، وأخرى تُلغى تُنزله. فرقمٌ
 * يُكتب عليها اليوم رقمٌ يكذب غداً، **وهو العطبُ نفسُه الذي يحرسه الشرطُ على المفتوحة**. ولذلك
 * لا تُجمَّد أرقامُ الفترة إلا لحظةَ `closed` وحدها، حين لا يبقى ما يحرّكها.
 *
 * ## وفهرسُ «مفتوحةٌ واحدة» لا يُمسّ
 *
 * شرطُه `WHERE status = 'open'` بنصّه، فـ«قيد الإغلاق» خارجه بلا سطرٍ جديد — وهو المقصود:
 * سبتمبر ينتظر بينما أكتوبر مفتوح، **وقد ينتظر أغسطس معه**. المفتوحةُ تبقى واحدةً أبداً،
 * والمنتظِراتُ بلا عدد.
 *
 * @see PeriodStatus::Closing
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE investment_periods DROP CONSTRAINT investment_periods_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_shape CHECK (
                (status IN ('open', 'closing')
                    AND closed_at IS NULL AND closed_by IS NULL
                    AND closing_stock_cost IS NULL AND closing_cash IS NULL
                    AND sales_revenue IS NULL AND cost_of_goods_sold IS NULL
                    AND cost_damaged IS NULL AND cost_short IS NULL
                    AND expenses_amount IS NULL AND net_profit IS NULL
                    AND investors_pool IS NULL AND company_share IS NULL
                    AND through_consumption_id IS NULL AND through_movement_id IS NULL
                    AND through_wallet_entry_id IS NULL AND through_cash_entry_id IS NULL)
                OR (status = 'closed'
                    AND closed_at IS NOT NULL
                    AND closing_stock_cost IS NOT NULL AND closing_cash IS NOT NULL
                    AND sales_revenue IS NOT NULL AND cost_of_goods_sold IS NOT NULL
                    AND cost_damaged IS NOT NULL AND cost_short IS NOT NULL
                    AND expenses_amount IS NOT NULL AND net_profit IS NOT NULL
                    AND investors_pool IS NOT NULL AND company_share IS NOT NULL
                    AND through_consumption_id IS NOT NULL AND through_movement_id IS NOT NULL
                    AND through_wallet_entry_id IS NOT NULL AND through_cash_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        // **لا فترةَ منتظِرةٌ تنجو من الرجوع.** شرطُ ما قبل هذا الترحيل لا يعرف `closing`، فصفٌّ
        // يحمله يمنع إضافةَ الشرط نفسِه. وردُّها إلى `open` هو أقربُ ما كانت عليه قبلاً: نافذتُها
        // انتهت ولم تُجمَّد أرقامُها بعد — وهي بالضبط حالُ فترةٍ تنتظر طلبيتَها في النظام القديم.
        DB::table('investment_periods')->where('status', 'closing')->update(['status' => 'open']);

        DB::statement('ALTER TABLE investment_periods DROP CONSTRAINT investment_periods_shape');

        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_shape CHECK (
                (status = 'open'
                    AND closed_at IS NULL AND closed_by IS NULL
                    AND closing_stock_cost IS NULL AND closing_cash IS NULL
                    AND sales_revenue IS NULL AND cost_of_goods_sold IS NULL
                    AND cost_damaged IS NULL AND cost_short IS NULL
                    AND expenses_amount IS NULL AND net_profit IS NULL
                    AND investors_pool IS NULL AND company_share IS NULL
                    AND through_consumption_id IS NULL AND through_movement_id IS NULL
                    AND through_wallet_entry_id IS NULL AND through_cash_entry_id IS NULL)
                OR (status = 'closed'
                    AND closed_at IS NOT NULL
                    AND closing_stock_cost IS NOT NULL AND closing_cash IS NOT NULL
                    AND sales_revenue IS NOT NULL AND cost_of_goods_sold IS NOT NULL
                    AND cost_damaged IS NOT NULL AND cost_short IS NOT NULL
                    AND expenses_amount IS NOT NULL AND net_profit IS NOT NULL
                    AND investors_pool IS NOT NULL AND company_share IS NOT NULL
                    AND through_consumption_id IS NOT NULL AND through_movement_id IS NOT NULL
                    AND through_wallet_entry_id IS NOT NULL AND through_cash_entry_id IS NOT NULL)
            )
        SQL);
    }
};
