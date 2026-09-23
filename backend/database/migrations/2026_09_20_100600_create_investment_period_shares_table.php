<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * نِسَبُ فترةٍ أُقفلت، مجمّدةً كما قُسِّم بها مالُها.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٣. وهو نصُّ ما طلبه
 * المالك: «كل مستثمرين ونسبة الربح الحالية ونسبتهم الحالية مربوطة بكل فترة».
 *
 * ## لماذا يُخزَّن ما يمكن حسابُه
 *
 * النسبةُ خارجُ قسمةٍ من دفتر الوحدات، ويمكن إعادةُ حسابها متى شئنا. لكن الفترةَ المغلقة **وُزّع
 * مالُها بهذه النسب** إلى جيوبِ ناسٍ لا يُستعاد منهم شيء — فلو أُعيد الحسابُ بعد سنةٍ بدفترٍ
 * تغيّر (صفٌّ عُكِس، وحداتٌ أُلغيت) لأظهرت الشاشةُ نسبةً غير التي قُبض بها. الرقمُ المجمَّد هو
 * الجوابُ الصادق على «بأيّ نسبةٍ قُسِّم سبتمبر؟»، وهو سؤالٌ غيرُ «بأيّ نسبةٍ يُقسَّم اليوم؟».
 *
 * وهو الانضباطُ نفسه الذي تمشي عليه أرقامُ `investment_periods` ومددُها.
 *
 * **ستُّ خاناتٍ لا اثنتان**: ثلاثون مستثمراً بأنصبةٍ متقاربة تفرّقها الخانةُ السادسة، وخانتان
 * كانتا ستجعل عشرةً منهم متساوين وهم ليسوا كذلك.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('investment_period_shares', function (Blueprint $table) {
            $table->id();

            $table->foreignId('investment_period_id')->constrained('investment_periods')->cascadeOnDelete();
            $table->foreignId('investor_id')->constrained('investors')->restrictOnDelete();

            $table->decimal('units', 20, 6);
            $table->decimal('share_percent', 9, 6);

            $table->timestamps();

            $table->unique(['investment_period_id', 'investor_id']);
        });

        DB::statement(<<<'SQL'
            ALTER TABLE investment_period_shares
            ADD CONSTRAINT investment_period_shares_positive
            CHECK (units > 0 AND share_percent > 0 AND share_percent <= 100)
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('investment_period_shares');
    }
};
