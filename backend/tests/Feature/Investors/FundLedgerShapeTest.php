<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * شكلُ الدفتر حين يصير المالُ للصندوق لا لصفقةٍ بعينها.
 *
 * الشريحة الأولى من تحويل الصفقات إلى صندوقٍ مستمرّ
 * ({@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}) لا تبني شيئاً يُرى — تفتح البابَ في
 * القاعدة وتُغلق ثغرةً فيه، والاثنان في ترحيلٍ واحد لأن فتحَ أحدهما بلا الآخر هو العطب بعينه.
 *
 * **البابُ:** قيدُ `_shape` اليوم يشترط `investor_deal_id IS NOT NULL` على كل نوعٍ يخصّ صفقة،
 * فصندوقٌ بلا صفقات يرتدّ على مستوى قاعدة البيانات لا في فعلٍ يمكن تعديله.
 *
 * **الثغرةُ:** الفهرسُ الذي يمنع دفعَ الطلبية مرّتين يحمل `investor_deal_id` في مفتاحه، و
 * Postgres يعتبر `NULL` مختلفاً عن `NULL` في الفهارس الفريدة. فأولُ صفٍّ للصندوق يُسقط الحمايةَ
 * كلَّها بصمت: مستمعٌ يعمل مرّتين يكتب صفَّي ربحٍ بـ٧٥٠ لكلٍّ منهما، ويقبلهما الفهرس، ويُدفع
 * ١٬٥٠٠ عن ربحٍ قدرُه ٧٥٠ — ولا شاشةَ تُظهر الفرق لأن كل رصيدٍ في هذه الميزة مشتقٌّ من الصفوف.
 *
 * والاختبار يكتب في الجدول مباشرةً لا عبر فعلٍ: **الضمانةُ المقصودة ضمانةُ قاعدة بيانات**، وفعلٌ
 * يحرسها في PHP هو ما نريد ألّا نعتمد عليه.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class FundLedgerShapeTest extends TestCase
{
    use RefreshDatabase;

    /**
     * صفٌّ في دفتر المحافظ، افتراضُه ربحُ الصندوق من الطلبية ٩١.
     *
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function entry(int $investorId, array $overrides = []): array
    {
        return array_merge([
            'investor_id' => $investorId,
            'investor_deal_id' => null,
            'type' => WalletEntryType::Profit->value,
            'amount' => '750.00',
            'method' => null,
            'source_type' => 'order',
            'source_id' => 91,
            'source_sequence' => 1,
            'occurred_at' => now(),
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides);
    }

    public function test_the_fund_may_earn_for_an_investor_without_any_deal(): void
    {
        // Arrange — مستثمرٌ وحده، بلا صفقةٍ في النظام إطلاقاً.
        $investor = Investor::factory()->create();

        // Act
        DB::table('investor_wallet_entries')->insert(
            $this->entry((int) $investor->getKey())
        );

        // Assert
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->getKey(),
            'investor_deal_id' => null,
            'type' => WalletEntryType::Profit->value,
            'amount' => '750.00',
        ]);
    }

    public function test_capital_may_enter_the_fund_without_naming_a_deal(): void
    {
        // Arrange — `allocation` تعني اليوم «تمويلُ صفقة»، وتصير «دخولٌ إلى الصندوق».
        $investor = Investor::factory()->create();

        // Act
        DB::table('investor_wallet_entries')->insert($this->entry(
            (int) $investor->getKey(),
            [
                'type' => WalletEntryType::Allocation->value,
                'amount' => '20000.00',
                'source_type' => null,
                'source_id' => null,
            ],
        ));

        // Assert
        $this->assertDatabaseHas('investor_wallet_entries', [
            'investor_id' => $investor->getKey(),
            'investor_deal_id' => null,
            'type' => WalletEntryType::Allocation->value,
        ]);
    }

    public function test_the_fund_pays_one_investor_once_for_one_source(): void
    {
        // Arrange — الصفُّ الأول مقبول؛ وهو الحالة التي كان الفهرسُ القديم يعميها.
        $investor = Investor::factory()->create();
        DB::table('investor_wallet_entries')->insert(
            $this->entry((int) $investor->getKey())
        );

        // Assert — يُعلَن قبل الفعل لأن الفعل هو الذي يرمي.
        $this->expectException(QueryException::class);

        // Act — المستمعُ نفسُه يعمل مرّة ثانية على الطلبية نفسها.
        DB::table('investor_wallet_entries')->insert(
            $this->entry((int) $investor->getKey())
        );
    }

    public function test_a_correction_may_name_the_same_source_again(): void
    {
        // Arrange — التصحيحُ عكسٌ ثم صفٌّ جديد يسمّي الطلبية نفسها، و`source_sequence` هو ما
        // يفرّق بينهما. لو حمل المفتاحُ الطلبيةَ وحدها لرُفض كلُّ تصحيح.
        $investor = Investor::factory()->create();
        DB::table('investor_wallet_entries')->insert(
            $this->entry((int) $investor->getKey())
        );

        // Act
        DB::table('investor_wallet_entries')->insert($this->entry(
            (int) $investor->getKey(),
            ['source_sequence' => 2, 'amount' => '640.00'],
        ));

        // Assert
        $this->assertSame(2, DB::table('investor_wallet_entries')
            ->where('investor_id', $investor->getKey())
            ->count());
    }

    public function test_a_reversed_row_leaves_the_key_free_for_its_replacement(): void
    {
        // Arrange — الحذفُ الناعم يُخرج الصفَّ من الفهرس، وهو كيف يُصحَّح رقمٌ بالتسلسل نفسه.
        $investor = Investor::factory()->create();
        DB::table('investor_wallet_entries')->insert($this->entry(
            (int) $investor->getKey(),
            ['deleted_at' => now()],
        ));

        // Act
        DB::table('investor_wallet_entries')->insert(
            $this->entry((int) $investor->getKey())
        );

        // Assert
        $this->assertSame(1, DB::table('investor_wallet_entries')
            ->where('investor_id', $investor->getKey())
            ->whereNull('deleted_at')
            ->count());
    }

    public function test_the_old_per_deal_guarantee_is_untouched(): void
    {
        // Arrange — تاريخُ الصفقات يبقى محروساً بفهرسه هو: صفقةٌ واحدة لا تدفع الطلبية مرّتين.
        $investor = Investor::factory()->create();
        $deal = InvestorDeal::factory()->create();
        DB::table('investor_wallet_entries')->insert($this->entry(
            (int) $investor->getKey(),
            ['investor_deal_id' => $deal->getKey()],
        ));

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('investor_wallet_entries')->insert($this->entry(
            (int) $investor->getKey(),
            ['investor_deal_id' => $deal->getKey()],
        ));
    }
}
