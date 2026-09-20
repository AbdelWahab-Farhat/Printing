<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PoolKind;
use App\Domain\Investor\Models\InvestmentPoolItem;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * صناديق الاستثمار — the continuous pool that replaces the per-lorry صفقة.
 *
 * The three things this slice has to get right, and each has a test below:
 *
 * 1. **A shelf belongs to one pool and no more.** Not a convention — a unique index. Two pools
 *    over one shelf would send one set of investors' goods into the other's accounts, silently,
 *    because a cost layer carries exactly one container id.
 * 2. **Nothing about a legacy صفقة changes.** It is not listed among pools, it cannot be renamed
 *    through a pool endpoint, and it goes on rendering on its own screen.
 * 3. **A pool is born open and empty.** No partners, no amounts, no purchase order — capital
 *    arrives later, and ownership is recomputed from it at every close.
 *
 * Arrange - Act - Assert throughout.
 */
class InvestmentPoolTest extends TestCase
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
    private function manager(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInvestors->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** A shelf standing behind one product, under a heading the business invests in. */
    private function investableShelf(bool $investable = true): StockItem
    {
        $category = ProductCategory::factory()->create(['is_investable' => $investable]);

        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Piece,
            'product_category_id' => $category->getKey(),
            'is_active' => true,
        ]);

        $stockItem = StockItem::factory()->unit(PricingUnit::Piece)->create();

        ProductVariant::factory()->for($product)->create([
            'stock_item_id' => $stockItem->getKey(),
        ]);

        return $stockItem;
    }

    public function test_a_pool_is_opened_with_its_shelves_and_is_live_immediately(): void
    {
        // Arrange
        $shelf = $this->investableShelf();

        // Act
        $response = $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$shelf->getKey()],
        ]);

        // Assert
        $response->assertCreated();

        $pool = InvestorDeal::query()->where('name', 'ورق')->firstOrFail();

        $this->assertSame(PoolKind::Pool, $pool->kind);
        // Open from birth: there is no draft to review, because there are no terms to freeze.
        $this->assertSame(DealStatus::Open, $pool->status);
        $this->assertTrue($pool->isPool());
        $this->assertSame('50.00', (string) $pool->investor_profit_share_percent);

        // Born empty — the whole difference from a deal, which was struck with its money.
        $this->assertSame(0, $pool->shares()->count());
        $this->assertSame(1, $pool->poolItems()->count());
        $this->assertNull($pool->purchase_order_id);
    }

    public function test_a_shelf_cannot_be_claimed_by_two_pools(): void
    {
        // Arrange
        $shelf = $this->investableShelf();

        $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$shelf->getKey()],
        ])->assertCreated();

        // Act — a second pool reaching for the same shelf
        $response = $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق آخر',
            'stock_item_ids' => [$shelf->getKey()],
        ]);

        // Assert — refused by name, and nothing half-made left behind
        $response->assertStatus(422);
        $this->assertStringContainsString('ورق', (string) $response->json('message'));
        $this->assertSame(1, InvestmentPoolItem::query()->where('stock_item_id', $shelf->getKey())->count());
        $this->assertNull(InvestorDeal::query()->where('name', 'ورق آخر')->first());
    }

    public function test_a_shelf_outside_the_investable_headings_is_refused(): void
    {
        // Arrange
        $shelf = $this->investableShelf(investable: false);

        // Act
        $response = $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'وسيط',
            'stock_item_ids' => [$shelf->getKey()],
        ]);

        // Assert
        $response->assertStatus(422);
        $this->assertNull(InvestorDeal::query()->where('name', 'وسيط')->first());
    }

    public function test_a_detached_shelf_may_join_another_pool(): void
    {
        // Arrange — one pool holding two shelves
        $kept = $this->investableShelf();
        $moving = $this->investableShelf();

        $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$kept->getKey(), $moving->getKey()],
        ])->assertCreated();

        $pool = InvestorDeal::query()->where('name', 'ورق')->firstOrFail();

        // Act — it lets one go, and a new pool takes it
        $this->withHeaders($this->manager())
            ->putJson("/api/v1/investment-pools/{$pool->getKey()}", [
                'name' => 'ورق',
                'stock_item_ids' => [$kept->getKey()],
            ])->assertOk();

        $response = $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'حبر',
            'stock_item_ids' => [$moving->getKey()],
        ]);

        // Assert — the partial index is on live rows, so the released shelf is free
        $response->assertCreated();
        $this->assertSame(
            1,
            InvestmentPoolItem::query()->where('stock_item_id', $moving->getKey())->count(),
        );
    }

    public function test_a_legacy_deal_is_not_listed_among_pools_and_pools_are_not_listed_among_deals(): void
    {
        // Arrange
        $deal = InvestorDeal::factory()->open()->create();
        $pool = InvestorDeal::factory()->pool()->create();

        // Act
        $pools = $this->withHeaders($this->manager())->getJson('/api/v1/investment-pools');
        $deals = $this->withHeaders($this->manager())->getJson('/api/v1/investor-deals');

        // Assert — the two screens stay apart although the rows share a table
        $pools->assertOk();
        $poolIds = array_column($pools->json('data'), 'id');
        $this->assertContains($pool->getKey(), $poolIds);
        $this->assertNotContains($deal->getKey(), $poolIds);

        $deals->assertOk();
        $dealIds = array_column($deals->json('data'), 'id');
        $this->assertContains($deal->getKey(), $dealIds);
        $this->assertNotContains($pool->getKey(), $dealIds);
    }

    public function test_a_legacy_deal_cannot_be_reached_through_a_pool_route(): void
    {
        // Arrange — the promise of the whole migration: no existing deal is ever rewritten
        $deal = InvestorDeal::factory()->open()->create();

        // Act
        $response = $this->withHeaders($this->manager())
            ->putJson("/api/v1/investment-pools/{$deal->getKey()}", [
                'name' => 'محاولة',
                'stock_item_ids' => [$this->investableShelf()->getKey()],
            ]);

        // Assert
        $response->assertNotFound();
        $this->assertNull($deal->fresh()->name);
    }

    public function test_two_pools_cannot_share_a_name(): void
    {
        // Arrange
        $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$this->investableShelf()->getKey()],
        ])->assertCreated();

        // Act
        $response = $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$this->investableShelf()->getKey()],
        ]);

        // Assert — the name is what staff say out loud, so it has to be unambiguous
        $response->assertStatus(422)->assertJsonValidationErrors('name');
    }

    public function test_the_profit_share_cannot_be_changed_after_the_pool_is_open(): void
    {
        // Arrange
        $shelf = $this->investableShelf();

        $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'ورق',
            'stock_item_ids' => [$shelf->getKey()],
            'investor_profit_share_percent' => '60',
        ])->assertCreated();

        $pool = InvestorDeal::query()->where('name', 'ورق')->firstOrFail();
        $this->assertSame('60.00', (string) $pool->investor_profit_share_percent);

        // Act — the term the partners were shown is not an editable field
        $response = $this->withHeaders($this->manager())
            ->putJson("/api/v1/investment-pools/{$pool->getKey()}", [
                'name' => 'ورق',
                'stock_item_ids' => [$shelf->getKey()],
                'investor_profit_share_percent' => '90',
            ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('investor_profit_share_percent');
        $this->assertSame('60.00', (string) $pool->fresh()->investor_profit_share_percent);
    }

    public function test_a_pool_needs_at_least_one_shelf(): void
    {
        // Arrange, Act
        $response = $this->withHeaders($this->manager())->postJson('/api/v1/investment-pools', [
            'name' => 'فارغ',
            'stock_item_ids' => [],
        ]);

        // Assert — a pool that owns nothing can take money and never buy anything with it
        $response->assertStatus(422)->assertJsonValidationErrors('stock_item_ids');
    }
}
