<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «إعادة استثمار الأرباح تلقائياً» — زرٌّ لكلّ مستثمر. التصميم في
 * Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md §١٤.
 *
 * **مُطفأ للجميع** — قرارُ المالك: لا يتحرّك مالُ أحدٍ إلا وقد اختاره إنسان.
 *
 * و`auto_reinvest_since` يُختم لحظةَ التشغيل ويُمسح عند الإطفاء. لا يقرؤه الكنسُ اليوم — يُعيد كلَّ
 * المتاح — لكنه يجعل «ما أُفرِج عنه بعد التشغيل وحده» تغييرَ استعلامٍ لا ترحيلاً، وتقرؤه الشاشة.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investors', function (Blueprint $table) {
            $table->boolean('auto_reinvest_profit')->default(false)->after('is_active');
            $table->timestamp('auto_reinvest_since')->nullable()->after('auto_reinvest_profit');
        });
    }

    public function down(): void
    {
        Schema::table('investors', function (Blueprint $table) {
            $table->dropColumn(['auto_reinvest_profit', 'auto_reinvest_since']);
        });
    }
};
