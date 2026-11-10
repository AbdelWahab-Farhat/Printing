<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Receiving a dollar purchase order, and the currency of its costs — USD-ACCOUNTS.md §٥, §٧,
 * phase 4. The stock is priced once at the arrival rate: dollars times the rate, dinar costs as
 * they are, and nothing paid afterwards moves it.
 *
 * Arrange - Act - Assert throughout.
 */
class DollarReceiptTest extends TestCase
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

        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewPurchaseOrders,
            PermissionName::ManagePurchaseOrders,
            PermissionName::ViewInventory,
            PermissionName::ManageInventory,
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ManageTreasury,
        ]));

        $this->headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** The default dinar cash box, holding `$dinars`. */
    private function dinarBox(string $dinars = '10000'): TreasuryAccount
    {
        $box = TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->firstOrFail();

        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $box->id,
            'amount' => $dinars,
        ], $this->headers)->assertCreated();

        return $box;
    }

    private function dollarBox(): TreasuryAccount
    {
        $id = $this->postJson('/api/v1/treasury/accounts', [
            'name' => 'خزنة الدولار',
            'kind' => 'cash',
            'currency' => 'USD',
        ], $this->headers)->assertCreated()->json('data.id');

        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $id,
            'amount' => '5000',
        ], $this->headers)->assertCreated();

        return TreasuryAccount::query()->findOrFail($id);
    }

    /**
     * An order: one line of 10 for each base total in `$lines`, plus `$costs`.
     *
     * @param  list<string>  $lines
     * @param  list<array<string, mixed>>  $costs
     */
    private function raise(string $currency, array $lines, array $costs = []): TestResponse
    {
        return $this->postJson('/api/v1/purchase-orders', [
            'vendor_id' => Vendor::factory()->create()->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'currency' => $currency,
            'items' => array_map(fn (string $base) => [
                'stock_item_id' => StockItem::factory()->create()->id,
                'quantity_ordered' => 10,
                'base_total_cost' => $base,
            ], $lines),
            'additional_costs' => $costs,
        ], $this->headers);
    }

    /**
     * Everything that was ordered arrives.
     *
     * @param  array<string, mixed>  $order
     * @param  array<string, mixed>  $extra
     */
    private function receive(array $order, array $extra = []): TestResponse
    {
        $items = PurchaseOrder::query()->findOrFail($order['id'])->items()->get();

        return $this->postJson("/api/v1/purchase-orders/{$order['id']}/arrivals", [
            'items' => $items->map(fn ($item) => ['stock_item_id' => $item->stock_item_id, 'quantity' => 10])->all(),
        ] + $extra, $this->headers);
    }

    /** @param  array<string, mixed>  $order */
    private function layerUnitCost(array $order, int $line = 0): string
    {
        $item = PurchaseOrder::query()->findOrFail($order['id'])->items()->orderBy('id')->get()[$line];

        return (string) StockBatch::query()->where('stock_item_id', $item->stock_item_id)->firstOrFail()->unit_cost;
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account->refresh());
    }

    // ── the rate ────────────────────────────────────────────────────────────────────────

    public function test_a_dollar_order_is_not_received_without_its_rate(): void
    {
        // Arrange
        $order = $this->raise('USD', ['1500'])->assertCreated()->json('data');

        // Act
        $response = $this->receive($order);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('arrival_rate');
        $this->assertSame(0, StockBatch::query()->count());
    }

    public function test_the_stock_is_priced_in_dinars_at_the_arrival_rate(): void
    {
        // Arrange — $1,500 of goods and $200 of shipping on the vendor's bill: $1,700 landed.
        $order = $this->raise('USD', ['1500'], [['name' => 'شحن من الصين', 'amount' => '200']])
            ->assertCreated()->json('data');

        // Act
        $this->receive($order, ['arrival_rate' => '7'])->assertCreated();

        // Assert — 1,700 × 7 = 11,900 dinars over 10 units.
        $this->assertSame('1190.000', $this->layerUnitCost($order));
        $saved = PurchaseOrder::query()->findOrFail($order['id']);
        $this->assertSame('7.0000', (string) $saved->arrival_rate);
        $this->getJson("/api/v1/purchase-orders/{$order['id']}", $this->headers)
            ->assertJsonPath('data.arrival_rate', '7.0000')
            ->assertJsonPath('data.items.0.landed_unit_cost', '1190.000')
            ->assertJsonPath('data.vendor_amount', '1700.00');
    }

    public function test_the_receive_screen_is_told_the_system_rate(): void
    {
        // Arrange
        $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '7.15'], $this->headers)->assertOk();
        $dollars = $this->raise('USD', ['100'])->json('data');
        $dinars = $this->raise('LYD', ['100'])->json('data');

        // Act
        $shown = $this->getJson("/api/v1/purchase-orders/{$dollars['id']}", $this->headers);
        $plain = $this->getJson("/api/v1/purchase-orders/{$dinars['id']}", $this->headers);

        // Assert
        $shown->assertJsonPath('data.system_usd_rate', '7.1500');
        $plain->assertJsonMissingPath('data.system_usd_rate');
    }

    public function test_a_dinar_order_takes_no_rate(): void
    {
        // Arrange
        $order = $this->raise('LYD', ['1000'])->json('data');

        // Act
        $this->receive($order, ['arrival_rate' => '7'])->assertCreated();

        // Assert
        $this->assertNull(PurchaseOrder::query()->findOrFail($order['id'])->arrival_rate);
        $this->assertSame('100.000', $this->layerUnitCost($order));
    }

    public function test_paying_the_vendor_afterwards_never_moves_the_stock(): void
    {
        // Arrange
        $order = $this->raise('USD', ['1000'])->json('data');
        $this->receive($order, ['arrival_rate' => '7'])->assertCreated();
        $box = $this->dollarBox();

        // Act — paid later, whatever the dollars cost when they were bought.
        $this->postJson("/api/v1/vendors/{$order['vendor_id']}/payments", [
            'amount' => '1000',
            'method' => 'cash',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $box->id,
        ], $this->headers)->assertCreated();

        // Assert
        $this->assertSame('700.000', $this->layerUnitCost($order));
        $this->assertSame('4000.00', $this->balance($box));
    }

    public function test_undoing_the_receipt_empties_the_rate_and_the_next_one_asks_again(): void
    {
        // Arrange
        $order = $this->raise('USD', ['1000'])->json('data');
        $this->receive($order, ['arrival_rate' => '7'])->assertCreated();

        // Act
        $this->postJson("/api/v1/purchase-orders/{$order['id']}/receipt-reversal", [
            'reason' => 'استُلم بالخطأ',
        ], $this->headers)->assertOk();
        $again = $this->receive($order);

        // Assert
        $this->assertNull(PurchaseOrder::query()->findOrFail($order['id'])->arrival_rate);
        $again->assertUnprocessable()->assertJsonValidationErrors('arrival_rate');
        $this->receive($order, ['arrival_rate' => '6.5'])->assertCreated();
        $this->assertSame('6.5000', (string) PurchaseOrder::query()->findOrFail($order['id'])->arrival_rate);
    }

    // ── each cost in its currency ───────────────────────────────────────────────────────

    public function test_customs_paid_in_dinars_land_in_the_stock_at_face_value(): void
    {
        // Arrange — $1,000 of goods, and 350 dinars of customs out of the dinar drawer.
        $box = $this->dinarBox('10000');
        $order = $this->raise('USD', ['1000'], [
            ['name' => 'جمارك', 'amount' => '350', 'treasury_account_id' => $box->id],
        ])->assertCreated()->json('data');

        // Act
        $this->receive($order, ['arrival_rate' => '7'])->assertCreated();

        // Assert — 1,000 × 7 + 350 = 7,350 over 10. The vendor is owed the dollars alone.
        $this->assertSame('735.000', $this->layerUnitCost($order));
        $this->assertSame('9650.00', $this->balance($box));
        $this->assertSame(Currency::Lyd, PurchaseOrderAdditionalCost::query()->firstOrFail()->currency);
        $this->getJson("/api/v1/purchase-orders/{$order['id']}", $this->headers)
            ->assertJsonPath('data.total_amount', '1000.00')
            ->assertJsonPath('data.total_additional_cost', '0.00')
            ->assertJsonPath('data.vendor_amount', '1000.00')
            ->assertJsonPath('data.additional_costs.0.currency', 'LYD');
    }

    public function test_a_planned_dinar_cost_is_spread_by_what_each_line_is_worth(): void
    {
        // Arrange — two lines, $300 and $100, and 400 dinars of customs: 300 and 100 of it.
        $box = $this->dinarBox();
        $order = $this->raise('USD', ['300', '100'], [
            ['name' => 'جمارك', 'amount' => '400', 'treasury_account_id' => $box->id],
        ])->json('data');

        // Act
        $this->receive($order, ['arrival_rate' => '5'])->assertCreated();

        // Assert — (300 × 5 + 300) / 10 and (100 × 5 + 100) / 10.
        $this->assertSame('180.000', $this->layerUnitCost($order, 0));
        $this->assertSame('60.000', $this->layerUnitCost($order, 1));
    }

    public function test_arrival_costs_in_both_currencies_each_take_their_own_road(): void
    {
        // Arrange — on the lorry: $100 of freight on the vendor's bill, 70 dinars of porters.
        $box = $this->dinarBox();
        $order = $this->raise('USD', ['1000'])->json('data');

        // Act
        $this->receive($order, [
            'arrival_rate' => '7',
            'additional_costs' => [
                ['name' => 'شحن', 'amount' => '100'],
                ['name' => 'عتّالة', 'amount' => '70', 'treasury_account_id' => $box->id],
            ],
        ])->assertCreated();

        // Assert — (1,000 + 100) × 7 + 70 = 7,770. The vendor is owed $1,100.
        $this->assertSame('777.000', $this->layerUnitCost($order));
        $this->assertSame('9930.00', $this->balance($box));
        $this->getJson("/api/v1/purchase-orders/{$order['id']}", $this->headers)
            ->assertJsonPath('data.vendor_amount', '1100.00');
        $this->assertSame(
            ['LYD', 'USD'],
            PurchaseOrderAdditionalCost::query()->orderBy('currency')->pluck('currency')->map->value->all(),
        );
    }

    public function test_a_cost_on_the_bill_is_in_the_order_s_currency_and_says_so(): void
    {
        // Act
        $response = $this->raise('USD', ['100'], [['name' => 'شحن', 'amount' => '10', 'currency' => 'LYD']]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('additional_costs.0.currency');
    }

    public function test_a_cost_from_a_drawer_is_in_the_drawer_s_currency(): void
    {
        // Arrange
        $box = $this->dinarBox();

        // Act
        $response = $this->raise('USD', ['100'], [
            ['name' => 'جمارك', 'amount' => '10', 'currency' => 'USD', 'treasury_account_id' => $box->id],
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('additional_costs.0.currency');
    }

    public function test_a_dollar_drawer_does_not_pay_a_dinar_order_s_cost(): void
    {
        // Arrange
        $box = $this->dollarBox();

        // Act
        $response = $this->raise('LYD', ['100'], [['name' => 'شحن', 'amount' => '10', 'treasury_account_id' => $box->id]]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('additional_costs.0.treasury_account_id');
        $this->assertSame('5000.00', $this->balance($box));
    }

    public function test_a_planned_dollar_cost_needs_a_rate_to_be_counted_in_dinars(): void
    {
        // Arrange — no «سعر النظام», and nothing received yet.
        $box = $this->dollarBox();

        // Act
        $response = $this->raise('USD', ['100'], [['name' => 'شحن', 'amount' => '10', 'treasury_account_id' => $box->id]]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('additional_costs.0.treasury_account_id');
        $this->assertSame('5000.00', $this->balance($box));
    }

    public function test_a_dollar_drawer_pays_a_dollar_order_s_cost_in_dollars(): void
    {
        // Arrange — «سعر النظام» 7.
        $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '7'], $this->headers)->assertOk();
        $box = $this->dollarBox();

        // Act — $1,000 of goods, $100 of shipping paid from the dollar box.
        $order = $this->raise('USD', ['1000'], [
            ['name' => 'شحن', 'amount' => '100', 'treasury_account_id' => $box->id],
        ])->assertCreated()->json('data');
        $this->receive($order, ['arrival_rate' => '7.5'])->assertCreated();

        // Assert — out of the dollar box, off the vendor's bill, into the stock at the arrival
        // rate: (1,000 + 100) × 7.5 / 10. In «المصاريف» at the rate of the day it left: 700.
        $this->assertSame('4900.00', $this->balance($box));
        $this->assertSame('825.000', $this->layerUnitCost($order));
        $this->getJson("/api/v1/purchase-orders/{$order['id']}", $this->headers)
            ->assertJsonPath('data.vendor_amount', '1000.00')
            ->assertJsonPath('data.additional_costs.0.currency', 'USD');
        $this->getJson('/api/v1/treasury/expenses', $this->headers)
            ->assertJsonPath('meta.expenses_total', '700.00')
            ->assertJsonPath('meta.expenses_usd_total', '100.00')
            ->assertJsonPath('data.0.dinar_amount', '700.00');
    }

    public function test_a_dollar_cost_at_arrival_is_counted_at_the_rate_typed_there(): void
    {
        // Arrange — no «سعر النظام»: the receive screen's rate is the one at hand.
        $box = $this->dollarBox();
        $order = $this->raise('USD', ['1000'])->json('data');

        // Act
        $this->receive($order, [
            'arrival_rate' => '7.5',
            'additional_costs' => [['name' => 'شحن', 'amount' => '100', 'treasury_account_id' => $box->id]],
        ])->assertCreated();

        // Assert
        $this->assertSame('4900.00', $this->balance($box));
        $this->assertSame('825.000', $this->layerUnitCost($order));
        $this->getJson('/api/v1/treasury/expenses', $this->headers)
            ->assertJsonPath('meta.expenses_total', '750.00');
    }

    public function test_moving_a_cost_from_the_bill_to_a_dinar_drawer_changes_its_currency(): void
    {
        // Arrange
        $box = $this->dinarBox();
        $order = $this->raise('USD', ['1000'], [['name' => 'جمارك', 'amount' => '50']])->json('data');
        $saved = PurchaseOrder::query()->with(['items', 'additionalCosts'])->findOrFail($order['id']);
        $line = $saved->items->first();
        $cost = $saved->additionalCosts->first();

        // Act
        $this->putJson("/api/v1/purchase-orders/{$order['id']}", [
            'vendor_id' => $order['vendor_id'],
            'warehouse_id' => $order['warehouse_id'],
            'order_date' => now()->toDateString(),
            'items' => [['id' => $line->id, 'stock_item_id' => $line->stock_item_id, 'quantity_ordered' => 10, 'base_total_cost' => '1000']],
            'additional_costs' => [['id' => $cost->id, 'name' => 'جمارك', 'amount' => '350', 'treasury_account_id' => $box->id]],
        ], $this->headers)->assertOk()
            ->assertJsonPath('data.additional_costs.0.currency', 'LYD')
            ->assertJsonPath('data.vendor_amount', '1000.00')
            ->assertJsonPath('data.items.0.final_total_cost', '1000.00');

        // Assert
        $this->assertSame('9650.00', $this->balance($box));
    }
}
