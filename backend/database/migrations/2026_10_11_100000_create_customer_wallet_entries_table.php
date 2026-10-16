<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «محفظة الزبون» — one append-only ledger per customer. Docs/payments/CUSTOMER-WALLET.md §٤.
 *
 * Written the way `order_payments` and `investor_wallet_entries` are: a **positive** amount always,
 * the direction carried by the type, a mistake undone by a further row pointing back, `recorded_by`
 * stamped rather than fillable, and no balance column anywhere — the balance is the sum of these
 * rows, read under a lock on the customer.
 *
 * **The wallet is the customer.** One wallet, one balance, no buckets — the owner's decision of
 * 2026-10-11 — so there is no `wallets` table to keep in step with `customers`.
 *
 * **Money only comes in.** There is no withdrawal type: a top-up, a refund handed back into the
 * wallet, and a hand adjustment are the only credits, and paying an order is the only debit.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_wallet_entries', function (Blueprint $table) {
            $table->id();

            $table->foreignId('customer_id')->constrained('customers')->restrictOnDelete();

            $table->string('type', 30);

            $table->decimal('amount', 14, 2);

            // How a top-up arrived — the order payment methods, plus `online` for EzonePay. Only on
            // a top-up: everything else is money already inside the system.
            $table->string('method', 20)->nullable();

            // The account a top-up's money went into. The payable «أرصدة محافظ الزبائن» is not
            // named here: every entry moves it, so naming it would say nothing.
            $table->foreignId('treasury_account_id')->nullable()
                ->constrained('treasury_accounts')->restrictOnDelete();

            // The order a payment from the wallet went to, or a refund came back from — and the
            // ledger row on the order's side that carries it.
            $table->foreignId('order_id')->nullable()->constrained('orders')->restrictOnDelete();
            $table->foreignId('order_payment_id')->nullable()
                ->constrained('order_payments')->restrictOnDelete();

            $table->string('reference', 100)->nullable();

            // The receipt (الواصل) of a top-up — required for a transfer, as on an order payment:
            // a transfer's only proof is the paper the customer sends. Same five columns, stored by
            // the same `StoreReceipt`.
            $table->string('receipt_disk', 50)->nullable();
            $table->string('receipt_path')->nullable();
            $table->string('receipt_original_filename')->nullable();
            $table->unsignedBigInteger('receipt_size_bytes')->nullable();
            $table->string('receipt_checksum', 64)->nullable();

            // When the money moved, not when somebody typed it in — the `order_payments` rule.
            $table->timestamp('occurred_at');

            $table->text('notes')->nullable();

            $table->foreignId('reverses_entry_id')->nullable()
                ->constrained('customer_wallet_entries')->restrictOnDelete();

            // Null for what the customer did themselves — paying from the app, a top-up online.
            $table->foreignId('recorded_by')->nullable()->constrained('users')->nullOnDelete();

            $table->timestamps();
            // Present because every domain model soft-deletes; the model refuses to use it.
            $table->softDeletes();

            $table->index(['customer_id', 'id']);
            $table->index(['type', 'occurred_at']);
            $table->index('order_id');
        });

        DB::statement(<<<'SQL'
            ALTER TABLE customer_wallet_entries
            ADD CONSTRAINT customer_wallet_entries_amount_positive CHECK (amount > 0)
        SQL);

        // Never reverse the same row twice.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX customer_wallet_entries_reversed_once
            ON customer_wallet_entries (reverses_entry_id)
            WHERE reverses_entry_id IS NOT NULL
        SQL);

        // **One wallet row per order payment** — a payment from the wallet and a refund into it are
        // each written once, whoever retries. The reversal of such a row points at the row, not at
        // the payment, so it is not caught here.
        DB::statement(<<<'SQL'
            CREATE UNIQUE INDEX customer_wallet_entries_one_per_order_payment
            ON customer_wallet_entries (order_payment_id)
            WHERE order_payment_id IS NOT NULL
        SQL);

        DB::statement(<<<'SQL'
            ALTER TABLE customer_wallet_entries
            ADD CONSTRAINT customer_wallet_entries_transfer_needs_receipt CHECK (
                method IS DISTINCT FROM 'bank_transfer' OR receipt_path IS NOT NULL
            )
        SQL);

        // The shapes that exist, each saying what it carries.
        DB::statement(<<<'SQL'
            ALTER TABLE customer_wallet_entries
            ADD CONSTRAINT customer_wallet_entries_shape CHECK (
                (type = 'topup'
                    AND method IS NOT NULL AND treasury_account_id IS NOT NULL
                    AND order_id IS NULL AND order_payment_id IS NULL AND reverses_entry_id IS NULL)
                OR (type IN ('order_payment', 'order_refund')
                    AND method IS NULL AND treasury_account_id IS NULL
                    AND order_id IS NOT NULL AND order_payment_id IS NOT NULL AND reverses_entry_id IS NULL)
                OR (type IN ('adjustment_credit', 'adjustment_debit')
                    AND method IS NULL AND treasury_account_id IS NULL
                    AND order_id IS NULL AND order_payment_id IS NULL AND reverses_entry_id IS NULL)
                OR (type = 'reversal'
                    AND method IS NULL AND treasury_account_id IS NULL
                    AND order_payment_id IS NULL AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }

    public function down(): void
    {
        Schema::dropIfExists('customer_wallet_entries');
    }
};
