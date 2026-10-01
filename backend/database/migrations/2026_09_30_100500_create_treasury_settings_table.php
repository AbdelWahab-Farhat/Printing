<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «إعدادات المالية» — the owner's switches over the treasury's rules, and where each custody
 * account's money goes when its orders are settled. TREASURY-DESIGN §١٦.
 *
 * **Every switch starts where the system already stood**, so running this changes nothing until
 * somebody changes a setting: own account first, overdrafts refused, a reason on withdrawals,
 * the carrier's cut asked at settlement, and nothing locked.
 *
 * A table of its own rather than more columns on `company_settings`: these belong to Treasury and
 * are guarded by `treasury.manage`, not `settings.manage` — the same split the investment
 * settings would have made had they come later.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('treasury_settings', function (Blueprint $table) {
            $table->id();

            // Rule 2 of §٥: a payment lands in the recorder's own account before the default.
            $table->boolean('own_account_first')->default(true);

            // Money out by hand — withdrawal, expense, transfer, vendor payment — refused when the
            // account does not hold it.
            $table->boolean('block_overdraft')->default(true);

            $table->boolean('withdrawal_needs_reason')->default(true);

            // «احتفظ به الناقل» on the settle screen.
            $table->boolean('ask_carrier_fee')->default(true);

            // Nothing by hand dated on or before this day — the month that was counted stays
            // counted. Null: nothing is locked.
            $table->date('locked_until')->nullable();

            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();
        });

        DB::statement('ALTER TABLE treasury_settings ADD CONSTRAINT treasury_settings_singleton CHECK (id = 1)');

        DB::table('treasury_settings')->insert([
            'id' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Schema::table('treasury_accounts', function (Blueprint $table) {
            // Where this custody's money goes at «تم التسوية» when nobody picks — Nawris into
            // «مصرف الجمهورية», a driver into the cash box. Null: the built-in rule.
            $table->foreignId('settles_into_account_id')->nullable()->after('system_code')
                ->constrained('treasury_accounts');
        });

        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_settles_into_custody
            CHECK (settles_into_account_id IS NULL OR kind = 'custody')");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT IF EXISTS treasury_accounts_settles_into_custody');

        Schema::table('treasury_accounts', function (Blueprint $table) {
            $table->dropConstrainedForeignId('settles_into_account_id');
        });

        Schema::dropIfExists('treasury_settings');
    }
};
