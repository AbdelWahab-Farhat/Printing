<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\StockAdjustmentReason;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\DealExpenseKind;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use App\Domain\Investor\Models\InvestmentSettlement;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\SettlementSnapshot;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * التسوية — and the one thing it is for.
 *
 * ## Why the obvious test would be worthless
 *
 * The design's §6.5 identity reads `Σ capital + Σ undivided profit = deployable cash + stock at
 * cost`. Asked of `PoolDeployableCash` alone that is a **tautology**: it defines deployable cash as
 * book value less stock, so the two sides are one subtraction written backwards. A test asserting
 * it would pass on the day somebody wrote a lorry off the shelf by hand.
 *
 * So `SettlementSnapshot` rebuilds the right-hand side from the **movements** — the capital rows,
 * the earnings table, the expenses, every cost layer bought and every draw taken out of one — and
 * the tests below are about the two derivations agreeing *for a reason*:
 *
 * 1. A pool that has only traded: **drift is exactly zero**, mid-period and after a close.
 * 2. A loss absorbed by the company is a real injection, and is **named** rather than drifting.
 * 3. **A stock adjustment made outside the investment flow produces a non-zero drift** — the case
 *    the whole table exists for, and the one nothing else in the system would ever mention.
 * 4. A settlement **moves nothing**: no wallet row, no movement, no period touched.
 * 5. Undrawn profit is a liability and is never inside deployable cash.
 * 6. The open period's undivided profit is named, and never added to deployable cash.
 *
 * Arrange - Act - Assert throughout.
 */
class InvestmentSettlementTest extends TestCase
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
    private function settler(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
            PermissionName::RecordInvestorMoney->value,
            PermissionName::CloseInvestmentPeriods->value,
            PermissionName::RecordInvestmentSettlements->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * A pool with an open period and the given capital in it.
     *
     * @param  array<string, string>  $capitalByInvestor
     * @return array{pool: InvestorDeal, period: InvestmentPeriod, investors: array<string, Investor>}
     */
    private function pool(array $capitalByInvestor): array
    {
        $pool = InvestorDeal::factory()->pool()->create(['investor_profit_share_percent' => '50.00']);

        $period = InvestmentPeriod::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => now()->startOfMonth()->toDateString(),
            'ends_on' => now()->endOfMonth()->toDateString(),
        ]);

        // **The company's own investors row (§10).** Without it the operator's 50% cut is computed
        // and then has nowhere to be written, so it leaves the pool with no ledger entry — which
        // the snapshot correctly reports as drift. Every pool in production has this row; a test
        // arranging a pool without one is arranging a broken pool.
        Investor::factory()->create(['name' => 'الشركة', 'is_company' => true]);

        $service = app(InvestorService::class);
        $investors = [];

        foreach ($capitalByInvestor as $label => $amount) {
            $investor = Investor::factory()->create(['name' => (string) $label]);

            $service->recordWalletEntry(new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ), null);

            $service->recordWalletEntry(new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Allocation,
                amount: $amount,
                investorDealId: (int) $pool->getKey(),
            ), null);

            $investors[$label] = $investor;
        }

        return ['pool' => $pool->refresh(), 'period' => $period->refresh(), 'investors' => $investors];
    }

    /**
     * A lorry the pool paid for: a cost layer carrying it, on a real shelf.
     *
     * Built through `InventoryService` so the warehouse balance is real and a later adjustment can
     * actually draw on it — a hand-written layer would let the write-off test pass against nothing.
     */
    private function lorry(InvestorDeal $pool, string $quantity, string $unitCost): array
    {
        $item = StockItem::factory()->unit(PricingUnit::Piece)->create();
        $warehouse = Warehouse::factory()->create();

        app(InventoryService::class)->recordMovement(StockMovementData::arrival([
            'stock_item_id' => $item->getKey(),
            'to_warehouse_id' => $warehouse->getKey(),
            'quantity' => $quantity,
            'unit_cost' => $unitCost,
        ], (int) User::factory()->create()->getKey()));

        StockBatch::query()
            ->where('stock_item_id', $item->getKey())
            ->update(['investor_deal_id' => $pool->getKey()]);

        return ['item' => $item, 'warehouse' => $warehouse];
    }

    /**
     * Goods leaving the shelf as a sale: the draw, and the margin it earned the pool.
     *
     * The draw is written at the seam `DealStockPosition` reads — a fulfillment movement and its
     * FIFO consumption — because what is under test is the snapshot, not the order state machine.
     */
    private function sell(
        array $lorry,
        InvestorDeal $pool,
        InvestmentPeriod $period,
        string $quantity,
        string $cost,
        string $margin,
        int $sourceId = 1,
    ): void {
        $movement = StockMovement::factory()
            ->fulfillment($lorry['warehouse'])
            ->create([
                'stock_item_id' => $lorry['item']->getKey(),
                'quantity' => $quantity,
            ]);

        $batch = StockBatch::query()
            ->where('stock_item_id', $lorry['item']->getKey())
            ->where('investor_deal_id', $pool->getKey())
            ->firstOrFail();

        StockBatchConsumption::factory()->create([
            'stock_batch_id' => $batch->getKey(),
            'stock_movement_id' => $movement->getKey(),
            'quantity' => $quantity,
            'unit_cost' => $batch->unit_cost,
            'total_cost' => $cost,
        ]);

        $batch->quantity_remaining = bcsub((string) $batch->quantity_remaining, $quantity, 3);
        $batch->save();

        InvestmentRealizedEarning::factory()->create([
            'investment_period_id' => $period->getKey(),
            'source_type' => AuditSubject::Order->value,
            'source_id' => $sourceId,
            'amount' => $margin,
        ]);
    }

    private function snapshot(InvestorDeal $pool): array
    {
        return app(SettlementSnapshot::class)((int) $pool->getKey());
    }

    public function test_a_pool_that_has_only_traded_has_no_drift(): void
    {
        // Arrange — 100,000 in, a 60,000 lorry, half of it sold at a 10,000 margin
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        // Act
        $figures = $this->snapshot($setup['pool']);

        // Assert — the two derivations agree to the fils
        $this->assertSame('0.00', $figures['drift']);

        // And they agree for the right reasons: cash really is 100,000 − 60,000 + 30,000 + 10,000
        $this->assertSame('30000.00', $figures['stock_at_cost']);
        $this->assertSame('80000.00', $figures['reconstructed_cash']);
        $this->assertSame('10000.00', $figures['undeployed_current_profit']);
    }

    public function test_the_identity_survives_a_close(): void
    {
        // Arrange — the boundary the design's §6.5 note is about: every period releases all its
        // profit, so book value collapses to Σ capital and there is no retained value
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Act
        $figures = $this->snapshot($setup['pool']);

        // Assert
        $this->assertSame('0.00', $figures['drift']);
        // The profit has left the pool for the wallets — it is a liability now, not capital
        $this->assertSame('10000.00', $figures['distributed_profit_to_date']);
        $this->assertSame('0.00', $figures['undeployed_current_profit']);
        $this->assertSame('10000.00', $figures['liabilities']);
    }

    public function test_an_expense_moves_both_sides_together(): void
    {
        // Arrange — an expense is cash out AND a subtraction from net profit. Counted on one side
        // only it would read as drift for ever.
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        app(InvestorService::class)->recordDealExpense(
            $setup['pool'],
            new DealExpenseData(
                kind: DealExpenseKind::Storage,
                name: 'تخزين',
                amount: '1000.00',
                incurredOn: now()->toDateString(),
            ),
            null,
        );

        // Act
        $figures = $this->snapshot($setup['pool']);

        // Assert
        $this->assertSame('0.00', $figures['drift']);
        $this->assertSame('9000.00', $figures['undeployed_current_profit']);
        $this->assertSame('79000.00', $figures['reconstructed_cash']);
    }

    public function test_a_write_off_outside_the_investment_flow_is_reported_as_drift(): void
    {
        // Arrange — **the case this whole table exists for.** Somebody writes damaged goods off
        // straight through Inventory in a period that then closes, so no loss is ever charged to
        // anybody. The goods leave the shelf, the pool's apparent cash rises by their cost, and
        // nothing else in the system would ever mention it.
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Now, in the *new* period, a write-off dated back inside the period that already closed.
        // Its damage cost will never be subtracted from anybody's profit: the period that would
        // have charged it is immutable.
        $movement = app(InventoryService::class)->recordMovement(StockMovementData::adjustment([
            'stock_item_id' => $lorry['item']->getKey(),
            'warehouse_id' => $lorry['warehouse']->getKey(),
            'direction' => 'decrease',
            'quantity' => '500.000',
            'adjustment_reason' => StockAdjustmentReason::Damage->value,
            'notes' => 'تالف',
        ], (int) User::factory()->create()->getKey()));

        StockMovement::query()->whereKey($movement->getKey())
            ->update(['created_at' => now()->subMonths(2), 'updated_at' => now()->subMonths(2)]);

        // Act
        $figures = $this->snapshot($setup['pool']);

        // Assert — 500 units at 10 left the shelf and nobody paid for them
        $this->assertSame('5000.00', $figures['damage_to_date']);
        $this->assertNotSame('0.00', $figures['drift']);
        $this->assertSame('5000.00', $figures['drift']);
    }

    public function test_a_settlement_moves_nothing(): void
    {
        // Arrange — the difference between this and a close. A close is an irreversible payout;
        // this is somebody signing a statement.
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        $walletBefore = InvestorWalletEntry::query()->count();
        $movementsBefore = StockMovement::query()->count();

        // Act
        $response = $this->withHeaders($this->settler())
            ->postJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/settlements", [
                'notes' => 'تسوية نصف سنوية',
            ]);

        // Assert
        $response->assertCreated();
        $this->assertSame($walletBefore, InvestorWalletEntry::query()->count());
        $this->assertSame($movementsBefore, StockMovement::query()->count());
        $this->assertSame('open', $setup['period']->fresh()->status->value);

        $settlement = InvestmentSettlement::query()->firstOrFail();
        $this->assertSame('0.00', (string) $settlement->drift);
        $this->assertSame('10000.00', (string) $settlement->undeployed_current_profit);
        $this->assertNotNull($settlement->code);
    }

    public function test_the_snapshot_and_the_signed_record_are_the_same_arithmetic(): void
    {
        // Arrange — a screen that asks somebody to sign a position must print the position that
        // gets signed. Two implementations is how a person approves one figure and the record
        // keeps another.
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        $headers = $this->settler();

        // Act
        $shown = $this->withHeaders($headers)
            ->getJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/settlement-snapshot");

        $signed = $this->withHeaders($headers)
            ->postJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/settlements", []);

        // Assert
        $shown->assertOk();
        $signed->assertCreated();

        foreach (['drift', 'stock_at_cost', 'deployable_cash', 'undeployed_current_profit', 'receivables'] as $field) {
            $this->assertSame(
                $shown->json("data.{$field}"),
                $signed->json("data.{$field}"),
                "«{$field}» differed between the screen and the record",
            );
        }
    }

    public function test_undrawn_profit_is_a_liability_and_not_deployable_cash(): void
    {
        // Arrange — the owner's ruling: undrawn profit is never working capital
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');
        $this->sell($lorry, $setup['pool'], $setup['period'], '3000.000', '30000.00', '10000.00');

        app(InvestorService::class)->closePeriod($setup['period'], null);

        // Act
        $figures = $this->snapshot($setup['pool']);

        // Assert — the 10,000 is owed, and it is nowhere inside what the pool may spend
        $this->assertSame('10000.00', $figures['liabilities']);
        $this->assertSame('70000.00', $figures['deployable_cash']);
        $this->assertSame('30000.00', $figures['stock_at_cost']);
    }

    public function test_an_uncollected_sale_is_named_as_a_receivable(): void
    {
        // Arrange — profit is recognised at delivery, so `deployable_cash` counts an unpaid order
        // as money in hand. That is inherited and not wrong; a settlement is where the size of the
        // assumption gets written down.
        $setup = $this->pool(['أحمد' => '100000.00']);
        $lorry = $this->lorry($setup['pool'], '6000.000', '10.000');

        $order = Order::factory()->create([
            'grand_total' => '50000.00',
            'paid_amount' => '0.00',
        ]);

        $this->sell(
            $lorry,
            $setup['pool'],
            $setup['period'],
            '3000.000',
            '30000.00',
            '10000.00',
            (int) $order->getKey(),
        );

        // Act
        $figures = $this->snapshot($setup['pool']);

        // Assert — and the drift is still zero: a receivable is an assumption, not a discrepancy
        $this->assertSame('10000.00', $figures['receivables']);
        $this->assertSame('0.00', $figures['drift']);
    }

    public function test_signing_is_its_own_grant(): void
    {
        // Arrange — reading a pool's position is not the same authority as putting your name to it
        $setup = $this->pool(['أحمد' => '100000.00']);

        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
        ]);
        $headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];

        // Act
        $read = $this->withHeaders($headers)
            ->getJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/settlement-snapshot");

        $sign = $this->withHeaders($headers)
            ->postJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/settlements", []);

        // Assert
        $read->assertOk();
        $sign->assertStatus(403);
        $this->assertSame(0, InvestmentSettlement::query()->count());
    }

    public function test_a_settlement_cannot_be_dated_into_the_future(): void
    {
        // Arrange — a settlement asserts a position that already exists
        $setup = $this->pool(['أحمد' => '100000.00']);

        // Act
        $response = $this->withHeaders($this->settler())
            ->postJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/settlements", [
                'settled_on' => now()->addWeek()->toDateString(),
            ]);

        // Assert
        $response->assertStatus(422);
        $response->assertJsonValidationErrors('settled_on');
    }
}
