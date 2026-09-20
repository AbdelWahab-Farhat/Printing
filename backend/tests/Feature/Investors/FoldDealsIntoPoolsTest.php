<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PoolKind;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealItem;
use App\Domain\Investor\Models\InvestorDealShare;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * `investment:fold-in` — the one step that touches money that already exists.
 *
 * Everything here is about what must **not** happen. The command's job is to move capital and
 * goods from the open صفقات into صناديق without a dinar or a kilo appearing or disappearing, and
 * without a single existing row being rewritten.
 *
 * The four properties that matter:
 *
 * 1. `--dry-run` writes nothing at all — asserted on row counts, not on hope.
 * 2. Every investor's total capital is exactly what it was.
 * 3. The legacy deal keeps its row, its ledger and its kind; it is closed, not converted.
 * 4. Deals that share a shelf land in **one** pool, because a shelf may belong to only one.
 *
 * Arrange - Act - Assert throughout.
 */
class FoldDealsIntoPoolsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** A man with money in his wallet, none of it committed. */
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

    /**
     * An open deal standing on one shelf, funded by one man, with stock still on it.
     *
     * Built from the parts rather than through the purchase-order pipeline: what is under test is
     * the fold, and a lorry's worth of arrangement would only obscure it.
     */
    private function openDeal(StockItem $shelf, Investor $investor, string $capital, string $stockCost = '0.000'): InvestorDeal
    {
        $deal = InvestorDeal::factory()->open()->create();

        InvestorDealItem::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'stock_item_id' => $shelf->getKey(),
        ]);

        InvestorDealShare::factory()->create([
            'investor_deal_id' => $deal->getKey(),
            'investor_id' => $investor->getKey(),
            'share_percent' => '100.0000',
            'committed_amount' => $capital,
        ]);

        app(InvestorService::class)->recordWalletEntry(
            new WalletEntryData(
                investorId: (int) $investor->getKey(),
                type: WalletEntryType::Allocation,
                amount: $capital,
                investorDealId: (int) $deal->getKey(),
            ),
            null,
        );

        if ($stockCost !== '0.000') {
            StockBatch::factory()->create([
                'stock_item_id' => $shelf->getKey(),
                'investor_deal_id' => $deal->getKey(),
                'unit_cost' => $stockCost,
                'quantity_received' => '100.000',
                'quantity_remaining' => '100.000',
            ]);
        }

        return $deal->refresh();
    }

    public function test_a_dry_run_writes_nothing(): void
    {
        // Arrange
        $shelf = StockItem::factory()->create();
        $this->openDeal($shelf, $this->investorHolding('50000.00'), '30000.00', '10.000');

        $before = [
            'deals' => InvestorDeal::query()->count(),
            'entries' => InvestorWalletEntry::query()->count(),
            'shares' => InvestorDealShare::query()->count(),
        ];

        // Act
        $this->artisan('investment:fold-in', ['--dry-run' => true])->assertSuccessful();

        // Assert — not one row, of any kind
        $this->assertSame($before['deals'], InvestorDeal::query()->count());
        $this->assertSame($before['entries'], InvestorWalletEntry::query()->count());
        $this->assertSame($before['shares'], InvestorDealShare::query()->count());
        $this->assertSame(0, InvestorDeal::query()->where('kind', PoolKind::Pool->value)->count());
    }

    public function test_capital_survives_the_fold_exactly(): void
    {
        // Arrange — 30,000 in a deal, 20,000 left in the wallet
        $shelf = StockItem::factory()->create();
        $investor = $this->investorHolding('50000.00');
        $deal = $this->openDeal($shelf, $investor, '30000.00', '10.000');

        $balances = app(InvestorBalances::class);
        $before = $balances->forInvestor((int) $investor->getKey());
        $totalBefore = bcadd($before['wallet']['capital'], $before['deals'][$deal->getKey()]['capital'], 2);

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — the same 50,000, now sitting in a pool instead of a deal
        $pool = InvestorDeal::query()->where('kind', PoolKind::Pool->value)->firstOrFail();
        $after = $balances->forInvestor((int) $investor->getKey());

        $this->assertSame('30000.00', $after['deals'][$pool->getKey()]['capital']);
        $this->assertSame('0.00', $after['deals'][$deal->getKey()]['capital']);
        $this->assertSame(
            $totalBefore,
            bcadd($after['wallet']['capital'], $after['deals'][$pool->getKey()]['capital'], 2),
        );
    }

    public function test_the_legacy_deal_keeps_everything_and_is_closed_not_converted(): void
    {
        // Arrange
        $shelf = StockItem::factory()->create();
        $investor = $this->investorHolding('50000.00');
        $deal = $this->openDeal($shelf, $investor, '30000.00', '10.000');
        $entriesBefore = $deal->walletEntries()->count();

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — the row is still there, still a صفقة, with its history intact
        $deal->refresh();
        $this->assertSame(PoolKind::Deal, $deal->kind);
        $this->assertSame(DealStatus::Closed, $deal->status);
        $this->assertNotNull($deal->closed_at);
        $this->assertGreaterThan($entriesBefore, $deal->walletEntries()->count());
        $this->assertSame(1, $deal->shares()->count());
    }

    public function test_the_stock_changes_hands_and_none_of_it_is_lost(): void
    {
        // Arrange
        $shelf = StockItem::factory()->create();
        $deal = $this->openDeal($shelf, $this->investorHolding('50000.00'), '30000.00', '10.000');

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — the same layer, re-pointed; the quantity and the cost untouched
        $pool = InvestorDeal::query()->where('kind', PoolKind::Pool->value)->firstOrFail();
        $layer = StockBatch::query()->where('stock_item_id', $shelf->getKey())->firstOrFail();

        $this->assertSame((int) $pool->getKey(), (int) $layer->investor_deal_id);
        $this->assertSame('100.000', (string) $layer->quantity_remaining);
        $this->assertSame('10.000', (string) $layer->unit_cost);
        $this->assertSame(0, StockBatch::query()->where('investor_deal_id', $deal->getKey())->count());
    }

    public function test_two_deals_over_one_shelf_land_in_the_same_pool(): void
    {
        // Arrange — the rule that forces this: a shelf belongs to one pool only
        $shelf = StockItem::factory()->create();
        $this->openDeal($shelf, $this->investorHolding('50000.00'), '30000.00', '10.000');
        $this->openDeal($shelf, $this->investorHolding('40000.00'), '20000.00', '12.000');

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — one pool, holding both men's money
        $pools = InvestorDeal::query()->where('kind', PoolKind::Pool->value)->get();
        $this->assertCount(1, $pools);
        $this->assertSame('50000.00', app(InvestorBalances::class)
            ->forDeal((int) $pools->first()->getKey())['capital']);
        $this->assertSame(2, $pools->first()->shares()->count());
    }

    public function test_deals_on_unrelated_shelves_get_a_pool_each(): void
    {
        // Arrange
        $paper = StockItem::factory()->create();
        $ink = StockItem::factory()->create();
        $this->openDeal($paper, $this->investorHolding('50000.00'), '30000.00', '10.000');
        $this->openDeal($ink, $this->investorHolding('40000.00'), '20000.00', '12.000');

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — and a loss in one can then never touch the other
        $this->assertSame(2, InvestorDeal::query()->where('kind', PoolKind::Pool->value)->count());
    }

    public function test_a_pool_roster_carries_no_frozen_percentage(): void
    {
        // Arrange
        $shelf = StockItem::factory()->create();
        $this->openDeal($shelf, $this->investorHolding('50000.00'), '30000.00', '10.000');

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — ownership is recomputed from capital at every close; a number here would be a
        // second answer to a question that already has one
        $pool = InvestorDeal::query()->where('kind', PoolKind::Pool->value)->firstOrFail();
        $this->assertNull($pool->shares()->firstOrFail()->share_percent);
    }

    public function test_the_pool_inherits_every_frozen_term_so_orders_in_flight_are_paid_the_same(): void
    {
        // Arrange — a deal whose partners bought 93.1808% of the goods, the company the rest.
        // Production's D1 is exactly this, and a pool taking the column default of 100 would pay
        // the investors for goods they never bought on every order still in flight.
        $shelf = StockItem::factory()->create();
        $deal = $this->openDeal($shelf, $this->investorHolding('50000.00'), '30000.00', '10.000');
        $deal->forceFill([
            'investor_funded_percent' => '93.1808',
            'company_stake' => '1160.01',
            'printing_sale_price' => '32.000',
            'investor_profit_share_percent' => '50.00',
        ])->save();

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert — attribution reads the layer, and the layer now points at the pool, so the
        // pool's terms are what an in-flight order will be paid on
        $pool = InvestorDeal::query()->where('kind', PoolKind::Pool->value)->firstOrFail();

        $this->assertSame('93.1808', (string) $pool->investor_funded_percent);
        $this->assertSame('1160.01', (string) $pool->company_stake);
        $this->assertSame('32.000', (string) $pool->printing_sale_price);
        $this->assertSame('50.00', (string) $pool->investor_profit_share_percent);

        // The whole point, stated as the sum it protects: 1,000 of profit still splits the way
        // it would have under the deal.
        $this->assertSame(
            $deal->investorsCutOf('1000.00'),
            $pool->investorsCutOf('1000.00'),
        );
    }

    public function test_nothing_happens_when_there_are_no_open_deals(): void
    {
        // Arrange — a closed deal and nothing else
        InvestorDeal::factory()->create(['status' => DealStatus::Closed]);

        // Act
        $this->artisan('investment:fold-in', ['--force' => true])->assertSuccessful();

        // Assert
        $this->assertSame(0, InvestorDeal::query()->where('kind', PoolKind::Pool->value)->count());
    }
}
