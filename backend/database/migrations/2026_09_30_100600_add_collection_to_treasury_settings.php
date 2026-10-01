<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * «التجميع عند التسوية» — at «تم التسوية», the order's money in «مصرف علي» or a branch's cash box
 * moves to one collecting account of its kind. TREASURY-DESIGN §١٨.
 *
 * **Every switch starts off**, so running this changes nothing until the owner turns one on. A
 * null target means the kind's default account, resolved at the moment of settlement — so
 * changing the default later moves the collection with it.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_settings', function (Blueprint $table) {
            foreach (['cash', 'bank', 'wallet'] as $kind) {
                $table->boolean("collect_{$kind}")->default(false)->after('locked_until');
                $table->foreignId("collect_{$kind}_into_id")->nullable()->after("collect_{$kind}")
                    ->constrained('treasury_accounts');
            }
        });

        Schema::table('treasury_accounts', function (Blueprint $table) {
            // The exception: a branch that keeps its own float is never emptied by a settlement.
            $table->boolean('is_collected')->default(true)->after('settles_into_account_id');
        });
    }

    public function down(): void
    {
        Schema::table('treasury_accounts', function (Blueprint $table) {
            $table->dropColumn('is_collected');
        });

        Schema::table('treasury_settings', function (Blueprint $table) {
            foreach (['cash', 'bank', 'wallet'] as $kind) {
                $table->dropConstrainedForeignId("collect_{$kind}_into_id");
                $table->dropColumn("collect_{$kind}");
            }
        });
    }
};
