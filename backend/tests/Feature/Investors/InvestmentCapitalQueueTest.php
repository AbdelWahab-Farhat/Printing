<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Settings\Models\CompanySetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The grace window, and the queue behind it.
 *
 * **Why any of this exists**: ownership of a pool is a plain capital ratio, and that is only exact
 * if capital does not move inside a period. So money offered late joins the next period, and money
 * asked back leaves at the close. Everything below is a consequence of that one sentence.
 *
 * The properties that matter:
 *
 * 1. Inside the window, capital is taken **now** and works for the whole period.
 * 2. Outside it, **nothing moves** — the money stays in the investor's wallet, and he can still
 *    cancel and take it.
 * 3. The next period open lets the queue in.
 * 4. An exit is **always** queued, window or no window.
 * 5. An investor who spent the money meanwhile does not stop the period opening.
 *
 * Arrange - Act - Assert throughout.
 */
class InvestmentCapitalQueueTest extends TestCase
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
     * @return array<string, string>
     */
    private function banker(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
            PermissionName::RecordInvestorMoney->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function graceDays(int $days): void
    {
        CompanySetting::query()->whereKey(CompanySetting::SINGLETON_ID)
            ->update(['entry_grace_days' => $days]);
    }

    /** A pool with one period running the current calendar month. */
    private function poolWithPeriod(?string $startsOn = null): InvestorDeal
    {
        $pool = InvestorDeal::factory()->pool()->create();

        InvestmentPeriod::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => $startsOn ?? Carbon::today()->startOfMonth()->toDateString(),
            'ends_on' => Carbon::parse($startsOn ?? Carbon::today()->startOfMonth())
                ->addMonthNoOverflow()->subDay()->toDateString(),
        ]);

        return $pool;
    }

    /**
     * Marks the pool's open period closed, with the full snapshot the table demands.
     *
     * `CloseInvestmentPeriod` belongs to a later slice, and `investment_periods_closed_is_complete`
     * refuses a period that looks settled and carries no figures — so a test cannot simply flip the
     * status. It says «assume last month was closed» in the only shape the database accepts.
     */
    private function closeTheOpenPeriodOf(InvestorDeal $pool): void
    {
        $period = $pool->periods()->where('status', 'open')->firstOrFail();

        $period->forceFill(InvestmentPeriod::factory()->closed()->raw([
            'investor_deal_id' => $period->investor_deal_id,
            'starts_on' => $period->starts_on,
            'ends_on' => $period->ends_on,
        ]))->save();
    }

    private function investorHolding(string $amount): Investor
    {
        $investor = Investor::factory()->create();

        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );

        return $investor;
    }

    public function test_capital_offered_inside_the_window_goes_to_work_at_once(): void
    {
        // Arrange — the period began today, and there are three days of grace
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->toDateString());
        $investor = $this->investorHolding('50000.00');

        // Act
        $response = $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ]);

        // Assert — allocated, not queued
        $response->assertCreated();

        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->getKey());
        $this->assertSame('30000.00', $balances['deals'][$pool->getKey()]['capital']);
        $this->assertSame('20000.00', $balances['wallet']['capital']);

        $request = InvestmentCapitalRequest::query()->firstOrFail();
        $this->assertSame(CapitalRequestStatus::Applied, $request->status);
        $this->assertNotNull($request->applied_entry_id);
    }

    public function test_capital_offered_after_the_window_moves_nothing(): void
    {
        // Arrange — the period began ten days ago; the window shut after three
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->subDays(10)->toDateString());
        $investor = $this->investorHolding('50000.00');

        // Act
        $response = $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ]);

        // Assert — queued, and **his money is still his**: nothing is held anywhere
        $response->assertCreated();

        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->getKey());
        $this->assertSame('50000.00', $balances['wallet']['capital']);
        $this->assertArrayNotHasKey($pool->getKey(), $balances['deals']);

        $request = InvestmentCapitalRequest::query()->firstOrFail();
        $this->assertSame(CapitalRequestStatus::Pending, $request->status);
        $this->assertNull($request->applied_entry_id);
        $this->assertNull($request->effective_period_id);
    }

    public function test_zero_grace_days_makes_the_boundary_strict(): void
    {
        // Arrange — the behaviour the ownership arithmetic assumes; the period began yesterday
        $this->graceDays(0);
        $pool = $this->poolWithPeriod(Carbon::today()->subDay()->toDateString());
        $investor = $this->investorHolding('50000.00');

        // Act
        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ])->assertCreated();

        // Assert
        $this->assertSame(
            CapitalRequestStatus::Pending,
            InvestmentCapitalRequest::query()->firstOrFail()->status,
        );
    }

    public function test_the_last_day_of_the_window_is_still_inside_it(): void
    {
        // Arrange — «three days of grace» means three days a person can use, not two and a bit
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->subDays(3)->toDateString());
        $investor = $this->investorHolding('50000.00');

        // Act
        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ])->assertCreated();

        // Assert
        $this->assertSame(
            CapitalRequestStatus::Applied,
            InvestmentCapitalRequest::query()->firstOrFail()->status,
        );
    }

    public function test_the_next_period_lets_the_queue_in(): void
    {
        // Arrange — a man who missed the window
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->subDays(10)->toDateString());
        $investor = $this->investorHolding('50000.00');

        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ])->assertCreated();

        $this->closeTheOpenPeriodOf($pool);

        // Act — the boundary he was waiting for
        $result = app(InvestorService::class)->openPeriod($pool->fresh());

        // Assert
        $this->assertCount(1, $result['applied']);
        $this->assertSame([], $result['short']);

        $balances = app(InvestorBalances::class)->forInvestor((int) $investor->getKey());
        $this->assertSame('30000.00', $balances['deals'][$pool->getKey()]['capital']);

        $request = InvestmentCapitalRequest::query()->firstOrFail();
        $this->assertSame(CapitalRequestStatus::Applied, $request->status);
        $this->assertSame((int) $result['period']->getKey(), (int) $request->effective_period_id);
    }

    public function test_an_exit_is_always_queued_even_inside_the_window(): void
    {
        // Arrange — he is in the pool, and the window is wide open
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->toDateString());
        $investor = $this->investorHolding('50000.00');

        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Allocation,
                amount: '30000.00',
                investorDealId: (int) $pool->getKey(),
            ),
            null,
        );

        // Act
        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'out',
                'amount' => '10000',
            ])->assertCreated();

        // Assert — his capital has not moved: an exit waits for the close, so that a man who
        // asks to leave in September is still paid his September share
        $this->assertSame(
            CapitalRequestStatus::Pending,
            InvestmentCapitalRequest::query()->where('direction', 'out')->firstOrFail()->status,
        );
        $this->assertSame(
            '30000.00',
            app(InvestorBalances::class)->forInvestor((int) $investor->getKey())['deals'][$pool->getKey()]['capital'],
        );
    }

    public function test_a_queued_request_can_be_cancelled_and_nothing_is_unwound(): void
    {
        // Arrange
        $this->graceDays(0);
        $pool = $this->poolWithPeriod(Carbon::today()->subDay()->toDateString());
        $investor = $this->investorHolding('50000.00');

        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ])->assertCreated();

        $request = InvestmentCapitalRequest::query()->firstOrFail();

        // Act
        $this->withHeaders($this->banker())
            ->deleteJson("/api/v1/investment-capital-requests/{$request->getKey()}")
            ->assertOk();

        // Assert — no ledger row was ever written, so none had to be undone
        $this->assertSame(CapitalRequestStatus::Cancelled, $request->fresh()->status);
        $this->assertSame(
            '50000.00',
            app(InvestorBalances::class)->forInvestor((int) $investor->getKey())['wallet']['capital'],
        );
    }

    public function test_an_applied_request_cannot_be_cancelled(): void
    {
        // Arrange — the money has moved; undoing it is a reversal, not a cancellation
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->toDateString());
        $investor = $this->investorHolding('50000.00');

        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ])->assertCreated();

        $request = InvestmentCapitalRequest::query()->firstOrFail();

        // Act
        $response = $this->withHeaders($this->banker())
            ->deleteJson("/api/v1/investment-capital-requests/{$request->getKey()}");

        // Assert
        $response->assertStatus(422);
        $this->assertSame(CapitalRequestStatus::Applied, $request->fresh()->status);
    }

    public function test_an_empty_wallet_does_not_stop_the_period_opening(): void
    {
        // Arrange — he queues 30,000 in October and spends it before November
        $this->graceDays(0);
        $pool = $this->poolWithPeriod(Carbon::today()->subDays(5)->toDateString());
        $investor = $this->investorHolding('30000.00');

        $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/capital-requests", [
                'investor_id' => $investor->getKey(),
                'direction' => 'in',
                'amount' => '30000',
            ])->assertCreated();

        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Withdrawal,
                amount: '30000.00',
                method: 'cash',
            ),
            null,
        );

        $this->closeTheOpenPeriodOf($pool);

        // Act
        $result = app(InvestorService::class)->openPeriod($pool->fresh());

        // Assert — the period opened, his request is still queued, and somebody is told
        $this->assertSame([], $result['applied']);
        $this->assertCount(1, $result['short']);
        $this->assertSame(
            CapitalRequestStatus::Pending,
            InvestmentCapitalRequest::query()->firstOrFail()->status,
        );
    }

    public function test_the_pool_screen_says_what_will_happen_before_anybody_commits(): void
    {
        // Arrange — the whole promise of this feature: he is told before, not after
        $this->graceDays(3);
        $pool = $this->poolWithPeriod(Carbon::today()->subDays(10)->toDateString());

        // Act
        $response = $this->withHeaders($this->banker())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}");

        // Assert
        $response->assertOk();
        $timing = $response->json('data.capital_timing');

        $this->assertFalse($timing['is_inside_grace_window']);
        $this->assertSame(
            Carbon::today()->subDays(10)->addDays(3)->toDateString(),
            $timing['grace_window_ends_on'],
        );
        // The day his money would actually start working — the next period's first day
        $this->assertSame(
            Carbon::parse($pool->periods()->firstOrFail()->ends_on)->addDay()->toDateString(),
            $timing['capital_takes_effect_on'],
        );
    }

    public function test_a_pool_has_one_open_period_at_a_time(): void
    {
        // Arrange — «الفترة الحالية» must have one answer, or the window has two boundaries
        $pool = $this->poolWithPeriod();

        // Act
        $response = $this->withHeaders($this->banker())
            ->postJson("/api/v1/investment-pools/{$pool->getKey()}/periods");

        // Assert
        $response->assertStatus(422);
        $this->assertSame(1, $pool->periods()->count());
    }

    public function test_a_new_pool_can_take_capital_immediately(): void
    {
        // Arrange — born empty is the intention; born unable to receive anything is not
        $category = ProductCategory::factory()->create(['is_investable' => true]);
        $product = Product::factory()->create([
            'product_category_id' => $category->getKey(),
            'is_active' => true,
        ]);
        $stockItem = StockItem::factory()->create();
        ProductVariant::factory()->for($product)->create([
            'stock_item_id' => $stockItem->getKey(),
        ]);

        // Act
        $this->withHeaders($this->banker())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$stockItem->getKey()],
        ])->assertCreated();

        // Assert
        $pool = InvestorDeal::query()->where('name', 'ورق')->firstOrFail();
        $this->assertSame(1, $pool->periods()->where('status', 'open')->count());
    }
}
