<?php

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\CashEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * خزينةُ الصندوق — الدفترُ الذي يجيب «كم يملك الصندوق نقداً».
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ١أ، وجوابُ المالك
 * على س٤: «دفتر».
 *
 * **ولماذا يسبق النقدُ الفترةَ في الترتيب:** قسمةُ النسب عند حافّة كل فترة تقرأ قيمة الصندوق،
 * وأوّلُ بنودها نقدُه. فترةٌ تُفتح على قيمةٍ لا تعرف نقدَها تقسم النسب على رقمٍ ناقص، ولا يظهر
 * الخطأ في أي شاشة — يظهر في حصّة مستثمرٍ بعد سنة.
 *
 * ## ما كان قبل هذا الجدول
 *
 * **لا شيء.** لا خزينةَ في المخطّط كلّه ولا جدولَ حسابات، و`allocation` تنقل رأس المال من محفظة
 * المستثمر إلى صفقةٍ مباشرةً بلا مرورٍ بنقدٍ وسيط، وحصيلةُ البيع لا تعود إلى أحد. فـ«إعادة تدوير
 * أموال المبيعات في شراء بضاعة جديدة» — البند الذي يقوم عليه النظام المستمرّ — لم يكن له تمثيلٌ
 * واحد في قاعدة البيانات.
 *
 * ## النقدُ ليس القيمة
 *
 * الصندوق يعترف بالربح عند **التسليم** (جوابُ المالك على س٥)، والعميلُ يدفع بعد ذلك بأسابيع.
 * فـ{@see CashEntryType::SaleProceeds} مصدرُه **دفعةُ الطلبية لا
 * الطلبية**: الخزينة تتحرّك عند التحصيل، والمستحقُّ — ما سُلِّم ولم يُحصَّل — يدخل **قيمة**
 * الصندوق ولا يدخل نقدَه. فسقفُ الشراء وسقفُ السحب يقرآن النقد وحده، وقسمةُ النسب تقرأ القيمة
 * كاملة، ولا يُشترى بمالٍ لم يصل.
 *
 * ## لا عمود رصيد، ولا صفٌّ بلا مصدر
 *
 * الرصيدُ مشيُ الصفوف كما في كل دفترٍ في هذه الميزة، والتصحيحُ صفٌّ عكسيّ لا تعديلُ صفّ.
 * و`source_type`/`source_id` **إلزاميّان على كل نوعٍ إلا العكس**: كلُّ دينارٍ هنا أثرُ حدثٍ في
 * مكانٍ آخر، وصفٌّ بلا مصدرٍ نقدٌ لا يعرف أحدٌ من أين جاء ولا يُطابَق بورقة.
 *
 * **ولا مفاتيحَ أجنبية على المصدر**، لأنه يتعدّد: دفعةُ طلبية، وأمرُ شراء، وصفُّ محفظة، وصفُّ
 * مصروف، وصفُّ فترة. والقيمُ من خريطة التدقيق ({@see AuditSubject})
 * لا نصّاً حرّاً، فيحلّها التطبيق كما يحلّ كل موضوعٍ آخر.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_cash_entries', function (Blueprint $table) {
            $table->id();

            // ٣٠ لا ٢٠: `sale_proceeds` و`company_payout` و`capital_return` كلُّها أطول مما
            // يبدو، وقيمةٌ يستطيع الـ enum إنتاجها يجب أن تسع في العمود الذي يخزّنها.
            $table->string('type', 30);

            $table->decimal('amount', 14, 2);

            $table->string('source_type', 40)->nullable();
            $table->unsignedBigInteger('source_id')->nullable();

            // **أيُّ محاولةٍ على هذا المصدر هذا الصفّ.** التصحيح عكسٌ ثم صفٌّ جديد يسمّي المصدر
            // نفسه، فمفتاحٌ فريد لا يحمل هذا كان سيرفض كلَّ تصحيح ويترك الرقم الخاطئ وحده مقبولاً.
            $table->smallInteger('source_sequence')->default(1);

            // حين تحرّك المال، لا حين كتبه أحد — قاعدةُ `order_payments` نفسها.
            $table->timestamp('occurred_at');

            $table->text('notes')->nullable();

            $table->foreignId('reverses_entry_id')->nullable()
                ->constrained('investment_cash_entries')->nullOnDelete();

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['occurred_at', 'type']);
            $table->index(['source_type', 'source_id']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_cash_entries
            ADD CONSTRAINT investment_cash_entries_amount_positive CHECK (amount > 0)
        SQL);

        // ردَّان على صفٍّ واحد يضاعفان المال، وهو عطبٌ لا تلتقطه شاشة لأن الرصيد مشتقٌّ من الصفوف.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_cash_entries_reverses_entry_id_unique
            ON investment_cash_entries (reverses_entry_id)
            WHERE reverses_entry_id IS NOT NULL AND deleted_at IS NULL
        SQL);

        // «لا يُرحَّل الحدث الواحد مرّتين» — القانون نفسه الذي يحمله
        // `journal_entries (source_type, source_id, kind)` في مواصفة المحاسبة. دفعةُ طلبيةٍ
        // عولجت مرّتين كانت ستُدخل المال مرّتين، والفرقُ لا يظهر في أي مكان.
        //
        // **و`type` خارج المفتاح عن قصد**، كما في دفتر المحافظ: مصدرٌ واحد قد يُنتج نوعين
        // مشروعَين، والتسلسلُ هو ما يحمل التصحيح.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_cash_entries_one_posting_per_source
            ON investment_cash_entries (source_type, source_id, source_sequence)
            WHERE source_type IS NOT NULL AND deleted_at IS NULL
        SQL);

        // الشكلان اللذان يوجدان، مكتوبَين كفصلٍ بينهما فيقول كلٌّ منهما ما يسمح به.
        DB::statement(<<<'SQL'
            ALTER TABLE investment_cash_entries
            ADD CONSTRAINT investment_cash_entries_shape CHECK (
                (type IN ('deposit', 'purchase', 'expense', 'sale_proceeds',
                          'profit_payout', 'company_payout', 'capital_return')
                    AND source_type IS NOT NULL AND source_id IS NOT NULL
                    AND reverses_entry_id IS NULL)
                OR (type = 'reversal'
                    AND source_type IS NULL AND source_id IS NULL
                    AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_cash_entries');
    }
};
