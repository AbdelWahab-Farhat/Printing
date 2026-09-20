<?php

declare(strict_types=1);

namespace Tests\Feature\Investors;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\Enums\StockAdjustmentReason;
use App\Domain\Inventory\InventoryService;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentRealizedEarning;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «بضاعة راجعة من طلبية ملغاة: صالحة أم تالفة؟» — reading the queue, and answering it.
 *
 * The action and the close guard are covered elsewhere ({@see InvestmentPeriodCloseTest}); what is
 * tested here is the pair of endpoints a person actually uses, and the properties that only exist
 * once a request is involved:
 *
 * 1. The list shows the pool's questions, **open ones first** — the open ones are the work.
 * 2. `only_open` narrows it, which is what a close screen shows.
 * 3. **«صالحة» writes nothing** but unblocks the close.
 * 4. **«تالفة» posts a damage decrease**, and the goods actually leave the shelf. This is the one
 *    that matters: charged as an expense instead, the pool would go on counting stock it does not
 *    have and the next lorry would be bought with money that was never there.
 * 5. A verdict is not a draft — answered once.
 * 6. `open` is not an answer.
 * 7. **Answering is `inventory.manage`, not an investor grant** — it writes off stock.
 *
 * Arrange - Act - Assert throughout.
 */
class ReturnedGoodsQuestionTest extends TestCase
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
     * Somebody who may read the pool and write off stock — the two grants these endpoints split
     * between them.
     *
     * @return array<string, string>
     */
    private function storekeeper(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewInvestors->value,
            PermissionName::ManageInventory->value,
            PermissionName::CloseInvestmentPeriods->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * Somebody who runs the money and nothing else. He may read the queue; he may not write off
     * paper he is not holding.
     *
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

    /**
     * A pool with an open period, one investor's capital in it, and a margin to divide — enough
     * for the close to be a real close rather than a no-op.
     *
     * @return array{pool: InvestorDeal, period: InvestmentPeriod}
     */
    private function pool(): array
    {
        $pool = InvestorDeal::factory()->pool()->create(['investor_profit_share_percent' => '50.00']);

        $period = InvestmentPeriod::factory()->create([
            'investor_deal_id' => $pool->getKey(),
            'starts_on' => now()->startOfMonth()->toDateString(),
            'ends_on' => now()->endOfMonth()->toDateString(),
        ]);

        $investor = Investor::factory()->create(['name' => 'أحمد']);
        $service = app(InvestorService::class);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Deposit,
            amount: '100000.00',
            method: 'cash',
        ), null);

        $service->recordWalletEntry(new WalletEntryData(
            investorId: (int) $investor->getKey(),
            type: WalletEntryType::Allocation,
            amount: '100000.00',
            investorDealId: (int) $pool->getKey(),
        ), null);

        InvestmentRealizedEarning::factory()->create([
            'investment_period_id' => $period->getKey(),
            'source_type' => AuditSubject::Order->value,
            'source_id' => 1,
            'amount' => '10000.00',
        ]);

        return ['pool' => $pool->refresh(), 'period' => $period->refresh()];
    }

    /** A shelf with `$quantity` of `$item` standing on it at 10 each. */
    private function shelf(StockItem $item, string $quantity): Warehouse
    {
        $warehouse = Warehouse::factory()->create();

        app(InventoryService::class)->recordMovement(StockMovementData::arrival([
            'stock_item_id' => $item->getKey(),
            'to_warehouse_id' => $warehouse->getKey(),
            'quantity' => $quantity,
            'unit_cost' => '10.00',
        ], (int) User::factory()->create()->getKey()));

        return $warehouse;
    }

    private function onShelf(Warehouse $warehouse, StockItem $item): string
    {
        return (string) (WarehouseStock::query()
            ->where('warehouse_id', $warehouse->getKey())
            ->where('stock_item_id', $item->getKey())
            ->first()?->quantity ?? '0.000');
    }

    public function test_the_list_puts_the_open_questions_first(): void
    {
        // Arrange — an answered question and an open one, the answered one created last so id
        // order alone would put it on top
        $setup = $this->pool();

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Good,
            'answered_at' => now(),
        ]);

        // Act
        $response = $this->withHeaders($this->storekeeper())
            ->getJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/returned-goods");

        // Assert
        $response->assertOk();
        $rows = $response->json('data');
        $this->assertCount(2, $rows);
        $this->assertTrue($rows[0]['is_open']);
        $this->assertFalse($rows[1]['is_open']);
    }

    public function test_only_open_narrows_it_to_the_work(): void
    {
        // Arrange
        $setup = $this->pool();

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Good,
            'answered_at' => now(),
        ]);

        // Act
        $response = $this->withHeaders($this->storekeeper())
            ->getJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/returned-goods?only_open=1");

        // Assert
        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('open', $response->json('data.0.verdict'));
    }

    public function test_a_question_belonging_to_another_pool_is_not_in_the_list(): void
    {
        // Arrange — the index is keyed on the pool, and a shared shelf is impossible by design;
        // this is the assertion that the endpoint agrees
        $mine = $this->pool();
        $other = $this->pool();

        InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $other['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        // Act
        $response = $this->withHeaders($this->storekeeper())
            ->getJson("/api/v1/investment-pools/{$mine['pool']->getKey()}/returned-goods");

        // Assert
        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    public function test_good_writes_nothing_and_lets_the_period_close(): void
    {
        // Arrange
        $setup = $this->pool();
        $item = StockItem::factory()->create();
        $warehouse = $this->shelf($item, '500.000');

        $question = InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'stock_item_id' => $item->getKey(),
            'quantity' => '100.000',
            'cost' => '1000.00',
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        $headers = $this->storekeeper();

        // Act
        $response = $this->withHeaders($headers)
            ->postJson("/api/v1/investment-returned-goods/{$question->getKey()}/answer", [
                'verdict' => ReturnedGoodsVerdict::Good->value,
                'warehouse_id' => $warehouse->getKey(),
            ]);

        // Assert — answered, nothing written off, and the shelf is exactly as it was
        $response->assertOk();
        $answered = $question->fresh();
        $this->assertSame(ReturnedGoodsVerdict::Good, $answered->verdict);
        $this->assertNotNull($answered->answered_at);
        $this->assertNull($answered->damage_movement_id);
        $this->assertSame('500.000', $this->onShelf($warehouse, $item));

        // And the close it was holding up now goes through
        $this->withHeaders($headers)
            ->postJson("/api/v1/investment-periods/{$setup['period']->getKey()}/close")
            ->assertOk();

        $this->assertSame(PeriodStatus::Closed, $setup['period']->fresh()->status);
    }

    public function test_damaged_takes_the_goods_off_the_shelf(): void
    {
        // Arrange — the property that matters. Booked as a cost alone, `stock_at_cost` would go on
        // counting 500 when only 400 are there, and the pool's deployable cash would be overstated
        // by the difference.
        $setup = $this->pool();
        $item = StockItem::factory()->create();
        $warehouse = $this->shelf($item, '500.000');

        $question = InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'stock_item_id' => $item->getKey(),
            'quantity' => '100.000',
            'cost' => '1000.00',
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        // Act
        $response = $this->withHeaders($this->storekeeper())
            ->postJson("/api/v1/investment-returned-goods/{$question->getKey()}/answer", [
                'verdict' => ReturnedGoodsVerdict::Damaged->value,
                'warehouse_id' => $warehouse->getKey(),
                'notes' => 'مطبوعة ولا تصلح',
            ]);

        // Assert
        $response->assertOk();
        $answered = $question->fresh();
        $this->assertSame(ReturnedGoodsVerdict::Damaged, $answered->verdict);
        $this->assertNotNull($answered->damage_movement_id);
        $this->assertSame('400.000', $this->onShelf($warehouse, $item));

        // A movement, not an expense — and one the damage bucket can find
        $movement = StockMovement::query()->whereKey($answered->damage_movement_id)->firstOrFail();
        $this->assertSame(MovementType::Adjustment, $movement->movement_type);
        $this->assertSame(StockAdjustmentReason::Damage, $movement->adjustment_reason);
        $this->assertSame((int) $warehouse->getKey(), (int) $movement->from_warehouse_id);
    }

    public function test_a_verdict_is_not_a_draft(): void
    {
        // Arrange — reopening one would mean unwinding a movement the shelf has been counted
        // against
        $setup = $this->pool();
        $item = StockItem::factory()->create();
        $warehouse = $this->shelf($item, '500.000');

        $question = InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'stock_item_id' => $item->getKey(),
            'quantity' => '100.000',
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        $headers = $this->storekeeper();
        $payload = [
            'verdict' => ReturnedGoodsVerdict::Damaged->value,
            'warehouse_id' => $warehouse->getKey(),
        ];

        $this->withHeaders($headers)
            ->postJson("/api/v1/investment-returned-goods/{$question->getKey()}/answer", $payload)
            ->assertOk();

        // Act — the same answer again
        $second = $this->withHeaders($headers)
            ->postJson("/api/v1/investment-returned-goods/{$question->getKey()}/answer", $payload);

        // Assert — refused, and the shelf was not decremented twice
        $second->assertStatus(422);
        $this->assertSame('400.000', $this->onShelf($warehouse, $item));
        $this->assertSame(1, StockMovement::query()
            ->where('adjustment_reason', StockAdjustmentReason::Damage->value)
            ->count());
    }

    public function test_open_is_not_an_answer(): void
    {
        // Arrange
        $setup = $this->pool();
        $warehouse = Warehouse::factory()->create();

        $question = InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        // Act
        $response = $this->withHeaders($this->storekeeper())
            ->postJson("/api/v1/investment-returned-goods/{$question->getKey()}/answer", [
                'verdict' => ReturnedGoodsVerdict::Open->value,
                'warehouse_id' => $warehouse->getKey(),
            ]);

        // Assert
        $response->assertStatus(422);
        $response->assertJsonValidationErrors('verdict');
        $this->assertSame(ReturnedGoodsVerdict::Open, $question->fresh()->verdict);
    }

    public function test_answering_is_not_an_investor_grant(): void
    {
        // Arrange — the banker may read the queue, because it is on the pool's screen; he may not
        // write off paper he is not holding
        $setup = $this->pool();
        $warehouse = Warehouse::factory()->create();

        $question = InvestmentReturnedGoodsQuestion::factory()->create([
            'investor_deal_id' => $setup['pool']->getKey(),
            'verdict' => ReturnedGoodsVerdict::Open,
        ]);

        $headers = $this->banker();

        // Act
        $read = $this->withHeaders($headers)
            ->getJson("/api/v1/investment-pools/{$setup['pool']->getKey()}/returned-goods");

        $answer = $this->withHeaders($headers)
            ->postJson("/api/v1/investment-returned-goods/{$question->getKey()}/answer", [
                'verdict' => ReturnedGoodsVerdict::Good->value,
                'warehouse_id' => $warehouse->getKey(),
            ]);

        // Assert
        $read->assertOk();
        $answer->assertStatus(403);
        $this->assertSame(ReturnedGoodsVerdict::Open, $question->fresh()->verdict);
    }
}
