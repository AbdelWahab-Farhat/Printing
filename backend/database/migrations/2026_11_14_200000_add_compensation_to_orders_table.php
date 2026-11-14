<?php

declare(strict_types=1);

use App\Domain\Investor\Enums\CashEntryType;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * «طلبية تعويض» — an order whose goods leave stock like any other, and which the customer does
 * not pay for. See Docs/orders/ORDER-COMPENSATION.md.
 *
 * Every existing order becomes an ordinary one (`is_compensation = false`), which is what they
 * all were. Nothing is backfilled.
 *
 * The fund's cash ledger learns one type, {@see CashEntryType::CompensationCoveredByCompany}:
 * what the company pays the fund back for goods a compensation order gave away, at cost.
 */
return new class extends Migration
{
    private const CASH = "'deposit', 'purchase', 'expense', 'sale_proceeds', 'profit_payout', 'company_payout', 'capital_return', 'stock_sold_to_press', 'legacy_transfer', 'write_off_covered_by_company', 'expense_covered_by_company', 'profit_capitalised'";

    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->boolean('is_compensation')->default(false)->after('additional_cost_note');
            $table->string('compensation_reason', 30)->nullable()->after('is_compensation');
            $table->string('compensation_note', 500)->nullable()->after('compensation_reason');

            // The order being made good, when there is one. Optional by the owner's decision:
            // goodwill across several orders has no single order to name.
            $table->foreignId('compensates_order_id')
                ->nullable()
                ->after('compensation_note')
                ->constrained('orders')
                ->nullOnDelete();

            $table->index('is_compensation');
        });

        $this->cashShapeWith(self::CASH.", 'compensation_by_company'");
    }

    public function down(): void
    {
        // Soft-deleted rather than erased, as the earlier reshapes do: the old constraint does
        // not know the type.
        DB::table('investment_cash_entries')
            ->where('type', 'compensation_by_company')
            ->whereNull('deleted_at')
            ->update(['deleted_at' => now()]);

        $this->cashShapeWith(self::CASH);

        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['compensates_order_id']);
            $table->dropIndex(['is_compensation']);
            $table->dropColumn(['is_compensation', 'compensation_reason', 'compensation_note', 'compensates_order_id']);
        });
    }

    private function cashShapeWith(string $types): void
    {
        DB::statement('ALTER TABLE investment_cash_entries DROP CONSTRAINT IF EXISTS investment_cash_entries_shape');

        DB::statement(<<<SQL
            ALTER TABLE investment_cash_entries
            ADD CONSTRAINT investment_cash_entries_shape CHECK (
                (type IN ({$types})
                    AND source_type IS NOT NULL AND source_id IS NOT NULL
                    AND reverses_entry_id IS NULL)
                OR (type = 'reversal'
                    AND source_type IS NULL AND source_id IS NULL
                    AND reverses_entry_id IS NOT NULL)
            )
        SQL);
    }
};
