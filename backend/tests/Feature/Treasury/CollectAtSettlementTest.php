<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «التجميع عند التسوية» — at «تم التسوية», the order's money in «مصرف علي», «مصرف عمر» or a
 * branch's cash box moves to the one account its kind is collected in. TREASURY-DESIGN §١٨.
 *
 * Arrange - Act - Assert throughout.
 */
class CollectAtSettlementTest extends TestCase
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
            PermissionName::ManageTreasury,
            PermissionName::ViewOrders,
            PermissionName::SettleOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
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

    private function bank(string $name, array $extra = []): TreasuryAccount
    {
        return TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => $name] + $extra);
    }

    private function cashBox(string $name, array $extra = []): TreasuryAccount
    {
        return TreasuryAccount::factory()->kind(AccountKind::Cash)->create(['name' => $name] + $extra);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $values
     */
    private function set(array $headers, array $values): void
    {
        $this->putJson('/api/v1/treasury/settings', $values, $headers)->assertOk();
    }

    private function order(string $total, OrderStatus $status = OrderStatus::Delivered): Order
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
     */
    private function pay(array $headers, Order $order, string $amount, TreasuryAccount $into): TestResponse
    {
        $body = ['amount' => $amount, 'method' => 'cash', 'treasury_account_id' => $into->id];

        if ($into->kind === AccountKind::Bank) {
            $body['method'] = 'bank_transfer';
            $body['receipt'] = UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf');
        }

        return $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments", $body);
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

    private function deliveredByNawris(string $collect): Order
    {
        $order = $this->order($collect, OrderStatus::OutForDelivery);

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

    // ── the switches ────────────────────────────────────────────────────────────────────

    public function test_every_kind_starts_switched_off_and_settling_moves_nothing(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $alisBank = $this->bank('مصرف علي');
        $order = $this->order('300.00');
        $this->pay($headers, $order, '300', $alisBank)->assertCreated();

        // Act
        $settings = $this->getJson('/api/v1/treasury/settings', $headers);
        $this->settle($headers, $order)->assertOk();

        // Assert
        $settings->assertJsonPath('data.collect_cash', false)
            ->assertJsonPath('data.collect_bank', false)
            ->assertJsonPath('data.collect_wallet', false)
            ->assertJsonPath('data.collect_bank_into_id', null);
        $this->assertSame('300.00', $this->balance($alisBank));
        $this->assertSame(0, TreasuryOperation::query()->count());
    }

    public function test_two_employees_banks_are_collected_into_the_default_bank(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['collect_bank' => true]);
        $alisBank = $this->bank('مصرف علي');
        $omarsBank = $this->bank('مصرف عمر');
        $order = $this->order('500.00');
        $this->pay($headers, $order, '300', $alisBank)->assertCreated();
        $this->pay($headers, $order, '200', $omarsBank)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert — one operation per account emptied, both into the bank
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($omarsBank));
        $this->assertSame('500.00', $this->balance($this->defaultOf(AccountKind::Bank)));

        $operations = TreasuryOperation::query()->where('type', OperationType::Settlement->value)->get();
        $this->assertCount(2, $operations);
        $this->assertSame("تجميع الطلبية {$order->code}", $operations->first()->notes);
    }

    public function test_a_branch_box_is_collected_into_the_cash_account_named_in_the_settings(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $misrata = $this->cashBox('خزنة فرع مصراتة');
        $head = $this->cashBox('خزنة الإدارة');
        $this->set($headers, ['collect_cash' => true, 'collect_cash_into_id' => $head->id]);
        $order = $this->order('150.00');
        $this->pay($headers, $order, '150', $misrata)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert — not the default box: the one the owner named
        $this->assertSame('0.00', $this->balance($misrata));
        $this->assertSame('150.00', $this->balance($head));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_only_what_sits_outside_the_collecting_account_moves(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['collect_bank' => true]);
        $alisBank = $this->bank('مصرف علي');
        $order = $this->order('150.00');
        $this->pay($headers, $order, '100', $this->defaultOf(AccountKind::Bank))->assertCreated();
        $this->pay($headers, $order, '50', $alisBank)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame('150.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(1, TreasuryOperation::query()->count());
        $this->assertSame('50.00', (string) TreasuryOperation::query()->sole()->amount);
    }

    public function test_money_already_carried_by_hand_is_not_carried_again(): void
    {
        // Arrange — Ali moved the 300 to the bank himself before the order was settled
        [$owner, $headers] = $this->owner();
        $this->set($headers, ['collect_bank' => true]);
        $alisBank = $this->bank('مصرف علي');
        $order = $this->order('300.00');
        $this->pay($headers, $order, '300', $alisBank)->assertCreated();
        app(TreasuryService::class)->recordOperation(OperationData::fromArray([
            'type' => 'transfer',
            'from_account_id' => $alisBank->id,
            'to_account_id' => $this->defaultOf(AccountKind::Bank)->id,
            'amount' => '300',
        ]), $owner);

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert — nothing counted twice, nothing below zero
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('300.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(0, TreasuryOperation::query()->where('type', OperationType::Settlement->value)->count());
    }

    public function test_an_account_marked_not_collected_keeps_its_money(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['collect_cash' => true]);
        $float = $this->cashBox('خزنة فرع بنغازي', ['is_collected' => false]);
        $order = $this->order('80.00');
        $this->pay($headers, $order, '80', $float)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame('80.00', $this->balance($float));
        $this->assertSame(0, TreasuryOperation::query()->count());
    }

    // ── with Nawris ─────────────────────────────────────────────────────────────────────

    public function test_nawris_money_goes_straight_to_the_collecting_bank_not_via_the_settlers_own(): void
    {
        // Arrange — Ali holds a bank account, and «الحساب الشخصي أولاً» is on
        [$ali, $headers] = $this->owner();
        $this->set($headers, ['collect_bank' => true]);
        $alisBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->heldBy($ali)->create();
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert — one hop, not two
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(1, TreasuryOperation::query()->count());
    }

    public function test_an_account_picked_by_hand_on_the_settle_screen_is_not_collected(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['collect_bank' => true]);
        $alisBank = $this->bank('مصرف علي');
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->settle($headers, $order, ['settlement_account_id' => $alisBank->id])->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    // ── undoing ─────────────────────────────────────────────────────────────────────────

    public function test_reversing_alis_payment_unwinds_alis_collection_and_leaves_omars(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->set($headers, ['collect_bank' => true]);
        $alisBank = $this->bank('مصرف علي');
        $omarsBank = $this->bank('مصرف عمر');
        $order = $this->order('500.00');
        $this->pay($headers, $order, '300', $alisBank)->assertCreated();
        $this->pay($headers, $order, '200', $omarsBank)->assertCreated();
        $this->settle($headers, $order)->assertOk();
        $alisPayment = OrderPayment::query()->where('order_id', $order->id)->where('treasury_account_id', $alisBank->id)->sole();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/{$alisPayment->id}/reverse", [
            'reason' => 'التحويل لم يصل',
        ])->assertCreated();

        // Assert — the 300 came back to Ali's bank and went out again; Omar's 200 stays collected
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($omarsBank));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    // ── the settings themselves ─────────────────────────────────────────────────────────

    public function test_a_kind_is_collected_only_into_an_active_account_of_that_kind(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $switchedOff = $this->bank('مصرف قديم', ['is_active' => false]);

        // Act
        $wrongKind = $this->putJson('/api/v1/treasury/settings', [
            'collect_bank' => true,
            'collect_bank_into_id' => $this->defaultOf(AccountKind::Cash)->id,
        ], $headers);
        $inactive = $this->putJson('/api/v1/treasury/settings', ['collect_bank_into_id' => $switchedOff->id], $headers);

        // Assert — and nothing of the refused request was kept
        $wrongKind->assertUnprocessable()->assertJsonValidationErrors('collect_bank_into_id');
        $inactive->assertUnprocessable()->assertJsonValidationErrors('collect_bank_into_id');
        $this->getJson('/api/v1/treasury/settings', $headers)->assertJsonPath('data.collect_bank', false);
    }

    public function test_an_account_can_be_marked_not_collected(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $box = $this->cashBox('خزنة فرع بنغازي');

        // Act
        $response = $this->putJson("/api/v1/treasury/accounts/{$box->id}", ['is_collected' => false], $headers);

        // Assert
        $response->assertOk()->assertJsonPath('data.is_collected', false);
        $this->assertFalse((bool) $box->fresh()->is_collected);
    }
}
