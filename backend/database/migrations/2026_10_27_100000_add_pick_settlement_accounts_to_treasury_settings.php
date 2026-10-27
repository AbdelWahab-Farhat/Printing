<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «اختيار حساب كل نوع عند التسوية» — at «تم التسوية», the settler picks one account for each kind
 * of the order's money. TREASURY-DESIGN §٢٤.
 *
 * **Starts off**, so running this changes nothing until the owner turns it on.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->boolean('pick_settlement_accounts')->default(false)->after('settle_into_settler');
        });
    }

    public function down(): void
    {
        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->dropColumn('pick_settlement_accounts');
        });
    }
};
