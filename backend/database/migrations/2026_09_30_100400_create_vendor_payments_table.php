<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * دفعات الموردين — money the company paid a vendor, shaped like `order_payments` turned around.
 * TREASURY-DESIGN §٨.
 *
 * Three kinds of row:
 *
 * | type | what | account |
 * | --- | --- | --- |
 * | payment | money went out to the vendor | required — the drawer it left |
 * | reversal | a payment entered in error | none — it mirrors the original's movement |
 * | opening_debt | what the company already owed on opening day | none — no money moved |
 *
 * **And every purchase order standing today is marked `predates_treasury`.** None of them has a
 * payment recorded, so each would show its whole total as still owed — the owner's decision is
 * to show nothing owed on them instead, and to record the few that truly are as an opening debt.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('vendor_payments', function (Blueprint $table) {
            $table->id();

            $table->foreignId('vendor_id')->constrained('vendors');
            $table->foreignId('purchase_order_id')->nullable()->constrained('purchase_orders');

            $table->string('type', 20);
            $table->decimal('amount', 14, 2);

            $table->string('method', 20)->nullable();
            $table->foreignId('treasury_account_id')->nullable()->constrained('treasury_accounts');

            $table->string('reference', 100)->nullable();

            $table->string('receipt_disk', 50)->nullable();
            $table->string('receipt_path')->nullable();
            $table->string('receipt_original_filename')->nullable();
            $table->unsignedBigInteger('receipt_size_bytes')->nullable();
            $table->string('receipt_checksum', 64)->nullable();

            // When the money moved, not when it was typed.
            $table->timestamp('paid_at');
            $table->text('notes')->nullable();

            $table->foreignId('reverses_payment_id')->nullable()->constrained('vendor_payments');
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            $table->softDeletes()->index();

            $table->index(['vendor_id', 'paid_at']);
            $table->index('purchase_order_id');
        });

        DB::statement('ALTER TABLE vendor_payments ADD CONSTRAINT vendor_payments_amount_positive CHECK (amount > 0)');

        DB::statement("ALTER TABLE vendor_payments ADD CONSTRAINT vendor_payments_shape CHECK (
            (type = 'payment' AND method IS NOT NULL AND treasury_account_id IS NOT NULL AND reverses_payment_id IS NULL)
            OR (type = 'reversal' AND reverses_payment_id IS NOT NULL)
            OR (type = 'opening_debt' AND method IS NULL AND treasury_account_id IS NULL AND reverses_payment_id IS NULL)
        )");

        DB::statement('CREATE UNIQUE INDEX vendor_payments_reverses_unique
            ON vendor_payments (reverses_payment_id)
            WHERE reverses_payment_id IS NOT NULL AND deleted_at IS NULL');

        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->boolean('predates_treasury')->default(false);
        });

        DB::table('purchase_orders')->update(['predates_treasury' => true]);
    }

    public function down(): void
    {
        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->dropColumn('predates_treasury');
        });

        Schema::dropIfExists('vendor_payments');
    }
};
