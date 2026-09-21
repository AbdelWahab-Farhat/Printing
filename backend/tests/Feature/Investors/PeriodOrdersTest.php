<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * طلبياتُ الفترة الواحدة — «أيُّ طلبيةٍ أعطت المستثمرين ربحاً، وكم أخذ كلُّ واحد منها».
 *
 * شاشةُ الفترة الواحدة من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٤.٣.
 *
 * **والمصدرُ الدفترُ لا حسابٌ ثانٍ.** ما يظهر هنا هو ما قُيِّد في محافظ الناس فعلاً، مختوماً
 * بهذه الفترة؛ وأيُّ إعادةِ حسابٍ من الـFIFO كانت ستُنتج رقماً ثانياً يخالف ما قُبض به يوم
 * أُقفلت الفترة.
 *
 * Arrange - Act - Assert في كلٍّ منها.
 */
class PeriodOrdersTest extends TestCase
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

    /** ربحٌ يُكتب كما يكتبه `PostDealShare`: بمصدره وختمِ فترته. */
    private function accrue(
        int $investorId,
        int $dealId,
        string $amount,
        string $sourceType,
        int $sourceId,
        ?int $periodId,
        WalletEntryType $type = WalletEntryType::Profit,
    ): InvestorWalletEntry {
        $entry = new InvestorWalletEntry(['amount' => $amount, 'occurred_at' => now()]);

        $entry->investor_id = $investorId;
        $entry->investor_deal_id = $dealId;
        $entry->type = $type;
        $entry->source_type = $sourceType;
        $entry->source_id = $sourceId;
        $entry->source_sequence = 1;
        $entry->investment_period_id = $periodId;
        $entry->save();

        return $entry;
    }

    /**
     * فترةٌ بنافذةٍ بعينها — نافذتان لا تتداخلان في القاعدة، فمن يحتاج فترتين يرسم مداهما.
     */
    private function periodOver(string $starts, string $ends, string $subscriptionCloses): InvestmentPeriod
    {
        return InvestmentPeriod::factory()->create([
            'starts_on' => $starts,
            'ends_on' => $ends,
            'subscription_closes_on' => $subscriptionCloses,
        ]);
    }

    /**
     * تُقفَل بأرقامٍ مجمّدة — لا لأن الاختبار يقرؤها، بل لأن «مفتوحةً واحدة» قيدٌ في القاعدة
     * وقيدَ `_shape` يشترط أرقامَ الإقفال كلَّها معاً.
     */
    private function seal(InvestmentPeriod $period): void
    {
        $period->forceFill([
            'status' => PeriodStatus::Closed,
            'closed_at' => now(),
            'closing_stock_cost' => '0.00',
            'closing_cash' => '0.00',
            'sales_revenue' => '0.00',
            'cost_of_goods_sold' => '0.00',
            'cost_damaged' => '0.00',
            'cost_short' => '0.00',
            'expenses_amount' => '0.00',
            'net_profit' => '0.00',
            'investors_pool' => '0.00',
            'company_share' => '0.00',
            'through_consumption_id' => 0,
            'through_movement_id' => 0,
            'through_wallet_entry_id' => 0,
            'through_cash_entry_id' => 0,
        ])->save();
    }

    /** العكسُ كما يكتبه `PostDealShare::reverse()` — بلا مصدرٍ خاصّ به، وبفترةٍ قد تختلف. */
    private function reverse(InvestorWalletEntry $original, ?int $periodId): InvestorWalletEntry
    {
        $reversal = new InvestorWalletEntry([
            'amount' => (string) $original->amount,
            'occurred_at' => now(),
        ]);

        $reversal->investor_id = $original->investor_id;
        $reversal->investor_deal_id = $original->investor_deal_id;
        $reversal->investment_period_id = $periodId;
        $reversal->type = WalletEntryType::Reversal;
        $reversal->reverses_entry_id = $original->getKey();
        $reversal->save();

        return $reversal;
    }

    public function test_the_period_lists_each_order_that_paid_its_investors_and_what_each_one_took(): void
    {
        // Arrange — طلبيةٌ واحدة قُسِّم ربحُها على شريكين بنسبِ فترتها.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $period = InvestmentPeriod::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $salem = Investor::factory()->create(['name' => 'سالم']);
        $order = Order::factory()->create();

        $this->accrue((int) $ahmad->id, (int) $deal->id, '562.50', 'order', (int) $order->id, (int) $period->id);
        $this->accrue((int) $salem->id, (int) $deal->id, '187.50', 'order', (int) $order->id, (int) $period->id);

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert — صفٌّ واحد للطلبية، ومجموعُها وتفصيلُه على من أخذه.
        $response->assertOk()
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', (int) $order->id)
            ->assertJsonPath('data.orders.0.code', (string) $order->code)
            ->assertJsonPath('data.orders.0.investors_total', '750.00')
            ->assertJsonCount(2, 'data.orders.0.investors')
            ->assertJsonPath('data.orders.0.investors.0.name', 'أحمد')
            ->assertJsonPath('data.orders.0.investors.0.amount', '562.50')
            ->assertJsonPath('data.orders.0.investors.1.name', 'سالم')
            ->assertJsonPath('data.orders.0.investors.1.amount', '187.50');
    }

    public function test_the_totals_are_the_rows_added_up_and_nothing_else(): void
    {
        // Arrange — طلبيتان، ومجموعُ كلِّ مستثمرٍ في الفترة مشيُ صفوفها هي لا استعلامٌ ثانٍ.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $period = InvestmentPeriod::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $first = Order::factory()->create();
        $second = Order::factory()->create();

        $this->accrue((int) $ahmad->id, (int) $deal->id, '300.00', 'order', (int) $first->id, (int) $period->id);
        $this->accrue((int) $ahmad->id, (int) $deal->id, '200.00', 'order', (int) $second->id, (int) $period->id);

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.totals.orders', 2)
            ->assertJsonPath('data.totals.investors_total', '500.00')
            ->assertJsonCount(1, 'data.investors')
            ->assertJsonPath('data.investors.0.name', 'أحمد')
            ->assertJsonPath('data.investors.0.amount', '500.00');
    }

    public function test_an_order_stamped_with_another_period_is_not_on_this_ones_list(): void
    {
        // Arrange — «كل طلبية في سبتمبر هي ل سبتمبر»: الختمُ يفصل، لا تاريخُ القراءة.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $september = $this->periodOver('2026-09-01', '2026-09-30', '2026-09-07');
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $mine = Order::factory()->create();
        $theirs = Order::factory()->create();

        $this->accrue((int) $ahmad->id, (int) $deal->id, '300.00', 'order', (int) $mine->id, (int) $september->id);

        $this->seal($september);
        $october = $this->periodOver('2026-10-01', '2026-10-31', '2026-10-07');

        $this->accrue((int) $ahmad->id, (int) $deal->id, '900.00', 'order', (int) $theirs->id, (int) $october->id);

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$september->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', (int) $mine->id)
            ->assertJsonPath('data.totals.investors_total', '300.00');
    }

    public function test_an_order_reversed_inside_its_own_period_drops_off_the_list(): void
    {
        // Arrange — قُيِّد ثم أُبطل في الفترة نفسها: لم يُعطِ أحداً شيئاً، وصفٌّ بـ«0.00» يقول
        // إنه تعادل — وهي جملةٌ أخرى.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $period = InvestmentPeriod::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $order = Order::factory()->create();

        $entry = $this->accrue((int) $ahmad->id, (int) $deal->id, '300.00', 'order', (int) $order->id, (int) $period->id);
        $this->reverse($entry, (int) $period->id);

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonCount(0, 'data.orders')
            ->assertJsonPath('data.totals.investors_total', '0.00');
    }

    public function test_a_correction_to_a_closed_period_shows_on_the_period_it_landed_in(): void
    {
        // Arrange — سبتمبر أُقفل وخرج مالُه؛ العكسُ يقع على المفتوحة اليوم بأرضية
        // `PeriodForEntry::floorOf()`. فتُظهره أكتوبر بسالبه، وتبقى سبتمبر على أرقامها التي
        // قُبض بها.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $september = $this->periodOver('2026-09-01', '2026-09-30', '2026-09-07');
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $order = Order::factory()->create();

        $entry = $this->accrue((int) $ahmad->id, (int) $deal->id, '300.00', 'order', (int) $order->id, (int) $september->id);

        $this->seal($september);
        $october = $this->periodOver('2026-10-01', '2026-10-31', '2026-10-07');

        $this->reverse($entry, (int) $october->id);

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$october->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', (int) $order->id)
            ->assertJsonPath('data.orders.0.investors_total', '-300.00')
            ->assertJsonPath('data.orders.0.investors.0.amount', '-300.00');
    }

    public function test_the_plain_bag_road_lands_on_the_order_its_line_belongs_to(): void
    {
        // Arrange — هامشُ السادة يُقيَّد على **سطر** الطلبية لا عليها، ومن يقرأ الفترة يسأل عن
        // الطلبية. فلولا الردُّ إلى صاحبها لاختفت طلبيةٌ دفعت للمستثمرين فعلاً.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $period = InvestmentPeriod::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $order = Order::factory()->create();
        $line = OrderItem::factory()->create(['order_id' => $order->id]);

        $this->accrue((int) $ahmad->id, (int) $deal->id, '96.00', 'order_item', (int) $line->id, (int) $period->id);

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.order_id', (int) $order->id)
            ->assertJsonPath('data.orders.0.investors_total', '96.00');
    }

    public function test_the_release_of_profit_at_close_is_not_an_order_row(): void
    {
        // Arrange — `profit_release` تحريكُ الربح من الصفقة إلى المحفظة، لا ربحٌ من طلبية.
        // إدخالُها هنا كان سيطرح ما قُيِّد من نفسه فتقرأ الفترةُ صفراً.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);

        $period = InvestmentPeriod::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $ahmad = Investor::factory()->create(['name' => 'أحمد']);
        $order = Order::factory()->create();

        $this->accrue((int) $ahmad->id, (int) $deal->id, '300.00', 'order', (int) $order->id, (int) $period->id);

        $release = new InvestorWalletEntry(['amount' => '300.00', 'occurred_at' => now()]);
        $release->investor_id = $ahmad->id;
        $release->investor_deal_id = $deal->id;
        $release->investment_period_id = $period->id;
        $release->type = WalletEntryType::ProfitRelease;
        $release->save();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data.orders')
            ->assertJsonPath('data.orders.0.investors_total', '300.00')
            ->assertJsonPath('data.totals.investors_total', '300.00');
    }

    public function test_the_period_travels_with_its_orders(): void
    {
        // Arrange — الشاشةُ ترسم ترويسةَ الفترة فوق قائمتها، فلا نداءان لرسم شاشةٍ واحدة.
        $headers = $this->headersFor([PermissionName::ViewInvestors]);
        $period = InvestmentPeriod::factory()->create();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.period.id', (int) $period->id)
            ->assertJsonPath('data.period.code', (string) $period->code)
            ->assertJsonCount(0, 'data.orders');
    }

    public function test_reading_a_periods_orders_needs_permission_to_see_investors(): void
    {
        // Arrange — أرباحُ الناس بأسمائهم؛ البابُ خلف `investors.view` كبقية أبواب الصندوق.
        $headers = $this->headersFor([PermissionName::ViewOrders]);
        $period = InvestmentPeriod::factory()->create();

        // Act
        $response = $this->withHeaders($headers)
            ->getJson("/api/v1/investment/periods/{$period->id}/orders");

        // Assert
        $response->assertForbidden();
    }
}
