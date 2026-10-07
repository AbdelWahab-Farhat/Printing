<?php

declare(strict_types=1);

use App\Domain\Order\Enums\OrderPaymentType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «الزائد للزبون» — a customer hands over 100 on an order of 99, and nobody has the one dinar.
 *
 * **The whole 100 is one entry**, because one handover happened: one receipt, one review, one
 * reversal if it was a mistake. `order_payments.excess_amount` says how much of it was beyond
 * what the order owed — 1 — and that part never reaches `paid_amount`: the order is paid 99,
 * its sales are 99, and the one dinar is owed back to the customer until somebody refunds it or
 * decides it is the shop's («اعتبار الزائد إيراداً», the new `excess_kept` entry).
 *
 * `orders.excess_amount` is the ledger's fourth total, beside paid, written off and settled at
 * the carrier, and written by `RecalculateOrderPayments` alone like the other three.
 *
 * | type | `excess_amount` |
 * | --- | --- |
 * | `payment` | what was beyond the debt when it was taken — 0 almost always |
 * | `refund` | how much of the refund handed the excess back rather than the payment |
 * | everything else | 0 — `excess_kept` carries its figure in `amount`, all of it excess |
 *
 * **`excess_kept` moves no money and names no method**, so it joins the write-off and the carrier
 * settlement in the ledger's shape rule. Forward-only, as RULES.md §8 requires: the shape
 * constraint is dropped and recreated rather than edited, and every existing row stays legal.
 *
 * See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('order_payments', function (Blueprint $table) {
            $table->decimal('excess_amount', 12, 2)->default(0)->after('amount');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('excess_amount', 12, 2)->default(0)->after('carrier_settled_amount');
        });

        $payment = OrderPaymentType::Payment->value;
        $refund = OrderPaymentType::Refund->value;

        DB::statement(<<<SQL
            ALTER TABLE order_payments
                ADD CONSTRAINT order_payments_excess_fits CHECK (
                    excess_amount >= 0
                    AND excess_amount <= amount
                    AND (excess_amount = 0 OR type IN ('{$payment}', '{$refund}'))
                )
        SQL);

        // Owed to the customer can reach zero and never go below it: handing back more than was
        // held would be money nobody can account for.
        DB::statement('ALTER TABLE orders ADD CONSTRAINT orders_excess_not_negative CHECK (excess_amount >= 0)');

        $this->shape(withExcessKept: true);
    }

    public function down(): void
    {
        $this->shape(withExcessKept: false);

        DB::statement('ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_excess_not_negative');
        DB::statement('ALTER TABLE order_payments DROP CONSTRAINT IF EXISTS order_payments_excess_fits');

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('excess_amount');
        });

        Schema::table('order_payments', function (Blueprint $table) {
            $table->dropColumn('excess_amount');
        });
    }

    /**
     * The three shapes, with `excess_kept` among the entries that moved no money — or, rolling
     * back, the rule exactly as it stood. Rolling back over a kept excess fails here, which is the
     * honest outcome: the shape it was written in is one the old constraint has no room for.
     */
    private function shape(bool $withExcessKept): void
    {
        $reversal = OrderPaymentType::Reversal->value;
        $noMoney = "'".OrderPaymentType::WriteOff->value."', '".OrderPaymentType::CarrierSettled->value."'"
            .($withExcessKept ? ", '".OrderPaymentType::ExcessKept->value."'" : '');

        DB::statement('ALTER TABLE order_payments DROP CONSTRAINT order_payments_shape');

        DB::statement(<<<SQL
            ALTER TABLE order_payments
                ADD CONSTRAINT order_payments_shape CHECK (
                    (type = '{$reversal}' AND reverses_payment_id IS NOT NULL AND method IS NULL)
                    OR
                    (type IN ({$noMoney}) AND reverses_payment_id IS NULL AND method IS NULL)
                    OR
                    (type NOT IN ('{$reversal}', {$noMoney}) AND reverses_payment_id IS NULL AND method IS NOT NULL)
                )
        SQL);
    }
};
