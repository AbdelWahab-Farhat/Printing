<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «أجر التصميم» — ما يدخل محفظة المصمم عند الاعتماد. Docs/employees/SERVICE-PAY-DESIGN.md §٣.
 *
 * **ليس `orders.design_fee`**: ذاك ما يدفعه الزبون، وهذا ما يتقاضاه المصمم، ولا رابط بينهما.
 *
 * `NULL` لم يُكتب أجر، والتذكرة تكتمل بلا مال.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('design_tickets', function (Blueprint $table) {
            $table->decimal('designer_pay', 12, 2)->nullable();
        });

        DB::statement(<<<'SQL'
            ALTER TABLE design_tickets
            ADD CONSTRAINT design_tickets_designer_pay_not_negative CHECK (designer_pay >= 0)
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE design_tickets DROP CONSTRAINT design_tickets_designer_pay_not_negative');

        Schema::table('design_tickets', function (Blueprint $table) {
            $table->dropColumn('designer_pay');
        });
    }
};
