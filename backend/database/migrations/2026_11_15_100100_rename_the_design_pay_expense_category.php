<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * «أجر التصميم» becomes «أجرة المصمم», so it cannot be read as the customer's «أجرة التصميم».
 * See Docs/orders/ORDER-DESIGN-FEE.md.
 *
 * The category names the designer's wallet line and the expense, so the rename reaches both.
 * Only while it still carries the seeded name: a name the owner chose is theirs.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::table('treasury_expense_categories')
            ->where('code', 'design_pay')
            ->where('name', 'أجر التصميم')
            ->update(['name' => 'أجرة المصمم', 'updated_at' => now()]);
    }

    public function down(): void
    {
        DB::table('treasury_expense_categories')
            ->where('code', 'design_pay')
            ->where('name', 'أجرة المصمم')
            ->update(['name' => 'أجر التصميم', 'updated_at' => now()]);
    }
};
