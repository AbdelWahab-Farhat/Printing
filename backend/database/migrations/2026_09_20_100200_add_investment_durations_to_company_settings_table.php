<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * المدد الأربع التي يحكم بها الصندوقُ المستمرّ نفسَه.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ١ب، وجوابُ المالك:
 * «مدة الفترة حتى يتم التسكير التلقائي»، و«يمكنه فقط في بداية الفترة — أول أسبوع أو أول يوم،
 * مدة يحددها المدير من الإعدادات»، و«مدة حجز رأس المال بعد دخوله تبقى سنة كاملة وهي نسبة متغيرة».
 *
 * **أعمدةٌ مكتوبة لا مفاتيح وقيم**، على سُنّة `investor_profit_share_percent` بجانبها: أربعُ
 * إعداداتٍ لا تبرّر عموداً بلا نوعٍ وجدولَ تحويلٍ خلفه، والعمودُ المكتوب تفحصه القاعدة نفسُها —
 * وهو ما تفعله الثلاثةُ قيودٌ أدناه.
 *
 * ## والوعدُ الذي تحمله: تغييرُها لا يمسّ ما مضى
 *
 * هذا هو الوعدُ نفسه الذي تقطعه النسبة بجانبها، ويُوفَّى بالطريقة نفسها: **القيمة تُنسَخ على صفّ
 * الفترة يوم تُفتح** ولا تُقرأ من هنا بعدها. فمن أقفل سبتمبر على شهرٍ واحد يبقى شهراً واحداً ولو
 * صارت المدةُ شهرين في أكتوبر. والنسخُ يقع **عند إنشاء صفّ الفترة** لا عند فتحه، وإلا وُجدت نافذةٌ
 * بين الاثنين يتغيّر فيها الإعداد.
 *
 * ## ولماذا قيودٌ في القاعدة وليس تحقُّقاً في الطلب وحده
 *
 * - **التسويةُ مضاعفٌ صحيح للفترة.** تسويةٌ كلَّ ٤ أشهر فوق فتراتٍ كلَّ ٣ تقطع الثانية في
 *   منتصفها، فتُقوَّم بضاعةٌ لم يُغلق حسابُها ويُعتمد رقمٌ نصفُه معلَّق. **وهذا افتراضٌ طبّقتُه
 *   ولم يُسأل عنه صراحةً** — إسقاطُه سطرٌ واحد إن أراده المالك مفتوحاً.
 * - **النافذةُ لا تبتلع الفترة.** ٢٨ حدٌّ أعلى مطلق لأنه أقصرُ شهرٍ ممكن: نافذةٌ أطول منه تجعل
 *   «أولَ الفترة» هو الفترةَ كلَّها، فيسقط معنى الاحتجاز الذي وُضعت من أجله.
 * - **ولا فترةَ بصفر شهر.** قسمةٌ على صفرٍ في كل حسابِ موعدٍ قادم.
 *
 * **وحجزُ رأس المال يقبل الصفر** وحده من بينها: صندوقٌ بلا حجزٍ خيارٌ مشروع، والصفرُ يقوله
 * صراحةً بدل أن يُقال بشهرٍ واحدٍ يُقارب المعنى.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            // مدة الفترة المحاسبية — عليها يقع إقفال الأرباح، وشهرٌ هو ما تعمل به الشركة اليوم.
            $table->smallInteger('investment_period_months')->default(1);

            // أوّلُ الفترة الذي يُقبَل فيه الإيداع. ما يصل بعده يُحتجز إلى الفترة التالية ولا
            // يُنفَق — «لا يُحسب كربح ولا يُحسب كنسبة إلا بداية الشهر الجاي».
            $table->smallInteger('investment_subscription_window_days')->default(7);

            // المراجعةُ الشاملة، ودورتُها أطول من دورة الأرباح ومستقلّةٌ عنها في المعنى.
            $table->smallInteger('investment_settlement_months')->default(6);

            // لا يُسحب رأسُ مالٍ قبل انقضائها، **ولكلّ إيداعٍ ساعتُه** — تُجمَّد على صفّ الإيداع
            // يوم وصوله، فخفضُ هذا الرقم غداً لا يُفرِج عن مالٍ التُزم به سنة، ورفعُه لا يحبس
            // مالاً وُعد صاحبُه بردّه. وسحبُ الأرباح مفتوحٌ طوال ذلك.
            $table->smallInteger('investment_capital_lock_months')->default(12);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_investment_durations_sane CHECK (
                investment_period_months BETWEEN 1 AND 12
                AND investment_subscription_window_days BETWEEN 1 AND 28
                AND investment_settlement_months BETWEEN 1 AND 36
                AND investment_capital_lock_months BETWEEN 0 AND 120
            )
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_settlement_spans_whole_periods
            CHECK (investment_settlement_months % investment_period_months = 0)
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT company_settings_settlement_spans_whole_periods');
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT company_settings_investment_durations_sane');

        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn([
                'investment_period_months',
                'investment_subscription_window_days',
                'investment_settlement_months',
                'investment_capital_lock_months',
            ]);
        });
    }
};
