<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الفترةُ المحاسبية — وهي ما يحلّ محلّ «صفقة #001 → #002 → #003».
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ١ج.
 *
 * **الذي يتكرّر صار الفترةَ لا الصفقة.** البضاعةُ ورأسُ المال يستمرّان عبرها بلا تصفيةٍ ولا
 * تصفير، والذي يُغلق دورياً هو الربحُ وحده.
 *
 * ## الجدولُ الوحيد هنا الذي يخزّن أرقاماً — وذلك مقصود
 *
 * قاعدةُ هذا المشروع «الرصيد لا يُخزَّن» صحيحةٌ للأرصدة الحيّة و**خاطئةٌ للفترة المغلقة**. فترةٌ
 * تُحسب عند كل قراءة تتحرّك تحت قدمها: مصروفٌ مؤرَّخٌ للماضي يُدخَل اليوم، تسويةُ هالكٍ تُسجَّل
 * غداً، طلبيةٌ تُحذف بعد شهر — فيعطي السؤالُ نفسُه عن الشهر نفسِه جواباً مختلفاً كلَّ مرّة. وهذا
 * ما لا يُدافَع عنه أمام مستثمرٍ وُقِّع له على رقم.
 *
 * **والعلاماتُ المائية (`through_*`) هي الحدُّ الأعلى الصريح** الذي دخل في الحساب: أقصى معرّفٍ
 * في الاستهلاكات والحركات ودفتر المحافظ والخزينة. بعدها لا يُعاد الاستعلام عن فترةٍ مغلقة أبداً،
 * ويصير «حتى أين حُسبت؟» سؤالاً له جوابٌ مكتوب بدل أن يكون استنتاجاً من تواريخ.
 *
 * ## والمدد تُنسَخ لا تُقرأ
 *
 * `period_months` و`subscription_window_days` و`investor_profit_share_percent` تُنسَخ من
 * `company_settings` **يوم يُنشأ هذا الصفّ**، ولا تُقرأ من هناك بعدها — فمن أُقفل على شهرٍ واحد
 * يبقى شهراً واحداً ولو صارت المدةُ شهرين غداً. وهو الوعدُ الذي قطعه المالك: «تغيير الإعدادات
 * يؤثّر على الفترات المستقبلية ولا يعيد تغيير ما سبق إغلاقه».
 *
 * ## القيود، وكلُّها تمنع خطأً لا يُرى في شاشة
 *
 * - **فترةٌ مفتوحةٌ واحدة لا غير.** فترتان مفتوحتان تعنيان أن ربح الطلبية يقع في أيّهما صادفت
 *   الاستعلام، والفرقُ مالُ مستثمر.
 * - **لا تتداخل نافذتان** (`EXCLUDE ... daterange &&`). يومٌ واحد في فترتين يُحسب مرّتين أو لا
 *   يُحسب، والمجموعُ يبقى «صحيحاً» في الحالتين. وهذا أصدقُ ما تستطيع القاعدةُ قولَه عن الزمن.
 * - **المغلقةُ تحمل أرقامها كلَّها، والمفتوحةُ لا تحمل منها شيئاً.** «مغلقة» بلا صافي ربح حالةٌ
 *   تكذب على قارئها، ورقمٌ مجمَّدٌ على فترةٍ ما زالت تستقبل رقمٌ سيتغيّر ولا يعلم قارئُه.
 *
 * **و`override_reason` هو بابُ الطلبية العالقة.** فترةٌ لا تُقفَل حتى تُسلَّم آخرُ طلبياتها، وطلبيةٌ
 * واحدة لا تُسلَّم ولا تُلغى تحبسها إلى الأبد ومعها أرباحُ كلّ مستثمريها. فإن قُفِلت متجاوِزةً،
 * كُتب هنا **من فعلها ولماذا** — لا علمٌ صامت.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_periods', function (Blueprint $table) {
            $table->id();

            // «P7» — التخصيص نفسه الذي يمشي عليه رقم الطلبية ورمز الصفقة.
            $table->string('code', 12);

            $table->string('status', 20)->default('open');

            // نافذةُ الفترة الاقتصادية: أيُّ طلبيةٍ يقع `placed_at` فيها فهي لها — ولو سُلِّمت
            // بعدها بشهر. ولذلك تبقى الفترةُ مفتوحةً للقيد بعد `ends_on` حتى تُسلَّم آخرُ
            // طلبياتها، ويفترق `ends_on` عن `closed_at` بأيامٍ عن قصد.
            $table->date('starts_on');
            $table->date('ends_on');

            // آخرُ يومٍ يُقبَل فيه إيداعُ رأس مال. ما يصل بعده يُحتجز إلى الفترة التالية ولا
            // يُنفَق. يُحسب مرّةً يوم الإنشاء ويُكتب، فلا يتحرّك بتحرّك الإعداد.
            $table->date('subscription_closes_on');

            // ── منسوخاتُ الإعدادات، تُجمَّد يوم الإنشاء ───────────────────────────────────
            $table->smallInteger('period_months');
            $table->smallInteger('subscription_window_days');
            $table->decimal('investor_profit_share_percent', 5, 2);

            // ── الرصيد الافتتاحي: إقفالُ ما قبلها، بالتكلفة ───────────────────────────────
            $table->decimal('opening_stock_cost', 14, 2)->default('0.00');
            $table->decimal('opening_cash', 14, 2)->default('0.00');

            // ── ما يكتبه الإقفال، ولا شيء منه قبله ────────────────────────────────────────
            $table->decimal('closing_stock_cost', 14, 2)->nullable();
            $table->decimal('closing_cash', 14, 2)->nullable();
            $table->decimal('sales_revenue', 14, 2)->nullable();
            $table->decimal('cost_of_goods_sold', 14, 2)->nullable();
            $table->decimal('cost_damaged', 14, 2)->nullable();
            $table->decimal('cost_short', 14, 2)->nullable();
            $table->decimal('expenses_amount', 14, 2)->nullable();
            $table->decimal('net_profit', 14, 2)->nullable();
            $table->decimal('investors_pool', 14, 2)->nullable();
            $table->decimal('company_share', 14, 2)->nullable();

            // العلاماتُ المائية — «حتى أين حُسبت هذه الفترة».
            $table->unsignedBigInteger('through_consumption_id')->nullable();
            $table->unsignedBigInteger('through_movement_id')->nullable();
            $table->unsignedBigInteger('through_wallet_entry_id')->nullable();
            $table->unsignedBigInteger('through_cash_entry_id')->nullable();

            $table->timestamp('closed_at')->nullable();
            $table->foreignId('closed_by')->nullable()->constrained('users')->nullOnDelete();

            // بابُ الطلبية العالقة — ومن فتحه.
            $table->string('override_reason', 500)->nullable();
            $table->foreignId('overridden_by')->nullable()->constrained('users')->nullOnDelete();

            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();

            $table->text('notes')->nullable();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['status', 'starts_on']);
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_periods_code_unique ON investment_periods (code)
            WHERE deleted_at IS NULL
        SQL);

        // **فترةٌ مفتوحةٌ واحدة، حقيقةً في القاعدة لا عرفاً في فعل.**
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_periods_one_open_at_a_time
            ON investment_periods ((status))
            WHERE status = 'open' AND deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_window_is_forward CHECK (ends_on >= starts_on)
        SQL);

        // نافذةُ الاكتتاب داخل فترتها: تبدأ معها ولا تتجاوز نهايتها.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_subscription_inside_window CHECK (
                subscription_closes_on >= starts_on AND subscription_closes_on <= ends_on
            )
        SQL);

        // **لا يومَ في فترتين.** الاستثناءُ على المدى نفسه لا على طرفيه، فيقول ما يعنيه بالضبط.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_windows_never_overlap
            EXCLUDE USING gist (daterange(starts_on, ends_on, '[]') WITH &&)
            WHERE (deleted_at IS NULL)
        SQL);

        // المغلقةُ تحمل أرقامها كلَّها، والمفتوحةُ لا تحمل منها شيئاً.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_periods
            ADD CONSTRAINT investment_periods_shape CHECK (
                (status = 'open'
                    AND closed_at IS NULL AND closed_by IS NULL
                    AND closing_stock_cost IS NULL AND closing_cash IS NULL
                    AND sales_revenue IS NULL AND cost_of_goods_sold IS NULL
                    AND cost_damaged IS NULL AND cost_short IS NULL
                    AND expenses_amount IS NULL AND net_profit IS NULL
                    AND investors_pool IS NULL AND company_share IS NULL
                    AND through_consumption_id IS NULL AND through_movement_id IS NULL
                    AND through_wallet_entry_id IS NULL AND through_cash_entry_id IS NULL)
                OR (status = 'closed'
                    AND closed_at IS NOT NULL
                    AND closing_stock_cost IS NOT NULL AND closing_cash IS NOT NULL
                    AND sales_revenue IS NOT NULL AND cost_of_goods_sold IS NOT NULL
                    AND cost_damaged IS NOT NULL AND cost_short IS NOT NULL
                    AND expenses_amount IS NOT NULL AND net_profit IS NOT NULL
                    AND investors_pool IS NOT NULL AND company_share IS NOT NULL
                    AND through_consumption_id IS NOT NULL AND through_movement_id IS NOT NULL
                    AND through_wallet_entry_id IS NOT NULL AND through_cash_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_periods');
    }
};
