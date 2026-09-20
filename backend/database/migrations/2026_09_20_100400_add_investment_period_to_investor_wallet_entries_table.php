<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الزمنُ يدخل الدفتر: كلُّ صفٍّ يقول لأيّ فترةٍ هو.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٢.
 *
 * ## الثقبُ الذي يسدّه هذا العمود
 *
 * `CloseInvestmentPeriod` كان يُفرج عن **كلّ** ربحٍ موجبٍ في الدفتر بلا سؤالٍ عن فترته — والدفترُ
 * لم يكن يعرف الجواب أصلاً. فإقفالُ سبتمبر في ١٥ أكتوبر كان يسلّم حَمَلةَ سبتمبر ربحَ طلبيةٍ من
 * أكتوبر سُلِّمت في الخامس. لا يظهر في شيء: كلُّ رصيدٍ هنا مشيُ صفوفٍ لا عمودٌ يُقارَن به.
 *
 * ## ولماذا يقبل `NULL`
 *
 * طلبيةُ الخامس من أكتوبر تُسلَّم وسبتمبر ما زال مفتوحاً ينتظر آخرَ طلبياته — **ولا فترةَ تسع
 * يومَها بعد**. فتُكتب بلا ختم، ويلتقطها إقفالُ أكتوبر بنافذته. وصفوفُ الصفقات القديمة، التي
 * وقعت قبل أن يُولد الصندوق، تبقى بلا ختمٍ أبداً — لا فترةَ تسعها، ولا إقفالَ فترةٍ يُفرج عنها؛
 * بابُها `CloseInvestorDeal` كما كان.
 *
 * فـ`NOT NULL` هنا كان سيمنع تسليمَ طلبيةٍ لأن المحاسبةَ لم تفتح فترةً بعد — والمحلُّ لا يقف
 * لأن دفتراً ينتظر.
 *
 * ## و`restrictOnDelete` لا `nullOnDelete`
 *
 * فترةٌ تُحذف وتترك صفوفَها بلا ختم هي بالضبط تسريبُ الأرباح الذي يمنعه هذا العمود، ويحدث في
 * صمت. الصفُّ يمنع حذفَها، والفترةُ المغلقة لا تُحذف أصلاً.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_wallet_entries', function (Blueprint $table) {
            $table->foreignId('investment_period_id')->nullable()->after('investor_deal_id')
                ->constrained('investment_periods')->restrictOnDelete();
        });

        // ما تقرؤه التسويةُ عند الإقفال: صفوفُ فترةٍ بعينها لكل مستثمر.
        DB::statement(<<<'SQL'
            CREATE INDEX investor_wallet_entries_period_investor
            ON investor_wallet_entries (investment_period_id, investor_id)
            WHERE deleted_at IS NULL
        SQL);

        // وما تقرؤه المطالبة: الصفوفُ التي لم تُنسب بعدُ إلى فترة. فهرسٌ جزئيّ صغير مهما كبر
        // الدفتر، لأن المنسوبَ هو السواد الأعظم منه.
        DB::statement(<<<'SQL'
            CREATE INDEX investor_wallet_entries_unstamped
            ON investor_wallet_entries (occurred_at)
            WHERE investment_period_id IS NULL AND deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS investor_wallet_entries_unstamped');
        DB::statement('DROP INDEX IF EXISTS investor_wallet_entries_period_investor');

        Schema::table('investor_wallet_entries', function (Blueprint $table) {
            $table->dropConstrainedForeignId('investment_period_id');
        });
    }
};
