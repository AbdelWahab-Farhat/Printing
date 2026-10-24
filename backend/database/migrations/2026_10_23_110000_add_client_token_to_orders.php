<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الطلبية من التطبيق لا تُكتب مرّتين — على نسق `customer_wallet_entries.client_token`.
 *
 * **رمزٌ يولّده التطبيق قبل الإرسال، ويبقى حتى تصل الطلبية.** اتصالٌ انقطع بعد أن كتبها الخادم
 * يترك العميل والسلةُ ممتلئة، فيضغط «إرسال» ثانية — والرمز نفسه يُرجع الطلبيةَ الأولى بدل أن يكتب
 * ثانية، ومعها عربونٌ ثانٍ من المحفظة.
 *
 * فريدٌ داخل طلبيات العميل، والمحذوفة منها معها: إعادةُ طلبيةٍ حذفها الموظف لا تُرجعها حيّة.
 * طلبيات الموظفين بلا رمز، فلا يمسّها الفهرس.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('client_token', 64)->nullable();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX orders_client_token_unique
            ON orders (customer_id, client_token)
            WHERE client_token IS NOT NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS orders_client_token_unique');

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('client_token');
        });
    }
};
