<?php

use App\Domain\Investor\Actions\DepositToFund;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * المدّتان الباقيتان على صفّ الفترة، ورايةُ «هذه تُغلق دورةَ تسوية».
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٦ (البندان ٩ و١١).
 *
 * ## لماذا تُنسَخ مدّةٌ تُقرأ من الإعدادات
 *
 * `investment_periods` كان ينسخ مدّةَ الفترة ونافذةَ الاكتتاب ونسبةَ الأرباح، ويترك مدّةَ
 * التسوية وحبسِ رأس المال تُقرآن حيّتين. وهذا ثقبٌ في الانضباط نفسِه الذي بُني عليه الجدول:
 * رجلٌ دخل على حبسِ سنة يجب أن يخرج بعد سنة، ولو صارت المدةُ سنتين في الشهر التالي.
 *
 * `capital_lock_months` هنا هو ما تنسخه {@see DepositToFund} على
 * صفّ وحداته — فالسلسلةُ كاملةٌ من الإعداد إلى الفترة إلى الدفعة، وكلُّ حلقةٍ تجمّد ما قبلها.
 *
 * ## ورايةُ دورة التسوية
 *
 * «التسويةُ دورةٌ منفصلة عن الفترة»: الفترةُ شهرٌ يُرحَّل فيه الربح، والتسويةُ ستةُ أشهرٍ تُقفَل
 * عندها الحسابات. والقيدُ القائم `settlement % period = 0` يجعل الدورةَ تنتهي دائماً على حافّة
 * فترة، فالرايةُ تُحسب عدّاً لا تُقدَّر بتاريخ.
 *
 * **وتُكتب يوم الفتح لا يوم الإقفال**، لأن من يفتح فترةً يحتاج أن يعرف أهي التي سيُصفّى فيها
 * الحساب — وتغييرُ المدة في منتصفها لا يقلب جواباً أُعلن.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investment_periods', function (Blueprint $table) {
            $table->smallInteger('settlement_months')->default(6)->after('subscription_window_days');
            $table->smallInteger('capital_lock_months')->default(12)->after('settlement_months');
            $table->boolean('ends_settlement_cycle')->default(false)->after('capital_lock_months');
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_settlement_sane CHECK (
                settlement_months > 0 AND capital_lock_months > 0
                AND settlement_months % period_months = 0
            )
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE investment_periods DROP CONSTRAINT IF EXISTS investment_periods_settlement_sane');

        Schema::table('investment_periods', function (Blueprint $table) {
            $table->dropColumn(['settlement_months', 'capital_lock_months', 'ends_settlement_cycle']);
        });
    }
};
