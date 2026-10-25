<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * علامةُ القراءة بجانب «رد» في بطاقة الرئيسية — طلبُ المالك ٢٠٢٦-١٠-٢٥: «قرأتُها ولا ردّ عندي».
 *
 * **مؤشّرٌ لكل طرف، برقم آخر رسالةٍ عُلّمت**، كمؤشّرَي القراءة بجانبهما — لا علمٌ «أُخفيت». فرسالةٌ
 * جديدة من الزميل رقمُها أكبر من المؤشّر، فتعود التذكرةُ إلى البطاقة بلا كتابةٍ تمحو شيئاً.
 *
 * عمودان فارغان يُضافان، بلا قيمةٍ افتراضية ولا فهرس: الجدولُ عشراتُ الصفوف، ولا يُبحث بهما.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('internal_tickets', function (Blueprint $table) {
            // `null` = لم يعلّمها هذا الطرف قط.
            $table->unsignedBigInteger('opener_seen_message_id')->nullable();
            $table->unsignedBigInteger('assignee_seen_message_id')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('internal_tickets', function (Blueprint $table) {
            $table->dropColumn(['opener_seen_message_id', 'assignee_seen_message_id']);
        });
    }
};
