<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Investor\Actions\FundPurchaseOrder;
use App\Domain\Investor\Actions\PurchaseFromFund;
use App\Domain\Investor\DTOs\FundPurchaseOrderData;
use App\Domain\Investor\Exceptions\PurchaseOrderCannotBeFunded;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Dollar purchase orders and the vendor's dollar «علينا» — USD-ACCOUNTS.md §٤, phase 2.
 *
 * Arrange - Act - Assert throughout.
 */
class DollarPurchaseOrdersTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** Raises orders, pays vendors, receives, and reads the treasury. @return array<string, string> */
    private function owner(): array
    {
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

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * An order through the real endpoint: one line of 10 for `$cost`, plus `$costs`.
     *
     * @param  array<string, string>  $headers
     * @param  list<array<string, mixed>>  $costs
     * @return array<string, mixed>
     */
    private function raise(array $headers, Vendor $vendor, ?string $currency, string $cost, array $costs = []): array
    {
        return $this->postJson('/api/v1/purchase-orders', array_filter([
            'vendor_id' => $vendor->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'currency' => $currency,
            'items' => [[
                'stock_item_id' => StockItem::factory()->create()->id,
                'quantity_ordered' => 10,
                'base_total_cost' => $cost,
            ]],
            'additional_costs' => $costs,
        ], fn ($value) => $value !== null), $headers)->assertCreated()->json('data');
    }

    /** What the vendor's payable in `$currency` says is owed, as a positive figure. */
    private function owed(Vendor $vendor, Currency $currency): ?string
    {
        $id = app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id, $currency);

        return $id === null
            ? null
            : bcmul(app(TreasuryService::class)->balanceOf(TreasuryAccount::query()->findOrFail($id)), '-1', 2);
    }

    // ── the order ───────────────────────────────────────────────────────────────────────

    public function test_an_order_raised_in_dollars_keeps_its_currency(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();

        // Act
        $order = $this->raise($headers, $vendor, 'USD', '1500');

        // Assert
        $this->assertSame('USD', $order['currency']);
        $this->assertSame('1500.00', $order['vendor_amount']);
        $this->assertSame(Currency::Usd, PurchaseOrder::query()->findOrFail($order['id'])->currency);
    }

    public function test_an_order_raised_without_a_currency_is_in_dinars(): void
    {
        // Arrange
        $headers = $this->owner();

        // Act
        $order = $this->raise($headers, Vendor::factory()->create(), null, '700');

        // Assert
        $this->assertSame('LYD', $order['currency']);
    }

    public function test_an_unknown_currency_is_refused(): void
    {
        // Arrange
        $headers = $this->owner();

        // Act
        $response = $this->postJson('/api/v1/purchase-orders', [
            'vendor_id' => Vendor::factory()->create()->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'currency' => 'EUR',
            'items' => [['stock_item_id' => StockItem::factory()->create()->id, 'quantity_ordered' => 1, 'base_total_cost' => 5]],
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('currency');
    }

    public function test_an_edit_never_changes_the_currency(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();
        $order = $this->raise($headers, $vendor, 'USD', '1500');
        $line = PurchaseOrder::query()->findOrFail($order['id'])->items()->firstOrFail();

        // Act
        $response = $this->putJson("/api/v1/purchase-orders/{$order['id']}", [
            'vendor_id' => $vendor->id,
            'warehouse_id' => $order['warehouse_id'],
            'order_date' => now()->toDateString(),
            'currency' => 'LYD',
            'items' => [[
                'id' => $line->id,
                'stock_item_id' => $line->stock_item_id,
                'quantity_ordered' => 10,
                'base_total_cost' => '1800',
            ]],
        ], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.currency', 'USD');
        $this->assertSame('1800.00', $this->owed($vendor, Currency::Usd));
        $this->assertNull($this->owed($vendor, Currency::Lyd));
    }

    public function test_the_table_refuses_a_currency_it_does_not_know(): void
    {
        // Arrange
        $order = PurchaseOrder::factory()->create();

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('purchase_orders')->where('id', $order->id)->update(['currency' => 'EUR']);
    }

    // ── the debt ────────────────────────────────────────────────────────────────────────

    public function test_a_dollar_order_owes_dollars_on_the_vendor_s_own_dollar_payable(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create(['name' => 'مصنع شنغهاي']);

        // Act
        $this->raise($headers, $vendor, 'LYD', '7000');
        $this->raise($headers, $vendor, 'USD', '1500', [['name' => 'شحن من الصين', 'amount' => '200']]);

        // Assert — two payables, each in its own currency, each owing its own orders.
        $this->assertSame('7000.00', $this->owed($vendor, Currency::Lyd));
        $this->assertSame('1700.00', $this->owed($vendor, Currency::Usd));

        $dollars = TreasuryAccount::query()->findOrFail(app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id, Currency::Usd));
        $this->assertSame('مصنع شنغهاي (دولار)', $dollars->name);
        $this->assertSame((int) $vendor->id, (int) $dollars->vendor_id);
        $this->assertSame(1, TreasuryMovement::query()->where('account_id', $dollars->id)->where('kind', MovementKind::Purchase->value)->count());
    }

    public function test_a_second_dollar_order_lands_on_the_same_dollar_payable(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();

        // Act
        $this->raise($headers, $vendor, 'USD', '1000');
        $this->raise($headers, $vendor, 'USD', '250');

        // Assert
        $this->assertSame(1, TreasuryAccount::query()->where('vendor_id', $vendor->id)->where('currency', 'USD')->count());
        $this->assertSame('1250.00', $this->owed($vendor, Currency::Usd));
    }

    public function test_cancelling_a_dollar_order_clears_its_dollar_debt(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();
        $order = $this->raise($headers, $vendor, 'USD', '1000');

        // Act
        $this->patchJson("/api/v1/purchase-orders/{$order['id']}/status", ['status' => 'cancelled'], $headers)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->owed($vendor, Currency::Usd));
    }

    public function test_moving_a_dollar_order_to_another_vendor_moves_its_dollar_debt(): void
    {
        // Arrange
        $headers = $this->owner();
        $first = Vendor::factory()->create();
        $second = Vendor::factory()->create();
        $order = $this->raise($headers, $first, 'USD', '900');
        $line = PurchaseOrder::query()->findOrFail($order['id'])->items()->firstOrFail();

        // Act
        $this->putJson("/api/v1/purchase-orders/{$order['id']}", [
            'vendor_id' => $second->id,
            'warehouse_id' => $order['warehouse_id'],
            'order_date' => now()->toDateString(),
            'items' => [['id' => $line->id, 'stock_item_id' => $line->stock_item_id, 'quantity_ordered' => 10, 'base_total_cost' => '900']],
        ], $headers)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->owed($first, Currency::Usd));
        $this->assertSame('900.00', $this->owed($second, Currency::Usd));
        $this->assertNull($this->owed($second, Currency::Lyd));
    }

    public function test_renaming_the_vendor_renames_both_payables(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create(['name' => 'قديم']);
        $this->raise($headers, $vendor, 'LYD', '100');
        $this->raise($headers, $vendor, 'USD', '100');

        // Act
        app(TreasuryService::class)->renameVendorPayable((int) $vendor->id, 'جديد');

        // Assert
        $this->assertEqualsCanonicalizing(
            ['جديد', 'جديد (دولار)'],
            TreasuryAccount::query()->where('vendor_id', $vendor->id)->pluck('name')->all(),
        );
    }

    public function test_the_table_allows_a_dollar_payable_for_a_vendor_alone(): void
    {
        // Arrange — a payable with no vendor is the system's, and the system's are dinars.
        $payable = TreasuryAccount::factory()->create(['kind' => 'payable', 'name' => 'التزام']);

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('treasury_accounts')->where('id', $payable->id)->update(['currency' => 'USD']);
    }

    // ── what the screens read ───────────────────────────────────────────────────────────

    public function test_the_vendor_s_account_says_dinars_and_dollars_apart(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();
        $this->raise($headers, $vendor, 'LYD', '7000');
        $this->raise($headers, $vendor, 'USD', '1500');

        // Act
        $response = $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.ordered', '7000.00')
            ->assertJsonPath('data.summary.owed', '7000.00')
            ->assertJsonPath('data.usd_summary.ordered', '1500.00')
            ->assertJsonPath('data.usd_summary.owed', '1500.00')
            ->assertJsonPath('data.usd_treasury_account_id', app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id, Currency::Usd));
    }

    public function test_the_order_s_payment_summary_names_its_currency(): void
    {
        // Arrange
        $headers = $this->owner();
        $order = $this->raise($headers, Vendor::factory()->create(), 'USD', '1500');

        // Act
        $response = $this->getJson("/api/v1/purchase-orders/{$order['id']}/payments", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.currency', 'USD')
            ->assertJsonPath('data.summary.remaining', '1500.00');
    }

    public function test_what_is_owed_in_dollars_counts_at_the_system_rate_in_the_totals(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();
        $this->raise($headers, $vendor, 'LYD', '1000');
        $this->raise($headers, $vendor, 'USD', '100');
        $this->putJson('/api/v1/treasury/settings', ['usd_rate' => '7'], $headers)->assertOk();

        // Act
        $accounts = $this->getJson('/api/v1/treasury/accounts', $headers);
        $ownership = $this->getJson('/api/v1/treasury/ownership', $headers);

        // Assert — 1,000 dinars and $100 at 7 is 1,700, never 1,100.
        $accounts->assertOk()
            ->assertJsonPath('data.payables_total', '1700.00')
            ->assertJsonPath('data.usd_payables_total', '100.00')
            ->assertJsonPath('data.usd_payables_total_in_lyd', '700.00');
        $ownership->assertOk()
            ->assertJsonPath('data.payables_total', '1700.00')
            ->assertJsonPath('data.usd_payables', '100.00')
            ->assertJsonPath('data.usd_payables_in_lyd', '700.00');
    }

    public function test_with_no_system_rate_the_dollar_debt_stays_out_of_the_dinar_total(): void
    {
        // Arrange
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();
        $this->raise($headers, $vendor, 'LYD', '1000');
        $this->raise($headers, $vendor, 'USD', '100');

        // Act
        $accounts = $this->getJson('/api/v1/treasury/accounts', $headers);

        // Assert
        $accounts->assertOk()
            ->assertJsonPath('data.payables_total', '1000.00')
            ->assertJsonPath('data.usd_payables_total', '100.00')
            ->assertJsonPath('data.usd_payables_total_in_lyd', null);
    }

    // ── what waits for its own phase ────────────────────────────────────────────────────

    public function test_a_payment_with_no_order_pays_the_dinar_debt_alone(): void
    {
        // Arrange — the vendor is owed dollars only, so there is no dinar debt to pay.
        $headers = $this->owner();
        $vendor = Vendor::factory()->create();
        $this->raise($headers, $vendor, 'USD', '1500');

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '100',
            'method' => 'cash',
        ], $headers);

        // Assert — «لا دفع مقدّماً» reads dinars: nothing is owed in them.
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
    }

    public function test_a_dinar_order_s_cost_is_still_paid_from_a_drawer(): void
    {
        // Arrange
        $headers = $this->owner();
        $cash = TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->firstOrFail();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $cash->id,
            'amount' => '500',
        ], $headers)->assertCreated();

        // Act
        $order = $this->raise($headers, Vendor::factory()->create(), 'LYD', '100', [
            ['name' => 'جمارك', 'amount' => '50', 'treasury_account_id' => $cash->id],
        ]);

        // Assert
        $this->assertSame('100.00', $order['vendor_amount']);
    }

    public function test_funding_a_dollar_order_asks_for_its_rate(): void
    {
        // Arrange
        $order = $this->raise($this->owner(), Vendor::factory()->create(), 'USD', '1500');

        // Act / Assert — both doors, with no rate: partners' money, and the fund's own cash.
        foreach ([
            fn () => app(FundPurchaseOrder::class)((int) $order['id'], new FundPurchaseOrderData(funders: []), null),
            fn () => app(PurchaseFromFund::class)((int) $order['id'], null, null),
        ] as $fund) {
            try {
                $fund();
                $this->fail('A dollar order was funded.');
            } catch (PurchaseOrderCannotBeFunded $refused) {
                $this->assertStringContainsString('بالدولار', $refused->getMessage());
            }
        }
    }
}
