<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * أين يُرسَل الدفعُ إلى العميل — صفٌّ لكل جهازٍ دخل منه عميلٌ إلى تطبيقه.
 *
 * **جدولٌ خاصٌّ بالعملاء، لا عمودٌ يُضاف إلى `device_tokens`.** ذاك الجدول وكلُّ ما حوله من
 * الإشعارات مفتاحه `users.id`، والعميلُ نموذجٌ آخر بحارسٍ آخر. والقرارُ مأخوذ: العميل يأخذ الدفعَ
 * وحده — لا صفوفَ إشعارات ولا جرس — فلا شيء في جداول الموظفين يُعمَّم لأجله.
 *
 * **يُحذف حذفاً حقيقياً، بلا `deleted_at`**، للسبب نفسه المشروح في
 * `2026_09_07_100200_create_device_tokens_table`: الرمزُ عنوانٌ لا سجلّ، والعنوانُ الميّت يُمحى.
 * و`ModelConventionsTest` يستثني نموذجه بجانب `DeviceToken`.
 *
 * **و`token` فريدٌ على الجدول كلّه لا لكل عميل**، ولأجل الأمان أيضاً: هاتفٌ يخرج منه عميلٌ ويدخل
 * غيره يسجّل الرمزَ نفسه، فيُحدَّث الصفُّ الواحد ولا يبقى الأوّلُ يتلقّى أخبارَ طلبيات الثاني. انظر
 * RegisterCustomerDevice.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_device_tokens', function (Blueprint $table) {
            $table->id();

            // الحذفُ الحقيقيّ للعميل نادر (يُعطَّل ولا يُحذف)، لكنه إن وقع فلا معنى لعنوانٍ بلا صاحب.
            $table->foreignId('customer_id')->constrained('customers')->cascadeOnDelete();

            $table->string('token', 255)->unique();

            // قيمةٌ من `DevicePlatform`.
            $table->string('platform', 16);

            // يُلمَس عند كل إرسالٍ ناجح، فيمكن يوماً تنظيفُ الأجهزة التي كفّت عن الردّ بلا خطأ.
            $table->timestamp('last_used_at')->nullable();

            $table->timestamps();

            $table->index('customer_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_device_tokens');
    }
};
