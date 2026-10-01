<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «علينا» — accounts for what the company owes. TREASURY-DESIGN §٢٠.
 *
 * **A fifth kind, `payable`, whose balance runs below zero**: −500 is 500 owed. Two sorts share it:
 * one per vendor (`vendor_id`), which only purchase orders and vendor payments move; and the ones
 * a person opens by hand — a loan from the owner, rent due — which take an opening, an expense,
 * a transfer and a count.
 *
 * What changes underneath:
 *
 * - **An opening may come *out* of an account** — a payable's opening is a debt — so the shape
 *   CHECK and the one-opening index read whichever side is set.
 * - **`treasury_movements.revision`.** A purchase order's debt is reposted when its total
 *   changes; the reversed original still stands in `treasury_movements_posted_once`, so the new
 *   posting needs a number of its own to get past it. Every other posting stays at 0.
 * - **`vendor_payments.type = 'credit'`** — «خصم من المورد»: the vendor knocked something off what
 *   is owed. No money moves, like an opening debt.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('treasury_accounts', function (Blueprint $table) {
            // The vendor this account is the debt to. A number Treasury never follows back: the
            // purchase-order context names it, the way `order_id` names an order.
            $table->foreignId('vendor_id')->nullable()->after('holder_user_id')->constrained('vendors');
        });

        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_kind_check');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_kind_check
            CHECK (kind IN ('cash', 'bank', 'wallet', 'custody', 'payable'))");

        // Nothing falls back into a debt, any more than into custody.
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_default_shape');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_default_shape
            CHECK (NOT is_default OR (kind NOT IN ('custody', 'payable') AND is_active))");

        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_vendor_is_payable
            CHECK (vendor_id IS NULL OR kind = 'payable')");

        DB::statement('CREATE UNIQUE INDEX treasury_accounts_one_per_vendor
            ON treasury_accounts (vendor_id) WHERE vendor_id IS NOT NULL AND deleted_at IS NULL');

        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_shape');
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type = 'opening' AND (from_account_id IS NULL) <> (to_account_id IS NULL))
            OR (type = 'deposit' AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type = 'expense' AND from_account_id IS NOT NULL AND to_account_id IS NULL AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");

        DB::statement('DROP INDEX treasury_operations_one_opening');
        DB::statement("CREATE UNIQUE INDEX treasury_operations_one_opening
            ON treasury_operations ((COALESCE(to_account_id, from_account_id)))
            WHERE type = 'opening' AND deleted_at IS NULL");

        Schema::table('treasury_movements', function (Blueprint $table) {
            $table->unsignedSmallInteger('revision')->default(0)->after('source_id');
        });

        DB::statement('DROP INDEX treasury_movements_posted_once');
        DB::statement('CREATE UNIQUE INDEX treasury_movements_posted_once
            ON treasury_movements (source_type, source_id, account_id, kind, direction, revision)
            WHERE reverses_movement_id IS NULL AND deleted_at IS NULL');

        DB::statement('ALTER TABLE vendor_payments DROP CONSTRAINT vendor_payments_shape');
        DB::statement("ALTER TABLE vendor_payments ADD CONSTRAINT vendor_payments_shape CHECK (
            (type = 'payment' AND method IS NOT NULL AND treasury_account_id IS NOT NULL AND reverses_payment_id IS NULL)
            OR (type = 'reversal' AND reverses_payment_id IS NOT NULL)
            OR (type IN ('opening_debt', 'credit') AND method IS NULL AND treasury_account_id IS NULL
                AND reverses_payment_id IS NULL)
        )");
    }

    /**
     * Refused while anything depends on what `up()` added: a payable account carries movements
     * the old CHECKs cannot hold, and a credit is a row the old shape forbids.
     */
    public function down(): void
    {
        if (DB::table('treasury_accounts')->where('kind', 'payable')->exists()
            || DB::table('vendor_payments')->where('type', 'credit')->exists()
            || DB::table('treasury_movements')->where('revision', '>', 0)->exists()
            || DB::table('treasury_operations')->where('type', 'opening')->whereNotNull('from_account_id')->exists()) {
            throw new RuntimeException('حسابات «علينا» مستعملة — لا يُرجَع هذا الترحيل وفيها حركات.');
        }

        DB::statement('ALTER TABLE vendor_payments DROP CONSTRAINT vendor_payments_shape');
        DB::statement("ALTER TABLE vendor_payments ADD CONSTRAINT vendor_payments_shape CHECK (
            (type = 'payment' AND method IS NOT NULL AND treasury_account_id IS NOT NULL AND reverses_payment_id IS NULL)
            OR (type = 'reversal' AND reverses_payment_id IS NOT NULL)
            OR (type = 'opening_debt' AND method IS NULL AND treasury_account_id IS NULL AND reverses_payment_id IS NULL)
        )");

        DB::statement('DROP INDEX treasury_movements_posted_once');
        DB::statement('CREATE UNIQUE INDEX treasury_movements_posted_once
            ON treasury_movements (source_type, source_id, account_id, kind, direction)
            WHERE reverses_movement_id IS NULL AND deleted_at IS NULL');

        Schema::table('treasury_movements', function (Blueprint $table) {
            $table->dropColumn('revision');
        });

        DB::statement('DROP INDEX treasury_operations_one_opening');
        DB::statement("CREATE UNIQUE INDEX treasury_operations_one_opening
            ON treasury_operations (to_account_id)
            WHERE type = 'opening' AND deleted_at IS NULL");

        DB::statement('ALTER TABLE treasury_operations DROP CONSTRAINT treasury_operations_shape');
        DB::statement("ALTER TABLE treasury_operations ADD CONSTRAINT treasury_operations_shape CHECK (
            (type IN ('opening', 'deposit') AND to_account_id IS NOT NULL AND from_account_id IS NULL)
            OR (type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL)
            OR (type = 'expense' AND from_account_id IS NOT NULL AND to_account_id IS NULL AND category_id IS NOT NULL)
            OR (type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL
                AND from_account_id <> to_account_id)
            OR (type = 'adjustment' AND (from_account_id IS NULL) <> (to_account_id IS NULL)
                AND system_balance IS NOT NULL AND counted_balance IS NOT NULL)
            OR (type = 'settlement' AND to_account_id IS NOT NULL AND order_id IS NOT NULL)
        )");

        DB::statement('DROP INDEX treasury_accounts_one_per_vendor');
        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_vendor_is_payable');

        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_default_shape');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_default_shape
            CHECK (NOT is_default OR (kind <> 'custody' AND is_active))");

        DB::statement('ALTER TABLE treasury_accounts DROP CONSTRAINT treasury_accounts_kind_check');
        DB::statement("ALTER TABLE treasury_accounts ADD CONSTRAINT treasury_accounts_kind_check
            CHECK (kind IN ('cash', 'bank', 'wallet', 'custody'))");

        Schema::table('treasury_accounts', function (Blueprint $table) {
            $table->dropConstrainedForeignId('vendor_id');
        });
    }
};
