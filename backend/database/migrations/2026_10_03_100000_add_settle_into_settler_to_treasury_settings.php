<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «التسوية إلى حساب المسوّي» — at «تم التسوية», each kind of the order's money goes to the
 * settler's own account of that kind. TREASURY-DESIGN §٢٢.
 *
 * **Starts off**, so running this changes nothing until the owner turns it on.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->boolean('settle_into_settler')->default(false)->after('collect_wallet_into_id');
        });
    }

    public function down(): void
    {
        Schema::table('treasury_settings', function (Blueprint $table) {
            $table->dropColumn('settle_into_settler');
        });
    }
};
