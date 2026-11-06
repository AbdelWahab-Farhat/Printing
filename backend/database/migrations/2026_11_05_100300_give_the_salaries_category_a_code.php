<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * «رواتب» صار شيئاً يعتمد عليه الكود — EMPLOYEE-WALLET-DESIGN §٩ س٣.
 *
 * اختيارُ التصنيف يقترح راتب الموظف مبلغاً، فيُعرف التصنيف برمزه لا باسمٍ يُعاد كتابته — القاعدة
 * التي على `ExpenseCategory`. فإن كان صاحب العمل قد أعاد تسميته فلا يوجد صفٌّ بالاسم المزروع،
 * ويُضاف صفٌّ يحمل الرمز بدل أن تفشل الميزة بصمت.
 */
return new class extends Migration
{
    public function up(): void
    {
        $id = DB::table('treasury_expense_categories')
            ->where('name', 'رواتب')
            ->whereNull('code')
            ->whereNull('deleted_at')
            ->orderBy('id')
            ->value('id');

        if ($id !== null) {
            DB::table('treasury_expense_categories')->where('id', $id)->update([
                'code' => 'salary',
                'updated_at' => now(),
            ]);

            return;
        }

        DB::table('treasury_expense_categories')->insert([
            'name' => 'رواتب',
            'code' => 'salary',
            'requires_employee' => false,
            'is_active' => true,
            'sort_order' => 2,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        DB::table('treasury_expense_categories')->where('code', 'salary')->update(['code' => null]);
    }
};
