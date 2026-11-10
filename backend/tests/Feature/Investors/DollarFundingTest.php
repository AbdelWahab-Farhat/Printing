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
use App\Domain\Investor\Actions\DepositToFund;
use App\Domain\Investor\Actions\OpenInvestmentPeriod;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Queries\FundGoodsOnOrder;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\Money;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Funding a dollar purchase order — USD-ACCOUNTS.md §٥, the owner's decision of 2026-11-10.
 *
 * The funding screen asks a rate («سعر النظام» unless changed); the fund's money and the
 * partners' are worked out in dinars at it, and the funded goods keep it when they arrive. The
 * company's own goods take the arrival rate. A difference between the two writes nothing — the
 * order says it.
 *
 * Arrange - Act - Assert throughout.
 */
class DollarFundingTest extends TestCase
{
    use RefreshDatabase;

    /** @var array<string, string> */
    private array $headers;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Carbon::setTestNow('2026-11-10 09:00:00');

        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewInvestors,
            PermissionName::ManageInvestors,
            PermissionName::RecordInvestorMoney,
            PermissionName::ViewInventory,
            PermissionName::ManageInventory,
            PermissionName::ViewPurchaseOrders,
            PermissionName::ManagePurchaseOrders,
        ]));

        $this->headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    /** The fund, holding `$amount` dinars of an investor's money. */
    private function fundHolding(string $amount): void
    {
        app(OpenInvestmentPeriod::class)(actorId: null);

        $investor = $this->investorHolding($amount);

        app(DepositToFund::class)(investorId: (int) $investor->id, amount: $amount, actorId: null);
    }

    private function investorHolding(string $amount): Investor
    {
        $investor = Investor::factory()->create();

        app(RecordWalletEntry::class)(
            new WalletEntryData(
                investorId: (int) $investor->id,
                type: WalletEntryType::Deposit,
                amount: $amount,
                method: 'cash',
            ),
            null,
        );

        return $investor;
    }

    private function investableShelf(string $name): StockItem
    {
        $shelf = StockItem::factory()->named($name)->unit(PricingUnit::Kilogram)->create();
        $product = Product::factory()->create([
            'pricing_unit' => PricingUnit::Kilogram,
            'product_category_id' => ProductCategory::factory()->investable()->create()->getKey(),
            'is_active' => true,
        ]);

        ProductVariant::factory()->for($product)->create(['stock_item_id' => $shelf->getKey()]);

        return $shelf;
    }

    /**
     * A dollar order with two lines: bags, 500 kg for $1,000, and rolls, 100 kg for $200.
     *
     * @return array{0: PurchaseOrder, 1: StockItem, 2: StockItem}
     */
    private function dollarOrder(): array
    {
        $order = PurchaseOrder::factory()->create([
            'vendor_id' => Vendor::factory()->create()->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'status' => PurchaseOrderStatus::New,
            'currency' => Currency::Usd,
        ]);

        $bags = $this->investableShelf('كيس 25×35');
        $rolls = $this->investableShelf('رول نايلون');

        foreach ([[$bags, '500.000', '1000.00', '2.000'], [$rolls, '100.000', '200.00', '2.000']] as [$shelf, $quantity, $total, $unit]) {
            PurchaseOrderItem::factory()->forOrder($order)->create([
                'stock_item_id' => $shelf->id,
                'quantity_ordered' => $quantity,
                'base_total_cost' => $total,
                'base_unit_cost' => $unit,
                'allocated_additional_cost' => '0.00',
                'final_unit_cost' => $unit,
                'final_total_cost' => $total,
                'unit' => PricingUnit::Kilogram,
            ]);
        }

        return [$order->refresh(), $bags, $rolls];
    }

    /** @param  array<string, mixed>  $body */
    private function fundBuys(PurchaseOrder $order, StockItem $shelf, array $body = []): TestResponse
    {
        return $this->withHeaders($this->headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/fund-purchase",
            ['stock_item_ids' => [$shelf->id]] + $body,
        );
    }

    private function receive(PurchaseOrder $order, string $rate): void
    {
        $this->withHeaders($this->headers)->postJson("/api/v1/purchase-orders/{$order->id}/arrivals", [
            'arrival_rate' => $rate,
            'items' => $order->items()->get()->map(fn (PurchaseOrderItem $item) => [
                'stock_item_id' => $item->stock_item_id,
                'quantity' => (string) $item->quantity_ordered,
            ])->all(),
        ])->assertCreated();
    }

    private function layerUnitCost(StockItem $shelf): string
    {
        return (string) StockBatch::query()->where('stock_item_id', $shelf->id)->firstOrFail()->unit_cost;
    }

    // ── the fund buys ───────────────────────────────────────────────────────────────────

    public function test_the_fund_does_not_buy_a_dollar_order_without_a_rate(): void
    {
        // Arrange
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->dollarOrder();

        // Act
        $response = $this->fundBuys($order, $bags);

        // Assert
        $response->assertUnprocessable();
        $this->assertStringContainsString('سعر الصرف', (string) $response->json('message'));
        $this->assertSame('20000.00', Money::round(app(FundCash::class)()));
    }

    public function test_the_fund_pays_the_dollars_in_dinars_at_the_rate_it_was_given(): void
    {
        // Arrange
        $this->fundHolding('20000.00');
        [$order, $bags, $rolls] = $this->dollarOrder();

        // Act — $1,000 of bags at 7.
        $this->fundBuys($order, $bags, ['rate' => '7'])->assertOk();

        // Assert — 7,000 dinars left the fund, and it is what the goods on the way are worth.
        $this->assertSame('13000.00', Money::round(app(FundCash::class)()));
        $this->assertSame('7000.00', Money::round(app(FundGoodsOnOrder::class)->value()));
        $order->refresh();
        $this->assertSame('7.0000', (string) $order->funding_rate);
        $this->assertSame('7000.00', (string) $order->items()->where('stock_item_id', $bags->id)->value('funded_cost'));
        $this->assertNull($order->items()->where('stock_item_id', $rolls->id)->value('funded_cost'));
    }

    public function test_a_second_funding_keeps_the_rate_of_the_first(): void
    {
        // Arrange
        $this->fundHolding('20000.00');
        [$order, $bags, $rolls] = $this->dollarOrder();
        $this->fundBuys($order, $bags, ['rate' => '7'])->assertOk();

        // Act — another rate typed for the rolls.
        $this->fundBuys($order, $rolls, ['rate' => '9'])->assertOk();

        // Assert — $200 at 7, not 9. (What the second purchase takes from the fund's cash is not
        // asked here: `RecordCashEntry` keys a purchase by its order, so a second purchase on the
        // same order writes none — dinars or dollars alike, and not this feature's to change.)
        $this->assertSame('7.0000', (string) $order->refresh()->funding_rate);
        $this->assertSame('1400.00', (string) $order->items()->where('stock_item_id', $rolls->id)->value('funded_cost'));
    }

    // ── arrival ─────────────────────────────────────────────────────────────────────────

    public function test_funded_goods_keep_the_funding_rate_and_the_company_s_the_arrival_rate(): void
    {
        // Arrange — the fund bought the bags at 7.
        $this->fundHolding('20000.00');
        [$order, $bags, $rolls] = $this->dollarOrder();
        $this->fundBuys($order, $bags, ['rate' => '7'])->assertOk();
        $priceBefore = app(UnitPrice::class)();

        // Act — the lorry comes in at 7.5.
        $this->receive($order, '7.5');

        // Assert — the bags at 7,000 / 500; the company's rolls at 200 × 7.5 / 100.
        $this->assertSame('14.000', $this->layerUnitCost($bags));
        $this->assertSame('15.000', $this->layerUnitCost($rolls));
        // The fund's value did not move at arrival: what it paid is what it holds.
        $this->assertSame($priceBefore, app(UnitPrice::class)());
        $this->assertSame('13000.00', Money::round(app(FundCash::class)()));
    }

    public function test_the_order_says_when_the_dollars_arrived_dearer_than_they_were_funded(): void
    {
        // Arrange
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->dollarOrder();
        $this->fundBuys($order, $bags, ['rate' => '7'])->assertOk();

        // Act
        $this->receive($order, '7.5');
        $response = $this->withHeaders($this->headers)->getJson("/api/v1/purchase-orders/{$order->id}");

        // Assert — half a dinar a dollar on $1,000 of funded goods, and nothing written for it.
        $response->assertOk()
            ->assertJsonPath('data.funding_rate', '7.0000')
            ->assertJsonPath('data.arrival_rate', '7.5000')
            ->assertJsonPath('data.rate_difference.per_dollar', '0.5000')
            ->assertJsonPath('data.rate_difference.direction', 'higher')
            ->assertJsonPath('data.rate_difference.funded_dollars', '1000.00')
            ->assertJsonPath('data.rate_difference.dinars', '500.00');
    }

    public function test_and_when_they_arrived_cheaper(): void
    {
        // Arrange
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->dollarOrder();
        $this->fundBuys($order, $bags, ['rate' => '7'])->assertOk();

        // Act
        $this->receive($order, '6.8');

        // Assert
        $this->withHeaders($this->headers)->getJson("/api/v1/purchase-orders/{$order->id}")
            ->assertJsonPath('data.rate_difference.direction', 'lower')
            ->assertJsonPath('data.rate_difference.per_dollar', '0.2000')
            ->assertJsonPath('data.rate_difference.dinars', '200.00');
    }

    public function test_the_same_rate_twice_says_nothing(): void
    {
        // Arrange
        $this->fundHolding('20000.00');
        [$order, $bags] = $this->dollarOrder();
        $this->fundBuys($order, $bags, ['rate' => '7'])->assertOk();

        // Act
        $this->receive($order, '7');

        // Assert
        $this->withHeaders($this->headers)->getJson("/api/v1/purchase-orders/{$order->id}")
            ->assertJsonPath('data.rate_difference', null);
    }

    // ── partners ────────────────────────────────────────────────────────────────────────

    public function test_partners_money_is_held_against_the_dinars_at_the_funding_rate(): void
    {
        // Arrange — the bags are $1,000: 7,000 dinars at 7.
        [$order, $bags] = $this->dollarOrder();
        $ahmed = $this->investorHolding('20000.00');
        $fund = fn (string $amount) => $this->withHeaders($this->headers)->postJson(
            "/api/v1/purchase-orders/{$order->id}/investor-funding",
            [
                'rate' => '7',
                'stock_item_ids' => [$bags->id],
                'investor_profit_share_percent' => 50,
                'investors' => [['investor_id' => $ahmed->id, 'amount' => $amount]],
            ],
        );

        // Act
        $tooMuch = $fund('7000.01');
        $fine = $fund('5000.00');

        // Assert — the rest of the 7,000 is the company's stake.
        $tooMuch->assertUnprocessable();
        $fine->assertCreated();
        $deal = InvestorDeal::query()->where('purchase_order_id', $order->id)->firstOrFail();
        $this->assertSame('2000.00', (string) $deal->company_stake);
        $this->assertSame('7.0000', (string) $order->refresh()->funding_rate);
    }
}
