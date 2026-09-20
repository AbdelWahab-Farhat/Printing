<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockBatchConsumption;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Which cancellations raise a question, and which are left alone.
 *
 * **A prompt with one possible answer is noise**, and noise is what teaches people to click through
 * the prompts that matter — so the filters are as much the feature as the question is:
 *
 * | the line | asked? | because |
 * |---|---|---|
 * | printed, unpriced, pool | **yes** | the pool's own paper came back, and it may be ruined |
 * | سادة | no | sold off the shelf as it stands — never printed, comes back intact |
 * | وسيط | no | no purchase order, no layer, nothing of the pool's was ever involved |
 * | priced (سعر السادة) | no | paid for the day it left; the cancellation hands it to the company |
 * | company-funded layer | no | no pool, nothing to block |
 * | legacy صفقة | no | closed and read-only; a question against it would block nothing |
 *
 * And the one that only exists because a shelf may move between pools: **one line, two pools, two
 * questions**. Its layers stay with whoever paid for them, so a line can draw straight through the
 * boundary and leave ruined paper on both sides of it.
 *
 * Arranged at the seam the action actually reads — a fulfillment movement and its FIFO draws —
 * rather than through the order state machine, which has its own tests and would only add noise
 * between the arrangement and the property.
 *
 * Arrange - Act - Assert throughout.
 */
class ReturnedGoodsRaisedTest extends TestCase
{
    use RefreshDatabase;

    /** A heading whose goods are made on our press, or one of the two that are not. */
    private function shelfAndLine(ProductionMode $mode, Order $order): array
    {
        $category = ProductCategory::factory()->create([
            'production_mode' => $mode,
            'is_investable' => true,
        ]);

        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Piece,
            'product_category_id' => $category->getKey(),
            'is_active' => true,
        ]);

        $stockItem = StockItem::factory()->unit(PricingUnit::Piece)->create();
        $variant = ProductVariant::factory()->for($product)->create([
            'stock_item_id' => $stockItem->getKey(),
        ]);

        // The draw itself. Deliberately still pointed at by the line after the cancellation:
        // `fulfillment_stock_movement_id` is never cleared by the reversal, because the movement is
        // history and the credit-back points back at it.
        $movement = StockMovement::factory()
            ->fulfillment(Warehouse::factory()->create())
            ->create([
                'stock_item_id' => $stockItem->getKey(),
                'quantity' => '300.000',
            ]);

        $line = OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'product_id' => $product->getKey(),
            'product_variant_id' => $variant->getKey(),
            'fulfillment_stock_movement_id' => $movement->getKey(),
        ]);

        return ['stock_item' => $stockItem, 'line' => $line, 'movement' => $movement];
    }

    /** A cost layer the given container paid for, and the draw that took `$quantity` out of it. */
    private function drawFrom(
        array $seam,
        ?InvestorDeal $container,
        string $quantity,
        ?string $printingSalePrice = null,
    ): StockBatch {
        $batch = StockBatch::factory()->create([
            'stock_item_id' => $seam['stock_item']->getKey(),
            'investor_deal_id' => $container?->getKey(),
            'printing_sale_price' => $printingSalePrice,
        ]);

        StockBatchConsumption::factory()->create([
            'stock_batch_id' => $batch->getKey(),
            'stock_movement_id' => $seam['movement']->getKey(),
            'quantity' => $quantity,
            'unit_cost' => '10.000',
            'total_cost' => bcmul($quantity, '10', 2),
        ]);

        return $batch;
    }

    /**
     * @return list<InvestmentReturnedGoodsQuestion>
     */
    private function ask(Order $order): array
    {
        return app(InvestorService::class)->askAboutReturnedGoods((int) $order->getKey());
    }

    public function test_a_printed_line_on_unpriced_pool_material_is_asked_about(): void
    {
        // Arrange
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();
        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, $pool, '300.000');

        // Act
        $raised = $this->ask($order);

        // Assert — and the figures are the ones read off the credit-back, not off the shelf
        $this->assertCount(1, $raised);
        $question = $raised[0];
        $this->assertSame((int) $pool->getKey(), (int) $question->investor_deal_id);
        $this->assertSame((int) $seam['line']->getKey(), (int) $question->order_item_id);
        $this->assertSame('300.000', (string) $question->quantity);
        $this->assertSame('3000.00', (string) $question->cost);
        $this->assertSame(ReturnedGoodsVerdict::Open, $question->verdict);
    }

    public function test_a_plain_line_is_not_asked_about(): void
    {
        // Arrange — سادة is sold off the shelf as it stands and comes back untouched
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();
        $seam = $this->shelfAndLine(ProductionMode::None, $order);
        $this->drawFrom($seam, $pool, '300.000');

        // Act
        $raised = $this->ask($order);

        // Assert
        $this->assertSame([], $raised);
        $this->assertSame(0, InvestmentReturnedGoodsQuestion::query()->count());
    }

    public function test_an_outsourced_line_is_not_asked_about(): void
    {
        // Arrange — وسيط never had a shelf of ours to come back to
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();
        $seam = $this->shelfAndLine(ProductionMode::Outsourced, $order);
        $this->drawFrom($seam, $pool, '300.000');

        // Act
        $raised = $this->ask($order);

        // Assert
        $this->assertSame([], $raised);
    }

    public function test_priced_material_is_not_asked_about(): void
    {
        // Arrange — سعر السادة was paid the day it left, and the cancellation hands those goods to
        // the company. Nothing of the pool's came back.
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();
        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, $pool, '300.000', '32.000');

        // Act
        $raised = $this->ask($order);

        // Assert
        $this->assertSame([], $raised);
    }

    public function test_company_material_is_not_asked_about(): void
    {
        // Arrange — no pool, so there is no period for a question to block
        $order = Order::factory()->create();
        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, null, '300.000');

        // Act
        $raised = $this->ask($order);

        // Assert
        $this->assertSame([], $raised);
    }

    public function test_a_legacy_deal_is_not_asked_about(): void
    {
        // Arrange — a صفقة is closed and read-only; a question against it would block nothing and
        // mean nothing
        $order = Order::factory()->create();
        $deal = InvestorDeal::factory()->create();
        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, $deal, '300.000');

        // Act
        $raised = $this->ask($order);

        // Assert
        $this->assertSame([], $raised);
    }

    public function test_one_line_across_two_pools_raises_two_questions(): void
    {
        // Arrange — the case a shelf moving between pools creates. `SyncPoolItems` lets صندوق «أ»
        // drop a material and صندوق «ب» claim it, and **the cost layers do not move with it**: they
        // are what أ's investors paid for. One line then draws FIFO straight through the boundary,
        // and both pools have ruined paper to account for.
        //
        // Keyed on the line alone, ب's question could never be raised — the unique index would
        // refuse the second insert — and ب would close its period over goods it no longer has.
        $order = Order::factory()->create();
        $first = InvestorDeal::factory()->pool()->create();
        $second = InvestorDeal::factory()->pool()->create();

        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, $first, '180.000');
        $this->drawFrom($seam, $second, '120.000');

        // Act
        $raised = $this->ask($order);

        // Assert — both, each for what it actually lost
        $this->assertCount(2, $raised);

        $byPool = [];
        foreach ($raised as $question) {
            $byPool[(int) $question->investor_deal_id] = $question;
        }

        $this->assertSame('180.000', (string) $byPool[(int) $first->getKey()]->quantity);
        $this->assertSame('1800.00', (string) $byPool[(int) $first->getKey()]->cost);
        $this->assertSame('120.000', (string) $byPool[(int) $second->getKey()]->quantity);
        $this->assertSame('1200.00', (string) $byPool[(int) $second->getKey()]->cost);
    }

    public function test_asking_twice_asks_once(): void
    {
        // Arrange — a status walked twice, or a listener fired twice, must be harmless
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();
        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, $pool, '300.000');

        $this->ask($order);

        // Act
        $second = $this->ask($order);

        // Assert
        $this->assertSame([], $second);
        $this->assertSame(1, InvestmentReturnedGoodsQuestion::query()->count());
    }

    public function test_an_answered_question_is_not_reopened_by_a_retry(): void
    {
        // Arrange
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();
        $seam = $this->shelfAndLine(ProductionMode::InHouse, $order);
        $this->drawFrom($seam, $pool, '300.000');

        $question = $this->ask($order)[0];
        $question->forceFill([
            'verdict' => ReturnedGoodsVerdict::Good,
            'answered_at' => now(),
        ])->save();

        // Act
        $this->ask($order);

        // Assert
        $this->assertSame(1, InvestmentReturnedGoodsQuestion::query()->count());
        $this->assertSame(ReturnedGoodsVerdict::Good, $question->fresh()->verdict);
    }

    public function test_a_line_whose_material_never_left_is_not_asked_about(): void
    {
        // Arrange — no fulfillment movement, so nothing was drawn and nothing came back
        $order = Order::factory()->create();
        $pool = InvestorDeal::factory()->pool()->create();

        $category = ProductCategory::factory()->create([
            'production_mode' => ProductionMode::InHouse,
            'is_investable' => true,
        ]);
        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Piece,
            'product_category_id' => $category->getKey(),
        ]);
        $stockItem = StockItem::factory()->unit(PricingUnit::Piece)->create();
        $variant = ProductVariant::factory()->for($product)->create([
            'stock_item_id' => $stockItem->getKey(),
        ]);

        OrderItem::factory()->create([
            'order_id' => $order->getKey(),
            'product_id' => $product->getKey(),
            'product_variant_id' => $variant->getKey(),
            'fulfillment_stock_movement_id' => null,
        ]);

        // Act
        $raised = $this->ask($order);

        // Assert
        $this->assertSame([], $raised);
        $this->assertSame(0, InvestmentReturnedGoodsQuestion::query()->count());
    }
}
