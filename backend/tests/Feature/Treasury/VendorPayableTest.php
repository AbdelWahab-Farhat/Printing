<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\VendorPayment;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementDirection;
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
 * What the company owes each vendor, on the vendor's «علينا» account — TREASURY-DESIGN §٢٠.
 *
 * Owed from the moment an order is raised, at its full total; lowered by payments and credits;
 * and never paid in advance. Arrange - Act - Assert throughout.
 */
class VendorPayableTest extends TestCase
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
            PermissionName::ViewVendors,
            PermissionName::ManageVendors,
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
            PermissionName::ReverseVendorPayments,
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
            PermissionName::ManageTreasury,
        ]));

        $this->headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * An order through the API, so it goes the way a real one does. One line, costed `$cost`.
     */
    private function raise(Vendor $vendor, string $cost): PurchaseOrder
    {
        $id = $this->postJson('/api/v1/purchase-orders', [
            'vendor_id' => $vendor->id,
            'warehouse_id' => Warehouse::factory()->create()->id,
            'order_date' => now()->toDateString(),
            'items' => [['stock_item_id' => StockItem::factory()->create()->id, 'quantity_ordered' => 10, 'base_total_cost' => $cost]],
        ], $this->headers)->assertCreated()->json('data.id');

        return PurchaseOrder::query()->with('items')->findOrFail($id);
    }

    private function edit(PurchaseOrder $order, string $cost, ?Vendor $vendor = null): TestResponse
    {
        $line = $order->items->first();

        return $this->putJson("/api/v1/purchase-orders/{$order->id}", [
            'vendor_id' => $vendor?->id ?? $order->vendor_id,
            'warehouse_id' => $order->warehouse_id,
            'order_date' => now()->toDateString(),
            'items' => [['id' => $line->id, 'stock_item_id' => $line->stock_item_id, 'quantity_ordered' => 10, 'base_total_cost' => $cost]],
        ], $this->headers);
    }

    /**
     * @param  array<string, mixed>  $body
     */
    private function pay(Vendor $vendor, array $body): TestResponse
    {
        return $this->postJson("/api/v1/vendors/{$vendor->id}/payments", $body, $this->headers);
    }

    private function fundTheBank(string $amount): void
    {
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->bank()->id, 'amount' => $amount,
        ], $this->headers)->assertCreated();
    }

    private function bank(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', AccountKind::Bank->value)->where('is_default', true)->firstOrFail();
    }

    private function payableOf(Vendor $vendor): TreasuryAccount
    {
        return TreasuryAccount::query()->where('vendor_id', $vendor->id)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    private function owed(Vendor $vendor): string
    {
        return (string) $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $this->headers)->json('data.summary.owed');
    }

    public function test_raising_an_order_puts_its_total_on_the_vendor_s_payable(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create(['name' => 'مطبعة النور']);

        // Act
        $this->raise($vendor, '1000');

        // Assert
        $payable = $this->payableOf($vendor);
        $this->assertSame(AccountKind::Payable, $payable->kind);
        $this->assertSame('مطبعة النور', $payable->name);
        $this->assertSame('-1000.00', $this->balance($payable));
        $this->assertSame('1000.00', $this->owed($vendor));
        $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $this->headers)
            ->assertJsonPath('data.treasury_account_id', $payable->id);
    }

    public function test_editing_the_total_reposts_the_debt_and_the_same_total_writes_nothing(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->raise($vendor, '1000');

        // Act
        $this->edit($order, '1200')->assertOk();
        $this->edit($order->fresh('items'), '1200')->assertOk();

        // Assert — the original, its reversal, and the new figure; the second save added nothing
        $payable = $this->payableOf($vendor);
        $this->assertSame('-1200.00', $this->balance($payable));
        $this->assertSame(3, TreasuryMovement::query()->where('account_id', $payable->id)->where('kind', MovementKind::Purchase->value)->count());
        $this->assertSame('1200.00', $this->owed($vendor));
    }

    public function test_moving_an_order_to_another_vendor_moves_its_debt(): void
    {
        // Arrange
        $first = Vendor::factory()->create();
        $second = Vendor::factory()->create();
        $order = $this->raise($first, '800');

        // Act
        $this->edit($order, '800', $second)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($this->payableOf($first)));
        $this->assertSame('-800.00', $this->balance($this->payableOf($second)));
    }

    public function test_cancelling_an_unpaid_order_clears_its_debt(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->raise($vendor, '1000');

        // Act
        $response = $this->patchJson("/api/v1/purchase-orders/{$order->id}/status", ['status' => 'cancelled'], $this->headers);

        // Assert
        $response->assertOk();
        $this->assertSame('0.00', $this->balance($this->payableOf($vendor)));
        $this->assertSame('0.00', $this->owed($vendor));
    }

    public function test_a_paid_order_cannot_be_cancelled_nor_cut_below_what_was_paid_nor_moved(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->raise($vendor, '1000');
        $this->fundTheBank('1000');
        $this->pay($vendor, ['amount' => '600', 'method' => 'bank_transfer', 'purchase_order_id' => $order->id])->assertCreated();

        // Act
        $cancel = $this->patchJson("/api/v1/purchase-orders/{$order->id}/status", ['status' => 'cancelled'], $this->headers);
        $cut = $this->edit($order, '500');
        $moved = $this->edit($order, '1000', Vendor::factory()->create());

        // Assert — and the debt stands as it was
        $cancel->assertUnprocessable();
        $cut->assertUnprocessable();
        $moved->assertUnprocessable()->assertJsonValidationErrors('vendor_id');
        $this->assertSame('-400.00', $this->balance($this->payableOf($vendor)));
        $this->assertSame('1000.00', (string) $order->fresh()->total_amount);
    }

    public function test_a_payment_lowers_the_debt_and_its_reversal_puts_both_back(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->raise($vendor, '1000');
        $this->fundTheBank('1000');

        // Act
        $payment = $this->pay($vendor, ['amount' => '1000', 'method' => 'bank_transfer', 'purchase_order_id' => $order->id])
            ->assertCreated()->json('data.id');
        $paidOff = $this->balance($this->payableOf($vendor));
        $this->postJson("/api/v1/vendors/{$vendor->id}/payments/{$payment}/reverse", ['reason' => 'خطأ'], $this->headers)
            ->assertCreated();

        // Assert
        $this->assertSame('0.00', $paidOff);
        $this->assertSame('-1000.00', $this->balance($this->payableOf($vendor)));
        $this->assertSame('1000.00', $this->balance($this->bank()));
    }

    public function test_nothing_is_paid_in_advance(): void
    {
        // Arrange — two orders: 1,000 and 300
        $vendor = Vendor::factory()->create();
        $big = $this->raise($vendor, '1000');
        $this->raise($vendor, '300');
        $this->fundTheBank('5000');

        // Act
        $overOrder = $this->pay($vendor, ['amount' => '1100', 'method' => 'bank_transfer', 'purchase_order_id' => $big->id]);
        $overAll = $this->pay($vendor, ['amount' => '1400', 'method' => 'bank_transfer']);
        $exact = $this->pay($vendor, ['amount' => '1300', 'method' => 'bank_transfer']);
        $after = $this->pay($vendor, ['amount' => '1', 'method' => 'bank_transfer']);

        // Assert
        $overOrder->assertUnprocessable()->assertJsonValidationErrors('amount');
        $overAll->assertUnprocessable()->assertJsonValidationErrors('amount');
        $exact->assertCreated();
        $after->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('0.00', $this->balance($this->payableOf($vendor)));
        $this->assertSame('3700.00', $this->balance($this->bank()));
    }

    public function test_a_credit_lowers_the_debt_without_any_money_and_counts_on_the_order(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create();
        $order = $this->raise($vendor, '1000');

        // Act — the vendor sent short, and knocks 150 off
        $credit = $this->pay($vendor, ['type' => 'credit', 'amount' => '150', 'purchase_order_id' => $order->id]);
        $tooBig = $this->pay($vendor, ['type' => 'credit', 'amount' => '900', 'purchase_order_id' => $order->id]);

        // Assert
        $credit->assertCreated()->assertJsonPath('data.type', 'credit')->assertJsonPath('data.method', null);
        $tooBig->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('-850.00', $this->balance($this->payableOf($vendor)));
        $this->getJson("/api/v1/purchase-orders/{$order->id}/payments", $this->headers)
            ->assertJsonPath('data.summary.credited', '150.00')
            ->assertJsonPath('data.summary.remaining', '850.00');
        $this->assertSame(0, TreasuryMovement::query()->where('account_id', $this->bank()->id)->count());
    }

    public function test_an_opening_debt_already_paid_cannot_be_reversed(): void
    {
        // Arrange — owed 500 from before, all of it paid
        $vendor = Vendor::factory()->create();
        $debt = $this->pay($vendor, ['type' => 'opening_debt', 'amount' => '500'])->assertCreated()->json('data.id');
        $this->fundTheBank('500');
        $this->pay($vendor, ['amount' => '500', 'method' => 'bank_transfer'])->assertCreated();

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments/{$debt}/reverse", ['reason' => 'خطأ'], $this->headers);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame('0.00', $this->balance($this->payableOf($vendor)));
    }

    public function test_a_vendor_s_payable_takes_nothing_by_hand_and_follows_the_vendor_s_name(): void
    {
        // Arrange
        $vendor = Vendor::factory()->create(['name' => 'الاسم القديم', 'phone' => '0911111111']);
        $this->raise($vendor, '1000');
        $payable = $this->payableOf($vendor);

        // Act
        $transfer = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer', 'from_account_id' => $payable->id, 'to_account_id' => $this->bank()->id, 'amount' => '10',
        ], $this->headers);
        $count = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment', 'to_account_id' => $payable->id, 'counted_balance' => '0', 'notes' => 'تجربة',
        ], $this->headers);
        $rename = $this->putJson("/api/v1/treasury/accounts/{$payable->id}", ['name' => 'غيره'], $this->headers);
        $this->putJson("/api/v1/vendors/{$vendor->id}", ['name' => 'الاسم الجديد', 'phone' => '0911111111'], $this->headers)
            ->assertOk();

        // Assert
        $transfer->assertUnprocessable()->assertJsonValidationErrors('from_account_id');
        $count->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
        $rename->assertUnprocessable()->assertJsonValidationErrors('name');
        $this->assertSame('الاسم الجديد', $payable->fresh()->name);
        $this->assertSame('-1000.00', $this->balance($payable));
    }

    public function test_an_order_from_before_the_treasury_is_paid_up_to_its_total_and_off_the_payable(): void
    {
        // Arrange — an old order of 1,602 the vendor is still owed, nothing on the treasury
        $vendor = Vendor::factory()->create();
        $old = PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '1602.00', 'predates_treasury' => true]);
        $this->fundTheBank('5000');

        // Act
        $first = $this->pay($vendor, ['amount' => '1000', 'method' => 'bank_transfer', 'purchase_order_id' => $old->id]);
        $tooMuch = $this->pay($vendor, ['amount' => '700', 'method' => 'bank_transfer', 'purchase_order_id' => $old->id]);
        $rest = $this->pay($vendor, ['amount' => '602', 'method' => 'bank_transfer', 'purchase_order_id' => $old->id]);

        // Assert — the money left the bank; «علينا» never heard of it
        $first->assertCreated();
        $tooMuch->assertUnprocessable()->assertJsonValidationErrors('amount');
        $rest->assertCreated();
        $this->assertSame('3398.00', $this->balance($this->bank()));
        $this->assertFalse(TreasuryAccount::query()->where('vendor_id', $vendor->id)->exists());
        $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $this->headers)
            ->assertJsonPath('data.summary.owed', '0.00')
            ->assertJsonPath('data.summary.paid_on_old_orders', '1602.00');
        $this->getJson("/api/v1/purchase-orders/{$old->id}/payments", $this->headers)
            ->assertJsonPath('data.summary.remaining', null)
            ->assertJsonPath('data.summary.payable_up_to', '0.00');
    }

    public function test_an_old_order_still_owed_can_be_counted_onto_the_payable_with_what_was_paid_since(): void
    {
        // Arrange — an old order of 1,602, 600 of it paid since the treasury
        $vendor = Vendor::factory()->create();
        $old = PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '1602.00', 'predates_treasury' => true]);
        $this->fundTheBank('5000');
        $this->pay($vendor, ['amount' => '600', 'method' => 'bank_transfer', 'purchase_order_id' => $old->id])->assertCreated();

        // Act
        $counted = $this->postJson("/api/v1/purchase-orders/{$old->id}/count-as-debt", [], $this->headers);
        $again = $this->postJson("/api/v1/purchase-orders/{$old->id}/count-as-debt", [], $this->headers);

        // Assert — owed what is left, on «علينا» and in the summary alike; now an ordinary order
        $counted->assertOk()
            ->assertJsonPath('data.summary.predates_treasury', false)
            ->assertJsonPath('data.summary.remaining', '1002.00');
        $again->assertUnprocessable();
        $this->assertSame('-1002.00', $this->balance($this->payableOf($vendor)));
        $this->assertSame('1002.00', $this->owed($vendor));
        $this->pay($vendor, ['amount' => '1100', 'method' => 'bank_transfer', 'purchase_order_id' => $old->id])
            ->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->pay($vendor, ['amount' => '1002', 'method' => 'bank_transfer', 'purchase_order_id' => $old->id])
            ->assertCreated();
        $this->assertSame('0.00', $this->balance($this->payableOf($vendor)));
    }

    public function test_counting_an_old_order_takes_the_grant_to_pay_vendors(): void
    {
        // Arrange
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewVendorPayments->value);
        $old = PurchaseOrder::factory()->create(['total_amount' => '500.00', 'predates_treasury' => true]);

        // Act
        $response = $this->postJson("/api/v1/purchase-orders/{$old->id}/count-as-debt", [], [
            'Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken,
        ]);

        // Assert
        $response->assertForbidden();
        $this->assertTrue((bool) $old->fresh()->predates_treasury);
    }

    public function test_the_backfill_takes_an_old_order_s_payment_back_off_the_payable(): void
    {
        // Arrange — what an earlier run of the backfill did: a payment on an old order, posted to
        // the vendor's payable, which then read «لنا عنده 4,000»
        $vendor = Vendor::factory()->create();
        $old = PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '4000.00', 'predates_treasury' => true]);
        $payment = VendorPayment::factory()->create([
            'vendor_id' => $vendor->id,
            'purchase_order_id' => $old->id,
            'type' => 'payment',
            'amount' => '4000.00',
            'method' => 'cash',
            'treasury_account_id' => TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->value('id'),
        ]);
        $treasury = app(TreasuryService::class);
        $payable = $treasury->payableForVendor($vendor->id, (string) $vendor->name);
        $treasury->post(new MovementData(
            accountId: (int) $payable->id,
            direction: MovementDirection::In,
            kind: MovementKind::VendorPayment,
            amount: '4000.00',
            occurredAt: now(),
            sourceType: $payment->getMorphClass(),
            sourceId: (int) $payment->id,
        ));

        // Act
        $this->artisan('treasury:post-vendor-payables', ['--apply' => true])->assertSuccessful();

        // Assert
        $this->assertSame('0.00', $this->balance($payable));
    }

    public function test_the_backfill_posts_what_came_before_once_and_matches_the_summary(): void
    {
        // Arrange — rows written the way they were before «علينا»: an order with no debt posted,
        // an opening debt and a payment with no payable movement
        $vendor = Vendor::factory()->create();
        $order = PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '900.00', 'predates_treasury' => false]);
        PurchaseOrder::factory()->create(['vendor_id' => $vendor->id, 'total_amount' => '5000.00', 'predates_treasury' => true]);
        $debt = VendorPayment::factory()->create(['vendor_id' => $vendor->id, 'type' => 'opening_debt', 'amount' => '200.00']);
        $paid = VendorPayment::factory()->create([
            'vendor_id' => $vendor->id,
            'purchase_order_id' => $order->id,
            'type' => 'payment',
            'amount' => '300.00',
            'method' => 'cash',
            'treasury_account_id' => TreasuryAccount::query()->where('kind', 'cash')->where('is_default', true)->value('id'),
        ]);

        // Act
        $this->artisan('treasury:post-vendor-payables')->assertSuccessful();
        $dryRunWroteNothing = ! TreasuryAccount::query()->where('vendor_id', $vendor->id)->exists();
        $this->artisan('treasury:post-vendor-payables', ['--apply' => true])->assertSuccessful();
        $this->artisan('treasury:post-vendor-payables', ['--apply' => true])->assertSuccessful();

        // Assert — 900 + 200 − 300, posted once, equal to the summary
        $this->assertTrue($dryRunWroteNothing);
        $payable = $this->payableOf($vendor);
        $this->assertSame('-800.00', $this->balance($payable));
        $this->assertSame('800.00', $this->owed($vendor));
        $this->assertSame(3, TreasuryMovement::query()->where('account_id', $payable->id)->count());
        $this->assertNotNull($debt->id);
        $this->assertNotNull($paid->id);
    }
}
