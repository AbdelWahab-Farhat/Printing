<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * الدفعُ من المحفظة لا يُكتب مرّتين — على نسق `treasury_operations.client_token`.
 *
 * **رمزٌ يولّده التطبيق قبل الإرسال، ويبقى حتى ينجح الدفع.** اتصالٌ انقطع بعد أن دفع الخادمُ يترك
 * الزبون لا يعرف هل دُفع، فيعيد — والرمزُ نفسه يُرجع الدفعةَ الأولى بدل أن يكتب ثانية.
 * CUSTOMER-WALLET §٤.
 *
 * على صفّ المحفظة لا على `order_payments`: الدفعُ من المحفظة يكتب صفّاً واحداً فيها، وهي ما يُقفل
 * عليه (الزبون). فريدٌ داخل محفظة الزبون، كما دفعةُ المورد داخل مورده.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customer_wallet_entries', function (Blueprint $table) {
            $table->string('client_token', 64)->nullable();
        });

        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX customer_wallet_entries_client_token_unique
            ON customer_wallet_entries (customer_id, client_token)
            WHERE client_token IS NOT NULL
        SQL);
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS customer_wallet_entries_client_token_unique');

        Schema::table('customer_wallet_entries', function (Blueprint $table) {
            $table->dropColumn('client_token');
        });
    }
};
