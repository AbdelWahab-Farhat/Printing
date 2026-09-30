<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * أين وصل العميل في قراءة ملاحظات طلبيته: آخر انتقالٍ رآه على شاشة «الملاحظات».
 *
 * **مؤشّرٌ لا جدول قراءات**، كـ`customer_read_message_id` في تذاكر الدعم: الملاحظات تُكتب
 * بترتيبها ولا تُعدَّل، فرقمُ آخر ما قُرئ يكفي ليعدّ ما بعده. وبلا مفتاحٍ أجنبي للسبب نفسه هناك:
 * هو علامةٌ على خيطٍ مرتّب، لا علاقةٌ يُسأل عنها.
 *
 * فارغٌ على كل طلبيةٍ قائمة، ولا يُملأ شيء: ما كُتب قبل اليوم لم يقرأه العميل بعد، وشارته صادقة.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->unsignedBigInteger('customer_read_transition_id')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('customer_read_transition_id');
        });
    }
};
