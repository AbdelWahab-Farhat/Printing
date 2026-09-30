<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Where a customer's money landed — beside how they paid it.
 *
 * `method` stays: it says how the customer paid. This says where the money is now — the cash box,
 * «مصرف علي», Nawris's custody. TREASURY-DESIGN §٤.
 *
 * **The CHECK binds every row written from now on and none written before.** The rows already
 * here were counted into the opening balances instead (§١١), so they carry no account and never
 * will; the watermark is the highest id at the moment this runs. Every path that writes a row
 * resolves an account on the server, so no request the app sends today meets this constraint.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_payments', function (Blueprint $table) {
            $table->foreignId('treasury_account_id')->nullable()->after('method')
                ->constrained('treasury_accounts');
        });

        $watermark = (int) DB::table('order_payments')->max('id');

        DB::statement("ALTER TABLE order_payments ADD CONSTRAINT order_payments_money_names_an_account CHECK (
            type NOT IN ('payment', 'refund') OR treasury_account_id IS NOT NULL OR id <= {$watermark}
        )");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE order_payments DROP CONSTRAINT IF EXISTS order_payments_money_names_an_account');

        Schema::table('order_payments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('treasury_account_id');
        });
    }
};
