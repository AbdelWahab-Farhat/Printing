<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «تسوية دفعة» — TREASURY-DESIGN §٢٣.
 *
 * **تسويةٌ تخصّ دفعةً واحدة تسمّيها.** تسويةُ الطلبية تنقل كلَّ ما بقي لها في حساب؛ تسويةُ الدفعة
 * تنقل مالَ دفعةٍ واحدة قبل أن تصل الطلبيةُ إلى «تم التسوية»، وهذا العمودُ ما يفرّق بينهما: فارغٌ
 * على تسوية الطلبية، ورقمُ الدفعة على تسويتها. والعكسُ يحمله أيضاً، فيُقرأ السجلُّ بلا تخمين.
 *
 * **رقمٌ لا مفتاحٌ أجنبي**، كـ`order_id` بجانبه: الخزينة لا تعرف ما الدفعة، والعمودُ للتصفية.
 * فارغٌ على كل صفٍّ قائم، فلا يُمسّ شيء.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_operations', function (Blueprint $table) {
            $table->unsignedBigInteger('order_payment_id')->nullable()->after('order_id')->index();
        });
    }

    public function down(): void
    {
        Schema::table('treasury_operations', function (Blueprint $table) {
            $table->dropIndex(['order_payment_id']);
            $table->dropColumn('order_payment_id');
        });
    }
};
