<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Paying a vendor's dollar debt — USD-ACCOUNTS.md §٦, phase 3. Each currency pays its own: a
 * dollar debt from a dollar account, in dollars, with no rate and no exchange difference.
 *
 * Arrange - Act - Assert throughout.
 */
class DollarVendorPaymentsTest extends TestCase
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
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
            PermissionName::ReverseVendorPayments,
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ManageTreasury,
        ]));

        $this->headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** A dollar account holding `$dollars`, through the real endpoints. */
    private function dollarBox(string $dollars = '5000', string $kind = 'cash'): TreasuryAccount
    {
        $id = $this->postJson('/api/v1/treasury/accounts', [
            'name' => "دولار {$kind}",
            'kind' => $kind,
            'currency' => 'USD',
        ], $this->headers)->assertCreated()->json('data.id');

        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $id,
            'amount' => $dollars,
        ], $this->headers)->assertCreated();

        return TreasuryAccount::query()->findOrFail($id);
    }

    private function dinarBox(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->firstOrFail();
    }

    /** @return array<string, mixed> */
    private function order(Vendor $vendor, string $currency, string $cost): array
    {
        return $this->postJson('/api/v1/purchase-orders', [
            'vendor_id' => $vendor->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'currency' => $currency,
            'items' => [['stock_item_id' => StockItem::factory()->create()->id, 'quantity_ordered' => 10, 'base_total_cost' => $cost]],
        ], $this->headers)->assertCreated()->json('data');
    }

    /** @param  array<string, mixed>  $body */
    private function pay(Vendor $vendor, array $body): TestResponse
    {
        return $this->postJson("/api/v1/vendors/{$vendor->id}/payments", $body + ['method' => 'cash'], $this->headers);
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account->refresh());
    }

    private function dollarPayable(Vendor $vendor): TreasuryAccount
    {
        return TreasuryAccount::query()->findOrFail(
            app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id, Currency::Usd),
        );
    }

    // ── paying ──────────────────────────────────────────────────────────────────────────

    public function test_a_dollar_order_is_paid_from_a_dollar_account_in_dollars(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');
        $box = $this->dollarBox('5000');

        // Act
        $response = $this->pay($vendor, [
            'amount' => '600',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $box->id,
        ]);

        // Assert — dollars left the drawer and came off the dollar debt; no dinar moved.
        $response->assertCreated()->assertJsonPath('data.currency', 'USD');
        $this->assertSame('4400.00', $this->balance($box));
        $this->assertSame('-900.00', $this->balance($this->dollarPayable($vendor)));
        $this->assertNull(app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id));
        $this->getJson("/api/v1/purchase-orders/{$order['id']}/payments", $this->headers)
            ->assertJsonPath('data.summary.paid', '600.00')
            ->assertJsonPath('data.summary.remaining', '900.00');
    }

    public function test_paying_the_whole_dollar_debt_closes_it_at_exactly_zero(): void
    {
        // Arrange — two payments from two dollar drawers, cash and bank.
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');
        $cash = $this->dollarBox('1000');
        $bank = $this->dollarBox('1000', 'bank');

        // Act
        $this->pay($vendor, ['amount' => '1000', 'purchase_order_id' => $order['id'], 'treasury_account_id' => $cash->id])->assertCreated();
        $this->pay($vendor, ['amount' => '500', 'method' => 'bank_transfer', 'purchase_order_id' => $order['id'], 'treasury_account_id' => $bank->id])->assertCreated();

        // Assert
        $this->assertSame('0.00', $this->balance($this->dollarPayable($vendor)));
        $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $this->headers)
            ->assertJsonPath('data.usd_summary.ordered', '1500.00')
            ->assertJsonPath('data.usd_summary.paid', '1500.00')
            ->assertJsonPath('data.usd_summary.owed', '0.00')
            ->assertJsonPath('data.summary.owed', '0.00');
    }

    public function test_a_dinar_account_cannot_pay_a_dollar_debt(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');

        // Act
        $response = $this->pay($vendor, [
            'amount' => '100',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $this->dinarBox()->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame('-1500.00', $this->balance($this->dollarPayable($vendor)));
    }

    public function test_a_dollar_payment_names_its_drawer(): void
    {
        // Arrange — no dollar default to fall into.
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');
        $this->dollarBox();

        // Act
        $response = $this->pay($vendor, ['amount' => '100', 'purchase_order_id' => $order['id']]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame(0, VendorPayment::query()->count());
    }

    public function test_a_dollar_account_cannot_pay_a_dinar_debt(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'LYD', '1500');
        $box = $this->dollarBox();

        // Act
        $response = $this->pay($vendor, [
            'amount' => '100',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $box->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame('5000.00', $this->balance($box));
    }

    public function test_a_currency_other_than_the_order_s_is_refused(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');

        // Act
        $response = $this->pay($vendor, [
            'amount' => '100',
            'currency' => 'LYD',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $this->dinarBox()->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('currency');
    }

    public function test_nothing_is_paid_in_advance_in_dollars_either(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');
        $box = $this->dollarBox('5000');

        // Act
        $response = $this->pay($vendor, [
            'amount' => '1500.01',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $box->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('5000.00', $this->balance($box));
    }

    public function test_a_dollar_drawer_must_hold_what_it_pays(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');
        $box = $this->dollarBox('100');

        // Act
        $response = $this->pay($vendor, [
            'amount' => '200',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $box->id,
        ]);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('100.00', $this->balance($box));
        $this->assertSame(0, VendorPayment::query()->count());
    }

    public function test_reversing_a_dollar_payment_returns_the_dollars_and_the_debt(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');
        $box = $this->dollarBox('5000');
        $paymentId = $this->pay($vendor, [
            'amount' => '600',
            'purchase_order_id' => $order['id'],
            'treasury_account_id' => $box->id,
        ])->json('data.id');

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments/{$paymentId}/reverse", [
            'reason' => 'سُجّلت مرتين',
        ], $this->headers);

        // Assert
        $response->assertCreated()->assertJsonPath('data.currency', 'USD');
        $this->assertSame('5000.00', $this->balance($box));
        $this->assertSame('-1500.00', $this->balance($this->dollarPayable($vendor)));
    }

    // ── what moves no money ─────────────────────────────────────────────────────────────

    public function test_a_credit_on_a_dollar_order_comes_off_the_dollar_debt(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->order($vendor, 'USD', '1500');

        // Act
        $response = $this->pay($vendor, [
            'type' => 'credit',
            'amount' => '200',
            'purchase_order_id' => $order['id'],
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.currency', 'USD');
        $this->assertSame('-1300.00', $this->balance($this->dollarPayable($vendor)));
        $this->assertSame(1, TreasuryMovement::query()
            ->where('account_id', $this->dollarPayable($vendor)->id)
            ->where('kind', MovementKind::VendorCredit->value)
            ->count());
    }

    public function test_an_opening_debt_in_dollars_opens_the_dollar_payable_and_is_paid_in_dollars(): void
    {
        // Arrange — an old dollar debt from before the system, on no order.
        $vendor = Vendor::factory()->create(['name' => 'مصنع قديم']);
        $box = $this->dollarBox('5000');

        // Act
        $debt = $this->pay($vendor, ['type' => 'opening_debt', 'amount' => '800', 'currency' => 'USD']);
        $paid = $this->pay($vendor, ['amount' => '300', 'currency' => 'USD', 'treasury_account_id' => $box->id]);
        $tooMuch = $this->pay($vendor, ['amount' => '501', 'currency' => 'USD', 'treasury_account_id' => $box->id]);

        // Assert
        $debt->assertCreated();
        $paid->assertCreated();
        $tooMuch->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('مصنع قديم (دولار)', $this->dollarPayable($vendor)->name);
        $this->assertSame('-500.00', $this->balance($this->dollarPayable($vendor)));
        $this->assertSame('4700.00', $this->balance($box));
    }

    public function test_undoing_a_dollar_opening_debt_is_held_to_what_is_owed_in_dollars(): void
    {
        // Arrange — 800 owed, 300 of it paid: undoing the 800 would leave $300 paid in advance.
        $vendor = Vendor::factory()->create();
        $box = $this->dollarBox('5000');
        $debtId = $this->pay($vendor, ['type' => 'opening_debt', 'amount' => '800', 'currency' => 'USD'])->json('data.id');
        $this->pay($vendor, ['amount' => '300', 'currency' => 'USD', 'treasury_account_id' => $box->id])->assertCreated();

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments/{$debtId}/reverse", [
            'reason' => 'خطأ',
        ], $this->headers);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('-500.00', $this->balance($this->dollarPayable($vendor)));
    }

    public function test_dinar_and_dollar_debts_of_one_vendor_never_mix(): void
    {
        // Arrange — owed 1,000 dinars and $1,500.
        $vendor = Vendor::factory()->create();
        $this->order($vendor, 'LYD', '1000');
        $dollarOrder = $this->order($vendor, 'USD', '1500');
        $box = $this->dollarBox('5000');

        // Act — $1,200 paid: more than the dinar debt, less than the dollar one.
        $this->pay($vendor, ['amount' => '1200', 'purchase_order_id' => $dollarOrder['id'], 'treasury_account_id' => $box->id])
            ->assertCreated();

        // Assert
        $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $this->headers)
            ->assertJsonPath('data.summary.paid', '0.00')
            ->assertJsonPath('data.summary.owed', '1000.00')
            ->assertJsonPath('data.usd_summary.paid', '1200.00')
            ->assertJsonPath('data.usd_summary.owed', '300.00');
        // And each payable agrees with its summary.
        $this->assertSame('-300.00', $this->balance($this->dollarPayable($vendor)));
        $dinars = TreasuryAccount::query()->findOrFail(app(TreasuryService::class)->payableIdOfVendor((int) $vendor->id));
        $this->assertSame('-1000.00', $this->balance($dinars));
    }

    // ── the picker ──────────────────────────────────────────────────────────────────────

    public function test_the_picker_offers_dollar_accounts_when_asked_and_suggests_none(): void
    {
        // Arrange
        $cash = $this->dollarBox('10');
        $bank = $this->dollarBox('10', 'bank');

        // Act
        $dollars = $this->getJson('/api/v1/treasury/account-options?method=cash&purpose=out&currency=USD', $this->headers);
        $dinars = $this->getJson('/api/v1/treasury/account-options?method=cash&purpose=out', $this->headers);

        // Assert
        $dollars->assertOk()
            ->assertJsonPath('data.suggested_id', null)
            ->assertJsonPath('data.accounts.0.id', $cash->id)
            ->assertJsonCount(1, 'data.accounts');
        $this->assertNotContains($cash->id, collect($dinars->json('data.accounts'))->pluck('id')->all());
        $this->assertNotContains($bank->id, collect($dinars->json('data.accounts'))->pluck('id')->all());
        $this->assertNotNull($dinars->json('data.suggested_id'));
    }
}
