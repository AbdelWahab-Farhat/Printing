<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * تصنيف «أجر التصميم» — به يُكتب الأجر مصروفاً، وبه يُعنون سطر المحفظة. SERVICE-PAY-DESIGN §٤.
 *
 * يُعرف برمزه، ويحمله صفٌّ بالاسم نفسه إن كان صاحب العمل قد أضافه، حتى لا يصبح في القائمة تصنيفان.
 */
return new class extends Migration
{
    public function up(): void
    {
        $id = DB::table('treasury_expense_categories')
            ->where('name', 'أجر التصميم')
            ->whereNull('code')
            ->whereNull('deleted_at')
            ->orderBy('id')
            ->value('id');

        if ($id !== null) {
            DB::table('treasury_expense_categories')->where('id', $id)->update([
                'code' => 'design_pay',
                'updated_at' => now(),
            ]);

            return;
        }

        DB::table('treasury_expense_categories')->insert([
            'name' => 'أجر التصميم',
            'code' => 'design_pay',
            'requires_employee' => false,
            'is_active' => true,
            'sort_order' => 3,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        DB::table('treasury_expense_categories')->where('code', 'design_pay')->delete();
    }
};
