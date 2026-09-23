<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * البابُ الذي تقرأ منه اللوحةُ الصندوقَ وتفتح منه فترة.
 *
 * الشريحة ١د من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class InvestmentFundEndpointTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    private function headersFor(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_a_period_past_its_date_says_how_many_days_it_has_been_due(): void
    {
        // Arrange — §٠.٤: غيابُ الجدولة صامت، فاللوحةُ تقول «مستحقّة الإقفال منذ ٣ أيام». انتهت
        // في ٣٠ سبتمبر، فهي مستحقّةٌ منذ أوّل أكتوبر.
        Carbon::setTestNow('2026-09-23 09:00:00');
        $headers = $this->headersFor([PermissionName::ViewInvestors, PermissionName::ManageInvestors]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        Carbon::setTestNow('2026-10-04 09:00:00');

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period.is_due_to_close', true)
            ->assertJsonPath('data.period.overdue_days', 3);

        Carbon::setTestNow();
    }

    public function test_a_period_still_inside_its_dates_is_not_overdue(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-23 09:00:00');
        $headers = $this->headersFor([PermissionName::ViewInvestors, PermissionName::ManageInvestors]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        Carbon::setTestNow('2026-09-30 20:00:00');

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period.is_due_to_close', false)
            ->assertJsonPath('data.period.overdue_days', null);

        Carbon::setTestNow();
    }

    /** طلبيةٌ سحبت من رفّ الصندوق ولم تصل العميل بعد. */
    private function orderInFlight(string $placedAt): Order
    {
        $deal = app(FundDeal::class)();

        $item = StockItem::factory()->named('رفّ الصندوق '.fake()->unique()->numberBetween(1, 99999))->create();
        $batch = StockBatch::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'stock_item_id' => $item->getKey(),
        ]);
        $movement = StockMovement::factory()->create([
            'movement_type' => 'order_fulfillment',
            'stock_item_id' => $item->getKey(),
        ]);

        StockBatchConsumption::factory()->create([
            'stock_batch_id' => $batch->getKey(),
            'stock_movement_id' => $movement->getKey(),
        ]);

        $order = Order::factory()->create([
            'placed_at' => $placedAt,
            'status' => 'out_for_delivery',
        ]);

        OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'fulfillment_stock_movement_id' => $movement->getKey(),
        ]);

        return $order;
    }

    public function test_the_dashboard_lists_the_periods_still_waiting_for_their_orders(): void
    {
        // Arrange — §١٢هـ: «تبقى بلا حدّ، واللوحةُ تصرخ». سبتمبر أُقفل في موعده وبقيت له طلبيةٌ
        // في الطريق، وأكتوبر يجري فوقه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        app(OpenInvestmentPeriod::class)(actorId: null);
        $this->orderInFlight('2026-09-28 10:00:00');
        Carbon::setTestNow('2026-10-02 09:00:00');
        app(CloseInvestmentPeriod::class)(actorId: null);
        app(OpenInvestmentPeriod::class)(actorId: null);
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period.starts_on', '2026-10-01')
            ->assertJsonPath('data.period.owed_orders', null)
            ->assertJsonCount(1, 'data.waiting_periods')
            ->assertJsonPath('data.waiting_periods.0.status', 'closing')
            ->assertJsonPath('data.waiting_periods.0.status_label', 'قيد الإغلاق')
            ->assertJsonPath('data.waiting_periods.0.owed_orders', 1);

        Carbon::setTestNow();
    }

    public function test_closing_a_period_that_still_waits_says_so_rather_than_closed(): void
    {
        // Arrange — §٠.٧: تنتهي في موعدها ولو بقيت لها طلبية. «أُفرج عن الأرباح» كذبٌ هنا.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([PermissionName::ViewInvestors, PermissionName::ManageInvestors]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $this->orderInFlight('2026-09-28 10:00:00');
        Carbon::setTestNow('2026-10-02 09:00:00');

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.status', 'closing')
            ->assertJsonPath('data.owed_orders', 1);
        $this->assertStringContainsString('قيد الإغلاق', $response->json('message'));
        $this->assertStringNotContainsString('أُفرج عن الأرباح', $response->json('message'));

        Carbon::setTestNow();
    }

    public function test_a_fund_with_no_period_says_so_rather_than_inventing_one(): void
    {
        // Arrange — صندوقٌ لم تُفتح فيه فترةٌ بعد.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period', null)
            ->assertJsonPath('data.valuation.total', '0.00');
    }

    public function test_the_value_arrives_broken_into_its_parts(): void
    {
        // Arrange — المجموعُ وحده ادّعاء؛ من يقرأ رقماً يحتاج أن يعرف من أين جاء.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '1400.000',
            'unit_cost' => '10.000',
        ]);

        DB::table('investment_cash_entries')->insert([
            'type' => 'deposit', 'amount' => '12000.00',
            'source_type' => 'investor_wallet_entry', 'source_id' => 1, 'source_sequence' => 1,
            'occurred_at' => now(), 'created_at' => now(), 'updated_at' => now(),
        ]);

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.valuation.cash', '12000.00')
            ->assertJsonPath('data.valuation.stock_on_shelf', '14000.00')
            ->assertJsonPath('data.valuation.total', '26000.00');
    }

    public function test_opening_a_period_needs_the_authority_that_moves_investors_money(): void
    {
        // Arrange — القراءةُ وحدها لا تكفي: فتحُ فترةٍ يقرّر بأيّ نسبٍ يُقسَّم ربحُ شهر.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods');

        // Assert
        $response->assertForbidden();
    }

    public function test_the_first_period_opens_on_what_the_fund_already_holds(): void
    {
        // Arrange — وهذا هو «لا تصفير»: الفترةُ تبدأ على رصيدٍ لا على صفر.
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $deal = InvestorDeal::factory()->create();

        StockBatch::factory()->create([
            'investor_deal_id' => $deal->id,
            'quantity_remaining' => '1400.000',
            'unit_cost' => '10.000',
        ]);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.opening_stock_cost', '14000.00')
            ->assertJsonPath('data.investor_profit_share_percent', '50.00');

        $this->assertDatabaseCount('investment_periods', 1);
    }

    public function test_a_second_period_is_refused_while_the_first_runs(): void
    {
        // Arrange
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods');

        // Assert — رسالةٌ تُقرأ، لا خطأُ فهرسٍ بخمسمئة.
        $response->assertStatus(422);
        $this->assertStringContainsString('ما زالت مفتوحة', $response->json('message'));
        $this->assertDatabaseCount('investment_periods', 1);
    }

    public function test_closing_from_the_screen_releases_the_profit(): void
    {
        // Arrange — فترةٌ انتهت نافذتُها، وربحٌ متراكم.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        Carbon::setTestNow('2026-10-15 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close');

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'closed');
        $this->assertStringContainsString('رأسُ المال والبضاعة في مكانهما', $response->json('message'));
    }

    public function test_an_early_close_without_a_reason_is_refused_with_words(): void
    {
        // Arrange — أوّلُ فترةٍ فُتحت في ١٥ سبتمبر تنتهي في ٣٠ منه، فالخامسُ والعشرون قبل موعدها.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        Carbon::setTestNow('2026-09-25 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close');

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString('ما زالت تستقبل', $response->json('message'));
    }

    public function test_a_one_word_reason_is_not_a_reason(): void
    {
        // Arrange — التجاوزُ يُكتب كاملاً ليُقرأ بعد سنة، لا كلمةً تمرّ.
        Carbon::setTestNow('2026-09-15 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        // Act
        Carbon::setTestNow('2026-10-02 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close', [
            'override_reason' => 'خلاص',
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('override_reason');
    }

    public function test_a_partner_row_carries_what_he_put_in_the_fund_not_everything_he_owns(): void
    {
        // Arrange — رجلٌ في محفظته عشرةُ آلاف اشترك بثلاثةٍ منها. السبعةُ الباقية مالُه عندنا
        // ولا تموّل هذا الصندوق، فلا تقف في سطرِ شركائه.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '10000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id, 'amount' => '3000',
        ])->assertOk();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert — ما في الصندوق وحده؛ ولو كان المجموعَ لقرأ الشريكُ نسبةً لا يفسّرها رأسُ مالها.
        $response->assertOk()
            ->assertJsonPath('data.investors.0.investor_id', $investor->id)
            ->assertJsonPath('data.investors.0.capital', '3000.00');
    }

    /** إيداعٌ نقديّ على الطاولة — ما يملأ المحفظة قبل أن يُشترك به. */
    private function fundWallet(array $headers, int $investorId, string $amount): void
    {
        $this->withHeaders($headers)->postJson("/api/v1/investors/{$investorId}/wallet", [
            'type' => 'deposit',
            'amount' => $amount,
            'method' => 'cash',
        ])->assertSuccessful();
    }

    public function test_a_deposit_from_the_screen_buys_units_and_says_what_it_bought(): void
    {
        // Arrange — الشريحتان ٣ و٤ من الشاشة: بابٌ واحد يكتب في ثلاثة دفاتر.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '5000');

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id,
            'amount' => '5000',
        ]);

        // Assert — الوحداتُ بسعر الافتتاح، والحبسُ سنةٌ من يومه.
        $response->assertOk()
            ->assertJsonPath('data.units', '5000.000000')
            ->assertJsonPath('data.unit_price', '1.000000')
            ->assertJsonPath('data.locked_until', '2027-09-01');

        $this->assertDatabaseHas('investment_cash_entries', ['type' => 'deposit', 'amount' => '5000.00']);
    }

    public function test_the_dashboard_carries_the_unit_price_and_who_holds_what(): void
    {
        // Arrange — الشاشةُ تحتاج السعرَ قبل أن تقبض، والنسبَ ليقرأها الشركاء.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        $big = Investor::factory()->create();
        $small = Investor::factory()->create();

        foreach ([[$big, '3000'], [$small, '1000']] as [$investor, $amount]) {
            $this->fundWallet($headers, (int) $investor->id, $amount);
            $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
                'investor_id' => $investor->id, 'amount' => $amount,
            ])->assertOk();
        }

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.units_outstanding', '4000.000000')
            ->assertJsonPath('data.investors.0.investor_id', $big->id)
            ->assertJsonPath('data.investors.0.share_percent', '75.000000')
            ->assertJsonPath('data.investors.1.share_percent', '25.000000')
            ->assertJsonPath('data.valuation.cash', '4000.00')
            // وأوّلُ فترةٍ في عمر الصندوق تُدخَل من نافذتها هي، فلا تقول الشاشةُ «للقادمة».
            ->assertJsonPath('data.period.subscription_serves_next_period', false);
    }

    public function test_the_dashboard_says_the_window_feeds_the_next_period_and_who_waits_for_it(): void
    {
        // Arrange — فترةٌ ثانية: من اكتتب في نافذتها مالُه في الصندوق ونصيبُه من التي بعدها.
        // «تجمد نسبته ولا تحسب له أرباح شهر تسعة إنما تحسب له أرباح شهر عشرة» — والشاشةُ تقولها
        // بدل أن تضع «٠٫٠٠٪» بجانب اسمه بلا تفسير.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        $founder = Investor::factory()->create();
        $this->fundWallet($headers, (int) $founder->id, '3000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $founder->id, 'amount' => '3000',
        ])->assertOk();

        Carbon::setTestNow('2026-10-02 09:00:00');
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods/close')->assertOk();
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();

        $newcomer = Investor::factory()->create();
        $this->fundWallet($headers, (int) $newcomer->id, '1000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $newcomer->id, 'amount' => '1000',
        ])->assertOk();

        // Act
        $response = $this->withHeaders($headers)->getJson('/api/v1/investment/fund');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period.subscription_serves_next_period', true)
            ->assertJsonPath('data.investors.0.investor_id', $founder->id)
            ->assertJsonPath('data.investors.0.share_percent', '100.000000')
            ->assertJsonPath('data.investors.0.share_starts_next_period', false)
            ->assertJsonPath('data.investors.1.investor_id', $newcomer->id)
            ->assertJsonPath('data.investors.1.share_percent', '0.000000')
            ->assertJsonPath('data.investors.1.share_starts_next_period', true)
            // وفي التالية يقف الاثنان بوحداتهما — ما تعرضه صفحةُ «الشركاء» تحت «الفترة القادمة».
            ->assertJsonPath('data.investors.0.next_share_percent', '75.000000')
            ->assertJsonPath('data.investors.1.next_share_percent', '25.000000');
    }

    public function test_a_withdrawal_needs_the_lock_to_have_run_out(): void
    {
        // Arrange
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '5000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id, 'amount' => '5000',
        ])->assertOk();

        // Act
        Carbon::setTestNow('2026-12-01 09:00:00');
        $response = $this->withHeaders($headers)->postJson('/api/v1/investment/withdrawals', [
            'investor_id' => $investor->id, 'amount' => '1000',
        ]);

        // Assert — رسالةٌ تقول متى، لا «ممنوع» وحدها.
        $response->assertStatus(422);
        $this->assertStringContainsString('محبوس', $response->json('message'));
        $this->assertStringContainsString('2027-09-01', $response->json('message'));
    }

    public function test_reversing_a_deposit_takes_its_units_and_its_cash_with_it(): void
    {
        // Arrange — الشريحة ٠ب. وإبطالُ الإيداع بلا إبطال وحداته يترك رجلاً استُرجع مالُه
        // وبقيت نسبتُه تقاسم ربحاً لا يموّله.
        Carbon::setTestNow('2026-09-01 09:00:00');
        $headers = $this->headersFor([
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
        ]);
        $this->withHeaders($headers)->postJson('/api/v1/investment/periods')->assertOk();
        $investor = Investor::factory()->create();
        $this->fundWallet($headers, (int) $investor->id, '5000');
        $this->withHeaders($headers)->postJson('/api/v1/investment/deposits', [
            'investor_id' => $investor->id, 'amount' => '5000',
        ])->assertOk();

        $entryId = (int) DB::table('investor_wallet_entries')->where('type', 'allocation')->value('id');

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/investors/{$investor->id}/wallet/{$entryId}/reversal");

        // Assert — الدفاتر الثلاثة رجعت معاً.
        $response->assertOk();
        $this->assertSame('0.000000', app(FundUnits::class)->outstanding());
        $this->assertSame('0.00', app(FundCash::class)());

        // ورأسُ ماله في محفظته كما كان قبل الاشتراك — لم يضِع ولم يُضاعَف. وهذا هو الفرق الذي
        // صنعه `allocation` بدل `deposit`: الإبطالُ يعيده إلى حيث كان، لا يمحوه.
        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->id);
        $this->assertSame('5000.00', $balances['wallet']['capital']);
        $this->assertSame('0.00', $balances['deals'][app(FundDeal::class)()->id]['capital']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();

        parent::tearDown();
    }
}
