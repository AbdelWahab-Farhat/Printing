<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الضغطةُ المزدوجة لا تكتب المال مرّتين.
 *
 * **`client_token` رمزٌ يولّده التطبيق قبل الإرسال**، على نسق `ticket_messages.client_token`:
 * اتصالٌ انقطع بعد الحفظ يترك الموظّف لا يعرف هل سُجِّل سحبُه، فيعيد — والرمزُ نفسه يُرجع
 * العمليةَ الأولى بدل أن يكتب ثانية.
 *
 * فريدٌ جزئياً كما تقتضي قاعدة الحذف الناعم. عامٌّ على العمليات — لا شيء فوقها يُقفل — وداخل
 * المورد على دفعاته، كما رسالةُ الدعم داخل تذكرتها. والعمودان فارغان على كل صفٍّ قائم، فلا
 * تُمسّ الصفوفُ ولا يُقفل الجدولُ إلا لحظةَ إضافة عمودٍ يقبل الفراغ.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_operations', function (Blueprint $table) {
            $table->string('client_token', 64)->nullable();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX treasury_operations_client_token_unique
            ON treasury_operations (client_token)
            WHERE client_token IS NOT NULL AND deleted_at IS NULL
        SQL);

        Schema::table('vendor_payments', function (Blueprint $table) {
            $table->string('client_token', 64)->nullable();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX vendor_payments_client_token_unique
            ON vendor_payments (vendor_id, client_token)
            WHERE client_token IS NOT NULL AND deleted_at IS NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS vendor_payments_client_token_unique');
        DB::statement('DROP INDEX IF EXISTS treasury_operations_client_token_unique');

        Schema::table('vendor_payments', function (Blueprint $table) {
            $table->dropColumn('client_token');
        });

        Schema::table('treasury_operations', function (Blueprint $table) {
            $table->dropColumn('client_token');
        });
    }
};
