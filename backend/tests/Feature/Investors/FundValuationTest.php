<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\FundValuation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * قيمةُ الصندوق — الرقمُ الذي تُقسَّم عليه كلُّ نسبة.
 *
 * الشريحة ١د من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * ```
 * قيمة الصندوق = نقد
 *              + بضاعة على الرفّ            (بالتكلفة)
 *              + بضاعة خرجت ولم تُسلَّم      (بالتكلفة)
 *              + مبيعات سُلِّمت ولم تُحصَّل   (بتكلفتها)
 *              − أرباحٌ لم تصل جيبَ أصحابها بعد
 * ```
 *
 * **والمبدأُ الواحد وراء البنود الأربعة: كلُّ أصلٍ يدخل بتكلفته، وكلُّ هامشٍ يخصّ فترةَ طلبيته.**
 * فالبضاعةُ في المطبعة والفاتورةُ غير المحصَّلة كلتاهما مالُ الصندوق بتكلفتها، وربحُهما محجوزٌ
 * لفترةٍ أخرى — ولو قُوِّمتا بسعر البيع لاقتسم حَمَلةُ الفترة القادمة هامشاً صنعه غيرُهم.
 *
 * **والطرحُ الأخير ليس تفصيلاً:** ربحٌ مستحقٌّ لمستثمر — أُفرِج عنه أو لم يُفرَج — دَينٌ على
 * الصندوق لا رأسُ مالٍ عامل. لو دخل في القيمة لتقاسمه الجميع مرّةً ثانية.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundValuationTest extends TestCase
{
    use RefreshDatabase;

    private function valuation(): FundValuation
    {
        return app(FundValuation::class);
    }

    private function cash(CashEntryType $type, string $amount, int $sourceId): void
    {
        DB::table('investment_cash_entries')->insert([
            'type' => $type->value,
            'amount' => $amount,
            'source_type' => 'order_payment',
            'source_id' => $sourceId,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_a_fund_that_owns_nothing_is_worth_nothing(): void
    {
        // Arrange — لا نقدَ ولا بضاعةَ ولا دفتر.

        // Act
        $value = $this->valuation()();

        // Assert
        $this->assertSame('0.00', $value['total']);
        $this->assertSame('0.00', $value['cash']);
        $this->assertSame('0.00', $value['stock_on_shelf']);
    }

    public function test_cash_is_what_came_in_less_what_went_out(): void
    {
        // Arrange — الاتجاهُ في النوع لا في إشارة المبلغ.
        $this->cash(CashEntryType::Deposit, '50000.00', 1);
        $this->cash(CashEntryType::SaleProceeds, '18000.00', 2);
        $this->cash(CashEntryType::Purchase, '20000.00', 3);
        $this->cash(CashEntryType::Expense, '1000.00', 4);

        // Act
        $value = $this->valuation()();

        // Assert — ٥٠٬٠٠٠ + ١٨٬٠٠٠ − ٢٠٬٠٠٠ − ١٬٠٠٠
        $this->assertSame('47000.00', $value['cash']);
        $this->assertSame('47000.00', $value['total']);
    }

    public function test_a_reversed_row_leaves_no_trace_in_the_cash(): void
    {
        // Arrange — التصحيحُ صفٌّ عكسيّ لا تعديلُ صفّ، والقيمةُ يجب أن تقرأه كذلك.
        $this->cash(CashEntryType::Deposit, '50000.00', 1);
        $original = (int) DB::table('investment_cash_entries')->value('id');

        DB::table('investment_cash_entries')->insert([
            'type' => CashEntryType::Reversal->value,
            'amount' => '50000.00',
            'source_type' => null,
            'source_id' => null,
            'source_sequence' => 1,
            'reverses_entry_id' => $original,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        $value = $this->valuation()();

        // Assert
        $this->assertSame('0.00', $value['cash']);
    }

    public function test_stock_on_the_shelf_counts_at_what_it_cost(): void
    {
        // Arrange — طبقتان للصندوق وثالثةٌ للشركة؛ والثالثةُ ليست مالَه.
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '400.000',
            'unit_cost' => '10.000',
        ]);
        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '1000.000',
            'unit_cost' => '10.000',
        ]);
        StockBatch::factory()->create([
            'investor_deal_id' => null,
            'quantity_remaining' => '9999.000',
            'unit_cost' => '10.000',
        ]);

        // Act
        $value = $this->valuation()();

        // Assert — ١٬٤٠٠ قطعة بتكلفة ١٠
        $this->assertSame('14000.00', $value['stock_on_shelf']);
        $this->assertSame('14000.00', $value['total']);
    }

    public function test_a_shelf_emptied_by_selling_stops_counting(): void
    {
        // Arrange — القيمةُ تقرأ الباقي لا الوارد: طبقةٌ استُهلكت كلُّها لا تساوي شيئاً على الرفّ.
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_received' => '600.000',
            'quantity_remaining' => '0.000',
            'unit_cost' => '10.000',
        ]);

        // Act
        $value = $this->valuation()();

        // Assert
        $this->assertSame('0.00', $value['stock_on_shelf']);
    }

    public function test_profit_owed_to_an_investor_is_a_debt_not_capital(): void
    {
        // Arrange — نقدٌ في الصندوق، وربحٌ مستحقٌّ لم يُسحب بعد. الربحُ ليس رأسَ مالٍ عامل.
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();

        $this->cash(CashEntryType::Deposit, '50000.00', 1);

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => $deal->id,
            'type' => WalletEntryType::Profit->value,
            'amount' => '3000.00',
            'source_type' => 'order',
            'source_id' => 91,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        $value = $this->valuation()();

        // Assert
        $this->assertSame('3000.00', $value['profit_owed']);
        $this->assertSame('47000.00', $value['total']);
    }

    public function test_capital_in_a_wallet_is_not_subtracted(): void
    {
        // Arrange — رأسُ المال هو الذي يعمل؛ طرحُه يُفرِّغ الصندوق من نفسه.
        $investor = Investor::factory()->create();

        $this->cash(CashEntryType::Deposit, '50000.00', 1);

        DB::table('investor_wallet_entries')->insert([
            'investor_id' => $investor->id,
            'investor_deal_id' => null,
            'type' => WalletEntryType::Deposit->value,
            'amount' => '50000.00',
            'method' => 'cash',
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        $value = $this->valuation()();

        // Assert
        $this->assertSame('0.00', $value['profit_owed']);
        $this->assertSame('50000.00', $value['total']);
    }

    public function test_every_component_is_reported_beside_the_total(): void
    {
        // Arrange — اللوحةُ تعرض البنودَ لا المجموعَ وحده، فمن يقرأ رقماً يعرف من أين جاء.
        $this->cash(CashEntryType::Deposit, '12000.00', 1);

        // Act
        $value = $this->valuation()();

        // Assert
        $this->assertSame(
            ['cash', 'stock_on_shelf', 'goods_in_flight', 'receivables_at_cost', 'profit_owed', 'total'],
            array_keys($value),
        );
    }
}
