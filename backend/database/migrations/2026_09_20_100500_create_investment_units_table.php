<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * دفترُ الوحدات — كيف يملك مستثمرٌ حصةً في صندوقٍ حيّ.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٣، وهي جوابُ
 * البند ١٤.
 *
 * ## لماذا وحداتٌ ولا نسبةٌ تُكتب بيد
 *
 * السؤال: يدخل ثالثٌ بألفٍ ومئة إلى صندوقٍ فيه بضاعةٌ لم تُبَع. كم نسبتُه؟ لو كُتبت النسبةُ بيد
 * لوجب إعادةُ كتابة نسب الجميع في كل دخولٍ وكل خروج — وكلُّ إعادةٍ فرصةٌ لأن تصير مئةً وواحداً
 * أو تسعةً وتسعين، ولا شيء يمنعها.
 *
 * الوحدةُ تقلب السؤال: **يُشترى عددٌ بسعرٍ معلوم**، والنسبةُ خارجُ قسمةٍ لا رقمٌ يُخزَّن.
 *
 * ```
 * سعرُ الوحدة = قيمةُ الصندوق ÷ الوحدات القائمة
 * وحداتُه     = ما دفع ÷ سعر الوحدة
 * نسبتُه      = وحداتُه ÷ مجموع الوحدات
 * ```
 *
 * فمن يدخل صندوقاً قيمتُه ١٬٦٠٠ وفيه ١٬٠٠٠ وحدة يشتري الوحدةَ بـ١٫٦، ولا يقاسم أحداً ربحاً صُنع
 * قبله: هو اشترى **قيمةَ** البضاعة القائمة، وثمنُها الذي دفعه يعوّض من صنعها. وهذا نصُّ ما قاله
 * المالك: «يعتبر مالكها لاكن مش هاذي القطعة بالذات بل يملك قيمتها».
 *
 * ## وهو دفترٌ كبقيّة دفاتر هذا النظام
 *
 * `units` موجبٌ دائماً والاتجاهُ في النوع، والتصحيحُ صفٌّ عكسيّ لا تعديل، ولا عمودَ رصيد: «كم
 * يملك فلان» مشيُ صفوفه. الشكلُ نفسه الذي تمشي عليه `order_payments` و`investor_wallet_entries`.
 *
 * ## و`locked_until` على كل صفٍّ لا على المستثمر
 *
 * قرارُ المالك حرفياً: «كل deposit Timer خاص به لوحده ويجمد معه». فمن أودع مئةَ ألفٍ في يناير
 * ومئةً أخرى في يونيو يُفرَج عن الأولى في يناير التالي وعن الثانية في يونيو التالي — عمودٌ على
 * `investors` كان سيجعل الإيداعَ الثاني يمدّد حبسَ الأول.
 *
 * والمدةُ تُنسَخ لحظةَ الإصدار ولا تُقرأ من الإعدادات بعدها: من دخل على سنةٍ يخرج بعد سنة ولو
 * صارت المدةُ سنتين غداً — الانضباطُ نفسه الذي تمشي عليه مدد الفترة.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_units', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investor_id')->constrained('investors')->restrictOnDelete();

            // الفترةُ التي وقع فيها الإصدار. تقرّر — مع `occurred_at` — أيُّ فترةٍ تقاسمه، ولا
            // تُقرأ منها نسبةٌ مباشرة: ذاك عملُ {@see \App\Domain\Investor\Queries\PeriodShares}.
            $table->foreignId('investment_period_id')->nullable()
                ->constrained('investment_periods')->restrictOnDelete();

            $table->string('type', 20);

            // ستُّ خاناتٍ عشرية: صندوقٌ قيمتُه مليونٌ ووحدتُه بدينار يبيع وحدةً بجزءٍ من ألف،
            // وخانتان كانتا ستبتلعان الفرقَ وتُسقطانه من نصيب صاحبه.
            $table->decimal('units', 20, 6);
            $table->decimal('unit_price', 14, 6);

            // ما دُفع بالدينار — وهو `units × unit_price` مقرَّباً. يُخزَّن لأنه ما يراه الناس
            // في كشوفهم، ولأن استرجاعَه بالضرب يُخرج فلساً مختلفاً بعد كل تقريب.
            $table->decimal('amount', 14, 2);

            // إلى متى يُحبس رأسُ المال الذي اشترى هذه الوحدات. يُنسَخ لحظةَ الإصدار.
            $table->date('locked_until')->nullable();

            // صفُّ المحفظة الذي دفع ثمنها أو قبض ثمنها — فلا وحدةَ بلا مالٍ يقابلها.
            $table->string('source_type', 40)->nullable();
            $table->unsignedBigInteger('source_id')->nullable();

            $table->timestamp('occurred_at');
            $table->text('notes')->nullable();

            $table->foreignId('reverses_unit_entry_id')->nullable()
                ->constrained('investment_units')->nullOnDelete();

            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['investor_id', 'occurred_at']);
            $table->index(['investment_period_id', 'investor_id']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_units
            ADD CONSTRAINT investment_units_positive CHECK (units > 0 AND unit_price > 0 AND amount > 0)
        SQL);

        // عكسُ عكسٍ متاهةٌ بلا أرضية — القاعدةُ تمنعه، لا حارسٌ يتذكّره كاتب.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_units_reverses_unique
            ON investment_units (reverses_unit_entry_id)
            WHERE reverses_unit_entry_id IS NOT NULL AND deleted_at IS NULL
        SQL);

        // ووحدةٌ واحدة لكل صفّ محفظة: إيداعٌ واحد لا يشتري وحداتٍ مرّتين مهما تكرّر المستمع.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX investment_units_one_per_source
            ON investment_units (source_type, source_id)
            WHERE source_type IS NOT NULL AND deleted_at IS NULL
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE investment_units
            ADD CONSTRAINT investment_units_shape CHECK (
                (type = 'issue' AND reverses_unit_entry_id IS NULL AND source_type IS NOT NULL)
                OR (type = 'cancel' AND reverses_unit_entry_id IS NULL AND source_type IS NOT NULL
                    AND locked_until IS NULL)
                OR (type = 'reversal' AND reverses_unit_entry_id IS NOT NULL
                    AND locked_until IS NULL AND source_type IS NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_units');
    }
};
