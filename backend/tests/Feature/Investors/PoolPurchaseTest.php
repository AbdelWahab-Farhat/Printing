<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentPoolItem;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Buying a lorry with pool money.
 *
 * The four things this slice has to get right:
 *
 * 1. **Nobody picks a pool.** The material decides, so the payload names lines and never a
 *    container — and the storekeeper is still asked nothing at receipt.
 * 2. **A pool spends only what it has.** Cash is derived, so overspending does not fail anywhere;
 *    it quietly produces a negative number and a lorry the investors did not pay for.
 * 3. **Affordability is per pool, not per line** — two lines of one lorry can share a pool.
 * 4. **سعر السادة is per lorry now**, and null still means the other road.
 *
 * Arrange - Act - Assert throughout.
 */
class PoolPurchaseTest extends TestCase
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
            PermissionName::RecordInvestorMoney->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function investableShelf(): StockItem
    {
        $category = ProductCategory::factory()->create(['is_investable' => true]);
        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Piece,
            'product_category_id' => $category->getKey(),
            'is_active' => true,
        ]);
        $stockItem = StockItem::factory()->unit(PricingUnit::Piece)->create();

        ProductVariant::factory()->for($product)->create(['stock_item_id' => $stockItem->getKey()]);

        return $stockItem;
    }

    /** A pool owning the given shelves, funded with `$capital` of somebody's money. */
    private function fundedPool(array $shelves, string $capital): InvestorDeal
    {
        $pool = InvestorDeal::factory()->pool()->create();

        foreach ($shelves as $shelf) {
            InvestmentPoolItem::factory()->create([
                'investor_deal_id' => $pool->getKey(),
                'stock_item_id' => $shelf->getKey(),
            ]);
        }

        $investor = Investor::factory()->create();
        $service = app(InvestorService::class);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Deposit,
            amount: $capital,
            method: 'cash',
        ), null);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Allocation,
            amount: $capital,
            investorDealId: (int) $pool->getKey(),
        ), null);

        return $pool->refresh();
    }

    /**
     * An order for the given shelves, 100,000 a line.
     *
     * @param  list<StockItem>  $shelves
     */
    private function order(array $shelves): PurchaseOrder
    {
        $order = PurchaseOrder::factory()->create([
            'warehouse_id' => Warehouse::factory()->create()->getKey(),
            'status' => PurchaseOrderStatus::New,
        ]);

        foreach ($shelves as $shelf) {
            PurchaseOrderItem::factory()->forOrder($order)->create([
                'stock_item_id' => $shelf->getKey(),
                'quantity_ordered' => '10000.000',
                'base_total_cost' => '100000.00',
                'base_unit_cost' => '10.000',
                'allocated_additional_cost' => '0.00',
                'final_unit_cost' => '10.000',
                'final_total_cost' => '100000.00',
            ]);
        }

        return $order->refresh();
    }

    public function test_a_pool_buys_a_line_and_nobody_chose_the_pool(): void
    {
        // Arrange
        $shelf = $this->investableShelf();
        $pool = $this->fundedPool([$shelf], '150000.00');
        $order = $this->order([$shelf]);

        // Act — the payload names a line and a price, never a container
        $response = $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [
                    ['stock_item_id' => $shelf->getKey(), 'printing_sale_price' => '32'],
                ],
            ]);

        // Assert — the material routed it
        $response->assertCreated();

        $supply = InvestorDealSupply::query()->firstOrFail();
        $this->assertSame((int) $pool->getKey(), (int) $supply->investor_deal_id);
        $this->assertSame((int) $shelf->getKey(), (int) $supply->stock_item_id);
        $this->assertSame('32.000', (string) $supply->printing_sale_price);
    }

    public function test_the_price_is_per_lorry_and_may_be_omitted(): void
    {
        // Arrange — omitted means «nobody said»: these goods ride the sale itself
        $shelf = $this->investableShelf();
        $this->fundedPool([$shelf], '150000.00');
        $order = $this->order([$shelf]);

        // Act
        $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $shelf->getKey()]],
            ])->assertCreated();

        // Assert
        $this->assertNull(InvestorDealSupply::query()->firstOrFail()->printing_sale_price);
    }

    public function test_a_pool_cannot_buy_more_than_it_has(): void
    {
        // Arrange — 50,000 of capital against a 100,000 line
        $shelf = $this->investableShelf();
        $this->fundedPool([$shelf], '50000.00');
        $order = $this->order([$shelf]);

        // Act
        $response = $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $shelf->getKey()]],
            ]);

        // Assert — refused, and nothing written
        $response->assertStatus(422);
        $this->assertSame(0, InvestorDealSupply::query()->count());
    }

    public function test_affordability_is_measured_per_pool_not_per_line(): void
    {
        // Arrange — two shelves of one pool, 150,000 of capital, two 100,000 lines.
        // Each line alone is affordable; together they are not.
        $paper = $this->investableShelf();
        $card = $this->investableShelf();
        $this->fundedPool([$paper, $card], '150000.00');
        $order = $this->order([$paper, $card]);

        // Act
        $response = $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [
                    ['stock_item_id' => $paper->getKey()],
                    ['stock_item_id' => $card->getKey()],
                ],
            ]);

        // Assert — the whole call is refused, not half of it
        $response->assertStatus(422);
        $this->assertSame(0, InvestorDealSupply::query()->count());
    }

    public function test_a_material_in_no_pool_is_refused(): void
    {
        // Arrange — inventing a pool on the buyer's behalf would put somebody's money into a
        // heading he never agreed to
        $shelf = $this->investableShelf();
        $order = $this->order([$shelf]);

        // Act
        $response = $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $shelf->getKey()]],
            ]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, InvestorDealSupply::query()->count());
    }

    public function test_a_line_already_claimed_is_refused(): void
    {
        // Arrange — the supply lookup answers with the first row it finds, so a second claim
        // would be ignored in silence at receipt
        $shelf = $this->investableShelf();
        $this->fundedPool([$shelf], '250000.00');
        $order = $this->order([$shelf]);

        $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $shelf->getKey()]],
            ])->assertCreated();

        // Act
        $response = $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $shelf->getKey()]],
            ]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(1, InvestorDealSupply::query()->count());
    }

    public function test_deployable_cash_is_book_value_less_the_goods_on_the_shelf(): void
    {
        // Arrange — 150,000 of capital, 40,000 of it already turned into stock
        $shelf = $this->investableShelf();
        $pool = $this->fundedPool([$shelf], '150000.00');

        StockBatch::factory()->create([
            'stock_item_id' => $shelf->getKey(),
            'investor_deal_id' => $pool->getKey(),
            'unit_cost' => '10.000',
            'quantity_received' => '4000.000',
            'quantity_remaining' => '4000.000',
        ]);

        // Act
        $response = $this->withHeaders($this->manager())
            ->getJson("/api/v1/investment-pools/{$pool->getKey()}/deployable-cash");

        // Assert
        $response->assertOk();
        $this->assertSame('150000.00', $response->json('data.capital'));
        $this->assertSame('40000.00', $response->json('data.stock_at_cost'));
        $this->assertSame('110000.00', $response->json('data.deployable_cash'));
    }

    public function test_stock_on_the_shelf_reduces_what_the_pool_can_buy(): void
    {
        // Arrange — the same pool, but its money is already in goods
        $paper = $this->investableShelf();
        $pool = $this->fundedPool([$paper], '150000.00');

        StockBatch::factory()->create([
            'stock_item_id' => $paper->getKey(),
            'investor_deal_id' => $pool->getKey(),
            'unit_cost' => '10.000',
            'quantity_received' => '8000.000',
            'quantity_remaining' => '8000.000',
        ]);

        $order = $this->order([$paper]);

        // Act — 70,000 of cash left against a 100,000 line
        $response = $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $paper->getKey()]],
            ]);

        // Assert
        $response->assertStatus(422);
    }

    public function test_the_payload_cannot_name_a_pool(): void
    {
        // Arrange — the guarantee that «الموظف لا يختار الصفقة أبداً» now holds for everybody
        $shelf = $this->investableShelf();
        $mine = $this->fundedPool([$shelf], '150000.00');
        $other = InvestorDeal::factory()->pool()->create();
        $order = $this->order([$shelf]);

        // Act — an extra key is simply not read
        $this->withHeaders($this->manager())
            ->postJson("/api/v1/purchase-orders/{$order->getKey()}/pool-purchase", [
                'lines' => [['stock_item_id' => $shelf->getKey()]],
                'investment_pool_id' => $other->getKey(),
            ])->assertCreated();

        // Assert — the material decided, not the payload
        $this->assertSame(
            (int) $mine->getKey(),
            (int) InvestorDealSupply::query()->firstOrFail()->investor_deal_id,
        );
    }
}
