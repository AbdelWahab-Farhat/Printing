<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * تكلفةُ الوحدة قبل أن يرفعها مصروفٌ على البضاعة — Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٨.
 *
 * طلبُ المالك 2026-10-12: «توضيح تغيير تكلفة بضاعة من كم لكم بناء على مصروف». `unit_amount` يحمل
 * الفرق وحده؛ و«من كم» لا يُستنتج من `unit_cost` اليوم، فقد يرفعه مصروفٌ ثانٍ بعده. فيُكتب على صفّ
 * الرفّ لحظةَ الهبوط.
 *
 * **والصفوفُ القائمة تُملأ بأحسن ما يُعرف:** تكلفةُ الطبقة اليوم ناقصاً الفرق — صحيحةٌ ما لم يرفعها
 * مصروفٌ لاحق، وهو ما لم يقع بعد على أيّ خادم (الميزةُ لم تُنشر).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('fund_expense_charges', function (Blueprint $table) {
            $table->decimal('unit_cost_before', 12, 3)->nullable()->after('unit_amount');
        });

        DB::statement("UPDATE fund_expense_charges AS f
            SET unit_cost_before = b.unit_cost - f.unit_amount
            FROM stock_batches AS b
            WHERE b.id = f.stock_batch_id
              AND f.kind = 'shelf'
              AND f.reverses_charge_id IS NULL
              AND f.amount >= 0
              AND f.unit_amount IS NOT NULL
              AND b.unit_cost >= f.unit_amount");
    }

    public function down(): void
    {
        Schema::table('fund_expense_charges', function (Blueprint $table) {
            $table->dropColumn('unit_cost_before');
        });
    }
};
