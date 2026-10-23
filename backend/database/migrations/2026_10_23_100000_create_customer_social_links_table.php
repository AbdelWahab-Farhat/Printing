<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * روابط التواصل للعميل: صفحاته على فيسبوك وإنستغرام وتيك توك وغيرها، بلا حدٍّ للمنصّات.
 * المواصفة في Docs/customers/CUSTOMER-SOCIAL-LINKS.md.
 *
 * **الرابط وحده، بلا عمود منصّة.** التطبيقان يعرفان المنصّة من نطاق الرابط ليرسما أيقونتها
 * والمستخدم يكتب، وعمودٌ يحفظ الجواب نفسه كان سيختلف معهما يوم تُضاف منصّة.
 *
 * **بلا فهرسٍ فريد على (العميل، الرابط).** الروابط لا تُكتب إلا بمزامنة المجموعة كلّها، وتكرارُ
 * رابطٍ داخل الطلب الواحد تردّه قاعدة `distinct`. والفهرس كان سيكسر تعديلاً صحيحاً: تبديلُ رابطين
 * بين سطرين يمرّ في منتصفه بسطرين يحملان الرابط نفسه.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_social_links', function (Blueprint $table) {
            $table->id();

            // بلا `cascadeOnDelete`: العميل لا يُحذف، والحذف هنا ناعمٌ لا يمرّ بالمفتاح الأجنبي أصلاً.
            $table->foreignId('customer_id')->constrained('customers');

            // حدُّ قاعدة التحقق نفسه، كـ`page_url` على المحل.
            $table->string('url', 2048);

            $table->timestamps();
            $table->softDeletes()->index();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_social_links');
    }
};
