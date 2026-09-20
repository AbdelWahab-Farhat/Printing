<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Investor\Enums\CashEntryType;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * خزينةُ الصندوق — الضمانات التي تحملها القاعدة لا الفعل.
 *
 * الشريحة ١أ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}. النقدُ يسبق الفترة لأن
 * قسمةَ النسب عند حافّة كل فترة تقرأ «قيمة الصندوق»، وأوّلُ بنودها نقدُه.
 *
 * وما يُثبَّت هنا أربعةٌ، وكلُّها في القاعدة حتى لا تتّكل على كاتبٍ يتذكّر:
 *
 * 1. **المبلغُ موجبٌ دائماً** — الاتجاه في النوع، على شكل `order_payments` حرفياً.
 * 2. **كلُّ صفٍّ يسمّي مصدره** — إيداعاً أو أمرَ شراءٍ أو مصروفاً أو دفعةَ طلبية. نقدٌ بلا مصدر
 *    مالٌ لا يعرف أحدٌ من أين جاء.
 * 3. **الحدثُ الواحد لا يُرحَّل مرّتين** — دفعةُ طلبيةٍ عولجت مرّتين لا تُدخل المال مرّتين.
 * 4. **العكسُ مرّةً واحدة** — وإلا ضوعف المال بردَّين على صفٍّ واحد.
 *
 * والاختبارُ يكتب في الجدول مباشرةً عن قصد: الضمانةُ المقصودة ضمانةُ قاعدة بيانات، وفعلٌ يحرسها
 * في PHP هو ما لا نريد أن نعتمد عليه.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundTreasuryTest extends TestCase
{
    use RefreshDatabase;

    /**
     * صفُّ خزينة، افتراضُه تحصيلُ ٤٬٥٠٠ عن دفعة الطلبية رقم ٧.
     *
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function entry(array $overrides = []): array
    {
        return array_merge([
            'type' => CashEntryType::SaleProceeds->value,
            'amount' => '4500.00',
            'source_type' => 'order_payment',
            'source_id' => 7,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides);
    }

    public function test_money_collected_from_a_sale_enters_the_treasury(): void
    {
        // Arrange — لا شيء: الخزينة تقبل أوّل صفٍّ بلا تمهيد.

        // Act
        DB::table('investment_cash_entries')->insert($this->entry());

        // Assert
        $this->assertDatabaseHas('investment_cash_entries', [
            'type' => CashEntryType::SaleProceeds->value,
            'amount' => '4500.00',
            'source_type' => 'order_payment',
            'source_id' => 7,
        ]);
    }

    public function test_an_amount_is_always_positive(): void
    {
        // Arrange — الاتجاهُ في النوع، فلا معنى لمبلغٍ سالبٍ ولا لصفرٍ.
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_cash_entries')->insert($this->entry([
            'type' => CashEntryType::Purchase->value,
            'amount' => '-10000.00',
            'source_type' => 'purchase_order',
        ]));
    }

    public function test_a_row_must_name_what_produced_it(): void
    {
        // Arrange — نقدٌ بلا مصدرٍ مالٌ لا يُعرف من أين جاء، ولا يُطابَق بورقة.
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_cash_entries')->insert($this->entry([
            'source_type' => null,
            'source_id' => null,
        ]));
    }

    public function test_one_event_is_posted_once(): void
    {
        // Arrange — الدفعةُ نفسُها عولجت مرّة.
        DB::table('investment_cash_entries')->insert($this->entry());

        // Assert
        $this->expectException(QueryException::class);

        // Act — ومرّةً ثانية: مهمّةٌ أُعيدت، أو حالةٌ مُشيت مرّتين.
        DB::table('investment_cash_entries')->insert($this->entry());
    }

    public function test_a_correction_may_name_the_same_source_again(): void
    {
        // Arrange — التصحيحُ عكسٌ ثم صفٌّ جديد يسمّي المصدر نفسه، و`source_sequence` يفرّق بينهما.
        DB::table('investment_cash_entries')->insert($this->entry());

        // Act
        DB::table('investment_cash_entries')->insert(
            $this->entry(['source_sequence' => 2, 'amount' => '4200.00'])
        );

        // Assert
        $this->assertSame(2, DB::table('investment_cash_entries')->count());
    }

    public function test_a_reversal_names_the_row_it_undoes_and_no_source(): void
    {
        // Arrange
        DB::table('investment_cash_entries')->insert($this->entry());
        $original = (int) DB::table('investment_cash_entries')->value('id');

        // Act
        DB::table('investment_cash_entries')->insert($this->entry([
            'type' => CashEntryType::Reversal->value,
            'source_type' => null,
            'source_id' => null,
            'reverses_entry_id' => $original,
        ]));

        // Assert
        $this->assertDatabaseHas('investment_cash_entries', [
            'type' => CashEntryType::Reversal->value,
            'reverses_entry_id' => $original,
            'amount' => '4500.00',
        ]);
    }

    public function test_a_row_is_never_reversed_twice(): void
    {
        // Arrange — ردَّان على صفٍّ واحد يضاعفان المال، وهو عطبٌ لا تلتقطه أيّ شاشة.
        DB::table('investment_cash_entries')->insert($this->entry());
        $original = (int) DB::table('investment_cash_entries')->value('id');
        $reversal = $this->entry([
            'type' => CashEntryType::Reversal->value,
            'source_type' => null,
            'source_id' => null,
            'reverses_entry_id' => $original,
        ]);
        DB::table('investment_cash_entries')->insert($reversal);

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_cash_entries')->insert($reversal);
    }

    public function test_a_reversal_without_a_target_is_refused(): void
    {
        // Arrange — «عكسٌ» لا يسمّي ما يعكسه ليس عكساً.
        $this->expectException(QueryException::class);

        // Act
        DB::table('investment_cash_entries')->insert($this->entry([
            'type' => CashEntryType::Reversal->value,
            'source_type' => null,
            'source_id' => null,
        ]));
    }
}
