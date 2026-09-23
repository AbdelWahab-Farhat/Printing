<?php

use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Support\FundDeal;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * سعرُ السادة ينزل من الصفقة إلى السطر — ليصير للصندوق سعرٌ لكل مادة.
 *
 * العمودُ على `investor_deals` كان يكفي حين كانت الصفقةُ لورياً واحداً: مادةٌ أو مادّتان،
 * وسعرٌ واحدٌ يمشي عليها. والصندوقُ صفقةٌ **واحدةٌ أبداً** ({@see FundDeal})،
 * فعمودٌ عليه يعني سعراً واحداً لكل مادةٍ يملكها الصندوقُ ما دام — الورقُ والحبرُ بالرقم نفسه،
 * وأولُ تغييرٍ في سعرِ مادةٍ يعيد تسعيرَ الباقي معها.
 *
 * فالسعرُ ينزل إلى **صفّ التوريد**: سطرُ أمرِ الشراء لهذه المادة. وهو الموضعُ الصحيح لأنه
 * الموضعُ الذي تُتَّخذ فيه القرارات الأخرى كلُّها عن هذه البضاعة بعينها — من يموّلها، ومن أيّ
 * أمرٍ جاءت — و`ReceivePurchaseOrder` يسأل عنه سؤالاً واحداً لكل سطرٍ عند الاستلام.
 *
 * **والقديمُ لا يتحرّك.** العمودُ على الصفقة يبقى ويبقى مقروءاً: صفقاتُ ما قبل الصندوق مسعَّرةٌ
 * به، وصفوفُ توريدها لا تحمل شيئاً، فتقرأ {@see InvestorService::dealForSupply()}
 * السطرَ أولاً ثم تسقط إلى الصفقة. سعرٌ على السطر يعلو سعرَ صفقته، ولا صفقةَ قديمةٌ فيها سطرٌ
 * مسعَّر.
 *
 * ثلاثُ خاناتٍ عشرية، كالعمود الذي جاء منه: سعرُ الكيلو رقمٌ يكتبه إنسان — «32.500».
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('investor_deal_supplies', function (Blueprint $table) {
            $table->decimal('printing_sale_price', 12, 3)->nullable()->after('stock_item_id');
        });

        // الصفرُ ليس «مجّاناً»، بل «لم يقل أحدٌ شيئاً» — وذاك مكتوبٌ NULL. وسعرُ صفرٍ يسلّم
        // المطبعةَ البضاعةَ بلا ثمنٍ ويكتب على المستثمر خسارةَ تكلفتها كاملة. نفسُ الحارس على
        // `investor_deals.printing_sale_price`، وللسبب نفسه.
        DB::statement(<<<'SQL'
            ALTER TABLE investor_deal_supplies
            ADD CONSTRAINT investor_deal_supplies_printing_sale_price_positive
            CHECK (printing_sale_price IS NULL OR printing_sale_price > 0)
        SQL);
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE investor_deal_supplies DROP CONSTRAINT IF EXISTS investor_deal_supplies_printing_sale_price_positive');

        Schema::table('investor_deal_supplies', function (Blueprint $table) {
            $table->dropColumn('printing_sale_price');
        });
    }
};
