<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Paying vendors, and what the company still owes them — TREASURY-DESIGN §٨.
 *
 * Arrange - Act - Assert throughout.
 */
class VendorPaymentTreasuryTest extends TestCase
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
    private function buyer(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewVendorPayments,
            PermissionName::RecordVendorPayments,
            PermissionName::ReverseVendorPayments,
            PermissionName::RecordTreasuryOperations,
        ]));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function bank(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', AccountKind::Bank->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function fundTheBank(array $headers, string $amount): void
    {
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->bank()->id, 'amount' => $amount,
        ], $headers)->assertCreated();
    }

    private function purchaseOrder(Vendor $vendor, string $total, bool $old = false): PurchaseOrder
    {
        return PurchaseOrder::factory()->create([
            'vendor_id' => $vendor->id,
            'total_amount' => $total,
            'predates_treasury' => $old,
        ]);
    }

    public function test_paying_for_a_purchase_order_leaves_the_bank_and_shows_what_is_still_owed(): void
    {
        // Arrange
        $headers = $this->buyer();
        $vendor = Vendor::factory()->create();
        $order = $this->purchaseOrder($vendor, '1000.00');
        $this->fundTheBank($headers, '5000');

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '600', 'method' => 'bank_transfer', 'purchase_order_id' => $order->id,
        ], $headers);

        // Assert
        $response->assertCreated()->assertJsonPath('data.treasury_account.id', $this->bank()->id);
        $this->assertSame('4400.00', $this->balance($this->bank()));

        $this->getJson("/api/v1/purchase-orders/{$order->id}/payments", $headers)
            ->assertOk()
            ->assertJsonPath('data.summary.total', '1000.00')
            ->assertJsonPath('data.summary.paid', '600.00')
            ->assertJsonPath('data.summary.remaining', '400.00');
    }

    public function test_a_vendor_cannot_be_paid_money_the_drawer_does_not_hold(): void
    {
        // Arrange — owed enough, so only the drawer stands in the way
        $headers = $this->buyer();
        $vendor = Vendor::factory()->create();
        $this->purchaseOrder($vendor, '1000.00');
        $this->fundTheBank($headers, '100');

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '150', 'method' => 'bank_transfer',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->assertSame('100.00', $this->balance($this->bank()));
    }

    public function test_a_payment_cannot_name_another_vendor_s_order(): void
    {
        // Arrange
        $headers = $this->buyer();
        $vendor = Vendor::factory()->create();
        $theirs = $this->purchaseOrder(Vendor::factory()->create(), '500.00');
        $this->fundTheBank($headers, '1000');

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '100', 'method' => 'bank_transfer', 'purchase_order_id' => $theirs->id,
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('purchase_order_id');
    }

    public function test_an_opening_debt_moves_no_money_and_raises_what_is_owed(): void
    {
        // Arrange
        $headers = $this->buyer();
        $vendor = Vendor::factory()->create();
        $this->purchaseOrder($vendor, '2000.00', old: true);

        // Act
        $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'type' => 'opening_debt', 'amount' => '750',
        ], $headers)->assertCreated();

        // Assert — the order from before the treasury counts nothing; the debt counts, on the
        // vendor's «علينا» account alone: no drawer moved
        $this->getJson("/api/v1/vendors/{$vendor->id}/payments", $headers)
            ->assertOk()
            ->assertJsonPath('data.summary.ordered', '0.00')
            ->assertJsonPath('data.summary.opening_debt', '750.00')
            ->assertJsonPath('data.summary.owed', '750.00');
        $this->assertSame(0, TreasuryMovement::query()
            ->whereHas('account', fn ($q) => $q->where('kind', '<>', AccountKind::Payable->value))
            ->count());
        $payable = TreasuryAccount::query()->where('vendor_id', $vendor->id)->firstOrFail();
        $this->assertSame('-750.00', $this->balance($payable));
    }

    public function test_an_order_from_before_the_treasury_shows_nothing_owed(): void
    {
        // Arrange
        $headers = $this->buyer();
        $order = $this->purchaseOrder(Vendor::factory()->create(), '900.00', old: true);

        // Act
        $response = $this->getJson("/api/v1/purchase-orders/{$order->id}/payments", $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.summary.predates_treasury', true)
            ->assertJsonPath('data.summary.remaining', null);
    }

    public function test_reversing_a_payment_puts_the_money_back_and_the_debt_back(): void
    {
        // Arrange
        $headers = $this->buyer();
        $vendor = Vendor::factory()->create();
        $order = $this->purchaseOrder($vendor, '1000.00');
        $this->fundTheBank($headers, '1000');
        $payment = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '1000', 'method' => 'bank_transfer', 'purchase_order_id' => $order->id,
        ], $headers)->json('data.id');

        // Act
        $first = $this->postJson("/api/v1/vendors/{$vendor->id}/payments/{$payment}/reverse", ['reason' => 'خطأ'], $headers);
        $second = $this->postJson("/api/v1/vendors/{$vendor->id}/payments/{$payment}/reverse", ['reason' => 'خطأ'], $headers);

        // Assert
        $first->assertCreated();
        $second->assertUnprocessable();
        $this->assertSame('1000.00', $this->balance($this->bank()));
        $this->getJson("/api/v1/purchase-orders/{$order->id}/payments", $headers)
            ->assertJsonPath('data.summary.remaining', '1000.00');
    }

    public function test_paying_a_vendor_takes_its_own_grant(): void
    {
        // Arrange
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewVendorPayments->value);
        $headers = ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
        $vendor = Vendor::factory()->create();

        // Act
        $response = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '10', 'method' => 'cash',
        ], $headers);

        // Assert
        $response->assertForbidden();
    }
}
