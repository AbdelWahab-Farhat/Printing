<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\DeleteOrder;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * A customer's money, from the counter or the doorstep to the account it ends in — and back out
 * when an entry turns out wrong. TREASURY-DESIGN §٥–§٧.
 *
 * **The spec's own example is {@see test_one_order_paid_two_ways_lands_in_two_accounts()}**:
 * 150 owed, 50 deposited by bank and 100 collected by Nawris.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderMoneyTreasuryTest extends TestCase
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
    private function cashier(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewOrders,
            PermissionName::MarkOrdersDelivered,
            PermissionName::SettleOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::WriteOffOrderPayments,
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

    private function order(OrderStatus $status = OrderStatus::Delivered, string $total = '150.00'): Order
    {
        return Order::factory()->create([
            'status' => $status,
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $extra
     */
    private function pay(array $headers, Order $order, string $amount, string $method = 'cash', array $extra = []): TestResponse
    {
        $body = ['amount' => $amount, 'method' => $method] + $extra;

        if ($method === 'bank_transfer') {
            $body['receipt'] = UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf');
        }

        return $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments", $body);
    }

    /**
     * Nawris says code 7 for this order: delivered, with the COD collected at the door.
     */
    private function deliveredByNawris(Order $order, string $collect): void
    {
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
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $fields
     */
    private function settle(array $headers, Order $order, array $fields = []): TestResponse
    {
        return $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
            'fields' => $fields,
        ]);
    }

    // ── a payment lands somewhere ───────────────────────────────────────────────────────

    public function test_a_payment_from_an_app_that_sends_no_account_lands_in_the_default(): void
    {
        // Arrange — exactly what today's app sends: amount and method, nothing more.
        [, $headers] = $this->cashier();
        $order = $this->order();

        // Act
        $response = $this->pay($headers, $order, '100');

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.payment.treasury_account.id', $this->defaultOf(AccountKind::Cash)->id);
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Cash)));

        $movement = TreasuryMovement::query()->sole();
        $this->assertSame((int) $order->id, (int) $movement->order_id);
        $this->assertSame('order_payment', $movement->source_type);
    }

    public function test_one_order_paid_two_ways_lands_in_two_accounts(): void
    {
        // Arrange — the spec's example: 150 owed, 50 by bank as a deposit, 100 through Nawris.
        [, $headers] = $this->cashier();
        $order = $this->order(OrderStatus::OutForDelivery);

        // Act
        $this->pay($headers, $order, '50', 'bank_transfer')->assertCreated();
        $this->deliveredByNawris($order, '100.00');

        // Assert
        $order->refresh();
        $this->assertSame('150.00', (string) $order->paid_amount);
        $this->assertSame('0.00', $order->remainingAmount());
        $this->assertSame('50.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('100.00', $this->balance($this->nawris()));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_a_payment_lands_in_the_account_of_whoever_records_it(): void
    {
        // Arrange — «مصرف علي»: Ali records a transfer and it is his account's by default.
        [$ali, $headers] = $this->cashier();
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create(['name' => 'مصرف علي']);
        $order = $this->order();

        // Act
        $this->pay($headers, $order, '60', 'bank_transfer')->assertCreated();

        // Assert
        $this->assertSame('60.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_a_chosen_account_that_does_not_fit_the_method_is_refused_and_nothing_is_written(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $order = $this->order();

        // Act
        $response = $this->pay($headers, $order, '60', 'cash', [
            'treasury_account_id' => $this->defaultOf(AccountKind::Bank)->id,
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $this->assertSame(0, OrderPayment::query()->count());
        $this->assertSame(0, TreasuryMovement::query()->count());
    }

    public function test_a_refund_leaves_a_real_drawer_never_nawris(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $order = $this->order();
        $this->pay($headers, $order, '100')->assertCreated();

        // Act
        $fromNawris = $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '20', 'method' => 'cash', 'treasury_account_id' => $this->nawris()->id,
        ]);
        $fromDefault = $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '20', 'method' => 'cash',
        ]);

        // Assert
        $fromNawris->assertUnprocessable()->assertJsonValidationErrors('treasury_account_id');
        $fromDefault->assertCreated();
        $this->assertSame('80.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    // ── and comes back out when it was a mistake ────────────────────────────────────────

    public function test_reversing_a_payment_takes_it_back_out_of_its_own_account(): void
    {
        // Arrange
        [$ali, $headers] = $this->cashier();
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create();
        $order = $this->order();
        $payment = $this->pay($headers, $order, '60', 'bank_transfer')->json('data.payment.id');

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/{$payment}/reverse", [
            'reason' => 'رقم خاطئ',
        ])->assertCreated();

        // Assert
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame(2, TreasuryMovement::query()->count());
    }

    public function test_a_write_off_moves_no_money(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $order = $this->order();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/write-offs", [
            'amount' => '5', 'reason' => 'فرق بسيط',
        ])->assertCreated();

        // Assert
        $this->assertSame(0, TreasuryMovement::query()->count());
    }

    public function test_deleting_an_order_takes_its_money_back_out(): void
    {
        // Arrange
        [$user, $headers] = $this->cashier();
        $order = $this->order(OrderStatus::New);
        $this->pay($headers, $order, '40')->assertCreated();

        // Act
        app(DeleteOrder::class)($order->refresh(), $user);

        // Assert
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    // ── «تم التسوية» ────────────────────────────────────────────────────────────────────

    public function test_settling_carries_nawris_money_to_the_bank_as_one_transfer_not_a_second_payment(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $order = $this->order(OrderStatus::OutForDelivery, '100.00');
        $this->deliveredByNawris($order, '100.00');

        // Act
        $response = $this->settle($headers, $order);

        // Assert
        $response->assertOk();
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('100.00', (string) $order->fresh()->paid_amount);

        $settlement = TreasuryOperation::query()->where('type', OperationType::Settlement->value)->sole();
        $this->assertSame((int) $order->id, (int) $settlement->order_id);
    }

    public function test_the_settle_screen_asks_where_the_money_arrived_only_when_something_is_held(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $viaNawris = $this->order(OrderStatus::OutForDelivery, '100.00');
        $this->deliveredByNawris($viaNawris, '100.00');
        $atTheCounter = $this->order();
        $this->pay($headers, $atTheCounter, '150')->assertCreated();

        // Act
        $held = $this->withHeaders($headers)->getJson("/api/v1/orders/{$viaNawris->id}");
        $notHeld = $this->withHeaders($headers)->getJson("/api/v1/orders/{$atTheCounter->id}");

        // Assert
        $keys = fn (TestResponse $r) => collect($r->json('data.available_transitions'))
            ->firstWhere('status', OrderStatus::Settled->value)['fields'] ?? [];

        $this->assertContains('settlement_account_id', array_column($keys($held), 'key'));
        $this->assertNotContains('settlement_account_id', array_column($keys($notHeld), 'key'));
    }

    public function test_settling_into_a_chosen_account_with_what_the_carrier_kept(): void
    {
        // Arrange
        [$omar, $headers] = $this->cashier();
        $omarsBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف عمر']);
        $order = $this->order(OrderStatus::OutForDelivery, '100.00');
        $this->deliveredByNawris($order, '100.00');

        // Act
        $this->settle($headers, $order, [
            'settlement_account_id' => $omarsBank->id,
            'settlement_fee' => '5',
        ])->assertOk();

        // Assert — 95 arrived, 5 is an expense, Nawris owes nothing
        $this->assertSame('95.00', $this->balance($omarsBank));
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame(1, TreasuryMovement::query()->where('kind', 'expense')->count());
    }

    public function test_the_settler_s_own_account_is_the_default_destination(): void
    {
        // Arrange
        [$ali, $headers] = $this->cashier();
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create();
        $order = $this->order(OrderStatus::OutForDelivery, '100.00');
        $this->deliveredByNawris($order, '100.00');

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($alisBank));
    }

    public function test_settling_an_order_paid_straight_into_the_bank_moves_nothing(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $order = $this->order();
        $this->pay($headers, $order, '150', 'bank_transfer')->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame(0, TreasuryOperation::query()->count());
        $this->assertSame('150.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_reversing_a_payment_already_settled_takes_it_out_of_where_it_arrived(): void
    {
        // Arrange
        [, $headers] = $this->cashier();
        $order = $this->order(OrderStatus::OutForDelivery, '100.00');
        $this->deliveredByNawris($order, '100.00');
        $this->settle($headers, $order)->assertOk();
        $payment = OrderPayment::query()->where('order_id', $order->id)->where('type', 'payment')->sole();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/{$payment->id}/reverse", [
            'reason' => 'لم يُحصَّل فعلاً',
        ])->assertCreated();

        // Assert — the settlement is undone first, so nothing is left below zero
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame('0.00', $this->balance($this->nawris()));
    }
}
