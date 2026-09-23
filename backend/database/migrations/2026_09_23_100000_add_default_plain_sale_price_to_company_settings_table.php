<?php

use App\Domain\Investor\InvestorService;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * سعرُ السادة الافتراضي — ما تُملأ به حقولُ التمويل قبل أن يُكتب رقم.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٤.٣.
 *
 * ## الثقبُ الذي يسدّه
 *
 * `investor_deals.printing_sale_price` افتراضُ الصفقة: رفٌّ موّلته D1 بلا سعرٍ خاصّ يسقط على
 * سعرها ({@see InvestorService::dealForSupply()}). **وللصندوق لا صفّ
 * يحمل ذلك**، وعن قصد: صفقةٌ واحدةٌ لا تنتهي تشتري كلَّ مادةٍ بسعرٍ ووحدةٍ مختلفتين، فرقمٌ
 * واحدٌ عليها رقمٌ خاطئ عن أكثر ما تحمله.
 *
 * فبقي رفُّ الصندوق بلا افتراضٍ إطلاقاً: يُترك حقلُه فارغاً — ويُترك، لأن أحداً لا يحفظ السعر
 * عن ظهر قلب — فتمشي البضاعةُ إلى المطبعة **بالتكلفة**، ويعود المستثمرُ إلى الطريق القديم:
 * يشارك في ربح طلبية الطباعة كلِّها. وهو عكسُ ما وُضع سعرُ السادة له أصلاً: «نبي نفصل ربح طباعة
 * وربح لبضاعة».
 *
 * ## ولماذا هنا لا على الصندوق
 *
 * إعدادٌ يراه المالك ويغيّره من شاشة، لا عمودٌ على صفقةٍ «تُجمَّد شروطُها يوم مولدها». وهو
 * **افتراضٌ لا سعر**: يُملأ به المربعُ في شاشة التمويل فيُرى ويُغيَّر لكل رفّ، ثم يُجمَّد
 * المكتوبُ وحده على سطر التوريد. فتغييرُه غداً لا يمسّ ديناراً وُقِّع عليه أمس — الوعدُ نفسه
 * الذي تقطعه `investor_profit_share_percent` بجانبه.
 *
 * ## ووحدتُه الكيلو
 *
 * «حالياً في السادة نتعاملوا بالكيلو» — وفي الرفوف ما يُعدّ بالقطعة. فالرقمُ الواحد هنا سعرُ
 * كيلو، ولا تُملأ به إلا رفوفُ الكيلو؛ وما عداها يُفتح حقلُه فارغاً بدل أن يُكتب فيه سعرُ كيلو
 * على قطعة. وحين تتغيّر وحدةُ التعامل — أو يُطلب أن يصير الافتراضُ نسبةً فوق التكلفة — يُبنى
 * على هذا العمود لا حوله.
 *
 * ## ويُولد بـ٣٢ — القيمةُ التي تعمل بها الشركة اليوم
 *
 * «تقدر تكتبه مباشرة 32»، وهي نفسُها التي تحملها صفقةُ D1 على صفّها منذ إصلاحِ ١١ سبتمبر. وهذا
 * هو أسلوبُ هذا الجدول بعينه: `investor_profit_share_percent` تُولد بـ٥٠ والمددُ الأربع بقيمها،
 * كلُّها `->default()` في ترحيلها — والقيمةُ تسري على الصفّ القائم لأن إضافةَ عمودٍ بقيمةٍ
 * افتراضية تملؤها في الصفوف الموجودة.
 *
 * **ولا بذرةٌ تفعل ذلك.** صفُّ الإعدادات يُكتب في ترحيله لا في `DatabaseSeeder` — «a deploy that
 * ran migrations and skipped seeding still answers» — و`firstOrCreate` في بذرةٍ تجد الصفَّ
 * موجوداً فتتركه كما هو: تنشئ الناقص ولا تحدّث الموجود، فلن تكتب ٣٢ أبداً.
 *
 * ## وفارغٌ يبقى جواباً — لا «صفر»
 *
 * من رفع الرقمَ من شاشة الإعدادات اختار «بلا افتراض»: تُفتح حقولُ التمويل خاليةً فتمشي البضاعةُ
 * بالتكلفة. والصفرُ ليس ذلك — سعرٌ يسلّم المطبعةَ البضاعةَ بلا ثمن — فالقيدُ يرفضه كما يرفضه
 * أخواه على `investor_deals` و`stock_batches`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_settings', function (Blueprint $table) {
            // ثلاث خانات عشرية كسعر السادة أينما كُتب — السعرُ هنا ينسخ نفسه إلى هناك حرفاً.
            // و`nullable` مع قيمةٍ افتراضية معاً: يُولد بـ٣٢ ويُرفَع متى أراد صاحبُه.
            $table->decimal('default_plain_sale_price', 12, 3)->nullable()->default('32.000');
        });

        DB::statement(<<<'SQL'
            ALTER TABLE company_settings
            ADD CONSTRAINT company_settings_default_plain_sale_price_positive
            CHECK (default_plain_sale_price IS NULL OR default_plain_sale_price > 0)
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE company_settings DROP CONSTRAINT IF EXISTS company_settings_default_plain_sale_price_positive');

        Schema::table('company_settings', function (Blueprint $table) {
            $table->dropColumn('default_plain_sale_price');
        });
    }
};
