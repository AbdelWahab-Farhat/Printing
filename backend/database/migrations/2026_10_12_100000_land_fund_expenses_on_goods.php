<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * مصروفُ الصندوق على البضاعة — Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md.
 *
 * - **`investor_deal_expenses.purchase_order_id`** — طلبُ الشراء الذي يخصّه المصروف. فارغٌ في كل
 *   صفٍّ قبل اليوم (القرار ٧: القديمُ يبقى كما هو)، وفي كل مصروف فترة.
 * - **`.landed_through_consumption_id`** — آخرُ استهلاكٍ وُجد لحظةَ الهبوط: ما قبله حُمِّل لمستهلكه
 *   صفّاً، وما بعده حمل الفرقَ في تكلفته — والعكسُ يحتاج أن يفرّق بينهما.
 * - **`stock_movements.purchased_layers_to_company`** — عكسٌ أعطى الشركةَ ما اشترته المطبعةُ من رفٍّ
 *   مسعَّر بدل أن يردّه إلى طبقته. كان يُمرَّر إلى `creditBack()` ثم يضيع؛ وبدونه لا يُعرف أنّ تلك
 *   الأكياس ما زالت مَبيعة.
 * - **`fund_expense_charges`** — كلُّ جزءٍ من المصروف: ما رفع تكلفةَ طبقة، وما كُتب على مستهلك.
 *   إضافيٌّ كلُّه، ولا يمسّ بياناً قائماً.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_deal_expenses', function (Blueprint $table) {
            $table->foreignId('purchase_order_id')->nullable()->after('source_id')
                ->constrained('purchase_orders');
            $table->unsignedBigInteger('landed_through_consumption_id')->nullable()->after('purchase_order_id');
        });

        Schema::table('stock_movements', function (Blueprint $table) {
            $table->boolean('purchased_layers_to_company')->default(false)->after('reverses_movement_id');
        });

        Schema::create('fund_expense_charges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('investor_deal_expense_id')->constrained('investor_deal_expenses');
            // shelf · consumer · rounding — انظر FundExpenseChargeKind.
            $table->string('kind', 20);
            $table->foreignId('stock_batch_id')->nullable()->constrained('stock_batches');
            $table->foreignId('stock_movement_id')->nullable()->constrained('stock_movements');
            $table->foreignId('order_id')->nullable()->constrained('orders');
            $table->decimal('quantity', 12, 3)->default(0);
            // الفرقُ في تكلفة الوحدة — لصفوف الرفّ وحدها.
            $table->decimal('unit_amount', 12, 3)->nullable();
            // موجبٌ ما حُمِّل، وسالبٌ ما رُدّ — المجموعُ يساوي المصروفَ بقرشه.
            $table->decimal('amount', 14, 2);
            $table->date('charged_on');
            $table->foreignId('investment_period_id')->nullable()->constrained('investment_periods');
            $table->foreignId('reverses_charge_id')->nullable()->constrained('fund_expense_charges');
            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['stock_movement_id', 'stock_batch_id']);
        });

        DB::statement("ALTER TABLE fund_expense_charges
            ADD CONSTRAINT fund_expense_charges_kind_known
            CHECK (kind IN ('shelf', 'consumer', 'rounding'))");
        DB::statement('ALTER TABLE fund_expense_charges
            ADD CONSTRAINT fund_expense_charges_quantity_not_negative CHECK (quantity >= 0)');
        // عكسٌ واحدٌ لكل صفّ — كما في كل دفترٍ هنا.
        DB::statement('CREATE UNIQUE INDEX fund_expense_charges_one_reversal
            ON fund_expense_charges (reverses_charge_id)
            WHERE reverses_charge_id IS NOT NULL AND deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('fund_expense_charges');

        Schema::table('stock_movements', function (Blueprint $table) {
            $table->dropColumn('purchased_layers_to_company');
        });

        Schema::table('investor_deal_expenses', function (Blueprint $table) {
            $table->dropConstrainedForeignId('purchase_order_id');
            $table->dropColumn('landed_through_consumption_id');
        });
    }
};
