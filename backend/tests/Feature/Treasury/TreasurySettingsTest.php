<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «إعدادات المالية» — the owner's switches, and where each custody account settles into.
 * TREASURY-DESIGN §١٦.
 *
 * Arrange - Act - Assert throughout.
 */
class TreasurySettingsTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'shared-secret';

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake('local');
        config()->set('services.nawris.webhook_secret', self::SECRET);
        config()->set('services.nawris.webhook_ips', []);
        config()->set('services.nawris.log_channel', 'null');
    }

    /**
     * @return array{0: User, 1: array<string, string>}
     */
    private function owner(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::AdjustTreasuryBalances,
            PermissionName::ManageTreasury,
            PermissionName::ViewOrders,
            PermissionName::SettleOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::RecordVendorPayments,
        ]));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function nawris(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('system_code', TreasuryAccount::NAWRIS)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $values
     */
    private function set(array $headers, array $values): void
    {
        $this->putJson('/api/v1/treasury/settings', $values, $headers)->assertOk();
    }

    private function deliveredByNawris(string $collect): Order
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'items_total' => $collect,
            'delivery_price' => '0.00',
            'grand_total' => $collect,
        ]);

        $parcel = NawrisParcel::factory()->create([
            'reference' => 'ref-'.$order->id,
            'code' => 'CODE-'.$order->id,
            'amount_to_collect' => $collect,
            'delivery_price_deducted' => '0.00',
        ]);

        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $order->id,
            'amount_to_collect' => $collect,
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])->postJson('/api/v1/webhooks/nawris', [
            'remote_order_id' => 'ref-'.$order->id,
            'order_code' => 'CODE-'.$order->id,
            'to_status_code' => 7,
            'to_status_text' => 'تم التسليم',
            'order_price' => $collect,
        ])->assertOk();

        return $order->refresh();
    }

    // ── what the switches start as ──────────────────────────────────────────────────────

    public function test_every_switch_starts_where_the_system_already_stood(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act
        $response = $this->getJson('/api/v1/treasury/settings', $headers);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.own_account_first', true)
            ->assertJsonPath('data.block_overdraft', true)
            ->assertJsonPath('data.withdrawal_needs_reason', true)
            ->assertJsonPath('data.ask_carrier_fee', true)
            ->assertJsonPath('data.locked_until', null);
    }

    public function test_only_the_manage_grant_changes_them(): void
    {
        // Arrange
        $viewer = User::factory()->create();
        $viewer->givePermissionTo(PermissionName::ViewTreasury->value);
        $headers = ['Authorization' => 'Bearer '.$viewer->createToken('test')->plainTextToken];

        // Act
        $response = $this->putJson('/api/v1/treasury/settings', ['block_overdraft' => false], $headers);

        // Assert
        $response->assertForbidden();
    }

    // ── the switches ────────────────────────────────────────────────────────────────────

    public function test_with_own_account_first_off_a_payment_lands_in_the_default(): void
    {
        // Arrange
        [$ali, $headers] = $this->owner();
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create();
        $this->set($headers, ['own_account_first' => false]);
        $order = Order::factory()->create(['status' => OrderStatus::Delivered, 'grand_total' => '100.00', 'items_total' => '100.00']);

        // Act
        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments", [
            'amount' => '100',
            'method' => 'bank_transfer',
            'receipt' => UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf'),
        ])->assertCreated();

        // Assert
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_with_overdrafts_allowed_a_withdrawal_may_take_an_account_below_zero(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['block_overdraft' => false]);

        // Act
        $response = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal',
            'from_account_id' => $this->defaultOf(AccountKind::Cash)->id,
            'amount' => '50',
            'notes' => 'سلفة للمحل',
        ], $headers);

        // Assert
        $response->assertCreated();
        $this->assertSame('-50.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_the_withdrawal_reason_follows_its_switch(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->defaultOf(AccountKind::Cash)->id, 'amount' => '100',
        ], $headers)->assertCreated();
        $withdraw = fn () => $this->postJson('/api/v1/treasury/operations', [
            'type' => 'withdrawal', 'from_account_id' => $this->defaultOf(AccountKind::Cash)->id, 'amount' => '10',
        ], $headers);

        // Act
        $required = $withdraw();
        $this->set($headers, ['withdrawal_needs_reason' => false]);
        $optional = $withdraw();

        // Assert
        $required->assertUnprocessable()->assertJsonValidationErrors('notes');
        $optional->assertCreated();
    }

    public function test_a_locked_period_refuses_hand_operations_and_vendor_payments_dated_inside_it(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['locked_until' => now()->subDays(2)->toDateString()]);
        $vendor = Vendor::factory()->create();

        // Act
        $inside = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit',
            'to_account_id' => $this->defaultOf(AccountKind::Cash)->id,
            'amount' => '10',
            'occurred_at' => now()->subDays(3)->toIso8601String(),
        ], $headers);
        $after = $this->postJson('/api/v1/treasury/operations', [
            'type' => 'deposit', 'to_account_id' => $this->defaultOf(AccountKind::Cash)->id, 'amount' => '10',
        ], $headers);
        $vendorInside = $this->postJson("/api/v1/vendors/{$vendor->id}/payments", [
            'amount' => '5', 'method' => 'cash', 'paid_at' => now()->subDays(3)->toIso8601String(),
        ], $headers);

        // Assert
        $inside->assertUnprocessable()->assertJsonValidationErrors('occurred_at');
        $after->assertCreated();
        $vendorInside->assertUnprocessable()->assertJsonValidationErrors('paid_at');
    }

    public function test_a_lock_cannot_be_set_in_the_future_and_null_unlocks(): void
    {
        // Arrange
        [, $headers] = $this->owner();

        // Act
        $future = $this->putJson('/api/v1/treasury/settings', ['locked_until' => now()->addDay()->toDateString()], $headers);
        $this->set($headers, ['locked_until' => now()->subDay()->toDateString()]);
        $this->set($headers, ['locked_until' => null]);

        // Assert
        $future->assertUnprocessable()->assertJsonValidationErrors('locked_until');
        $this->getJson('/api/v1/treasury/settings', $headers)->assertJsonPath('data.locked_until', null);
    }

    public function test_the_settle_screen_stops_asking_what_the_carrier_kept_when_switched_off(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('100.00');
        $this->set($headers, ['ask_carrier_fee' => false]);

        // Act
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $fields = collect($response->json('data.available_transitions'))
            ->firstWhere('status', OrderStatus::Settled->value)['fields'] ?? [];
        $keys = array_column($fields, 'key');

        $this->assertContains('settlement_account_id', $keys);
        $this->assertNotContains('settlement_fee', $keys);
    }

    // ── «تُسوّى إلى» ────────────────────────────────────────────────────────────────────

    public function test_nawris_settles_into_the_account_the_owner_set(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $jumhuria = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف الجمهورية']);
        $this->putJson('/api/v1/treasury/accounts/'.$this->nawris()->id, [
            'settles_into_account_id' => $jumhuria->id,
        ], $headers)->assertOk()->assertJsonPath('data.settles_into.name', 'مصرف الجمهورية');
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
        ])->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($jumhuria));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_the_settlers_own_account_still_comes_before_it_while_that_switch_is_on(): void
    {
        // Arrange
        [$ali, $headers] = $this->owner();
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create();
        $jumhuria = TreasuryAccount::factory()->kind(AccountKind::Bank)->create();
        $this->putJson('/api/v1/treasury/accounts/'.$this->nawris()->id, [
            'settles_into_account_id' => $jumhuria->id,
        ], $headers)->assertOk();
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
        ])->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($jumhuria));
    }

    public function test_only_custody_settles_and_only_into_an_account_money_can_sit_in(): void
    {
        // Arrange
        [$salem, $headers] = $this->owner();
        $driver = TreasuryAccount::factory()->kind(AccountKind::Custody)->heldBy($salem)->create();

        // Act
        $onACashBox = $this->putJson('/api/v1/treasury/accounts/'.$this->defaultOf(AccountKind::Cash)->id, [
            'settles_into_account_id' => $this->defaultOf(AccountKind::Bank)->id,
        ], $headers);
        $intoCustody = $this->putJson('/api/v1/treasury/accounts/'.$this->nawris()->id, [
            'settles_into_account_id' => $driver->id,
        ], $headers);
        $cleared = $this->putJson('/api/v1/treasury/accounts/'.$this->nawris()->id, [
            'settles_into_account_id' => null,
        ], $headers);

        // Assert
        $onACashBox->assertUnprocessable()->assertJsonValidationErrors('settles_into_account_id');
        $intoCustody->assertUnprocessable()->assertJsonValidationErrors('settles_into_account_id');
        $cleared->assertOk()->assertJsonPath('data.settles_into_account_id', null);
    }

    public function test_the_categories_are_read_by_whoever_manages_them(): void
    {
        // Arrange
        $manager = User::factory()->create();
        $manager->givePermissionTo(PermissionName::ManageTreasury->value);
        $headers = ['Authorization' => 'Bearer '.$manager->createToken('test')->plainTextToken];
        $nobody = User::factory()->create();

        // Act
        $allowed = $this->getJson('/api/v1/treasury/expense-categories', $headers);
        $refused = $this->getJson('/api/v1/treasury/expense-categories', [
            'Authorization' => 'Bearer '.$nobody->createToken('test')->plainTextToken,
        ]);

        // Assert
        $allowed->assertOk();
        $refused->assertForbidden();
    }

    public function test_a_category_the_system_relies_on_stays_on_however_the_off_is_spelled(): void
    {
        // Arrange — «سلفة موظف» يعتمد عليها نموذجُ السلفة. قاعدةُ `boolean` تقبل 0 و"0" و false،
        // والمقارنةُ بـ`=== false` كانت تُمرّر الأوليين.
        [, $headers] = $this->owner();
        $advance = ExpenseCategory::query()->where('code', ExpenseCategory::ADVANCE)->firstOrFail();
        $switchOff = fn (mixed $off) => $this->putJson(
            "/api/v1/treasury/expense-categories/{$advance->id}",
            ['is_active' => $off],
            $headers,
        );

        // Act
        $asNumber = $switchOff(0);
        $asText = $switchOff('0');
        $asBoolean = $switchOff(false);

        // Assert
        $asNumber->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $asText->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $asBoolean->assertUnprocessable()->assertJsonValidationErrors('is_active');
        $this->assertTrue($advance->refresh()->is_active);
    }

    public function test_a_category_people_added_switches_off_with_a_zero(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $rent = ExpenseCategory::query()->where('name', 'إيجار')->firstOrFail();

        // Act
        $response = $this->putJson(
            "/api/v1/treasury/expense-categories/{$rent->id}",
            ['is_active' => '0'],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.is_active', false);
        $this->assertFalse($rent->refresh()->is_active);
    }
}
