<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
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
 * «اختيار حساب كل نوع عند التسوية» — at «تم التسوية», the settler picks one account for each kind
 * of the order's money: cash into a cash account, bank into a bank, ليبيانا into a wallet.
 * TREASURY-DESIGN §٢٤.
 *
 * Arrange - Act - Assert throughout.
 */
class PickSettlementAccountsTest extends TestCase
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
    private function staff(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, [
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ManageTreasury,
            PermissionName::ViewOrders,
            PermissionName::SettleOrders,
            PermissionName::UnsettleOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::TopUpCustomerWallets,
        ]));

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    private function defaultOf(AccountKind $kind): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', $kind->value)->where('is_default', true)->firstOrFail();
    }

    private function balance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    /**
     * @param  array<string, mixed>  $extra
     */
    private function account(AccountKind $kind, string $name, ?User $holder = null, array $extra = []): TreasuryAccount
    {
        $factory = TreasuryAccount::factory()->kind($kind);

        return ($holder === null ? $factory : $factory->heldBy($holder))->create(['name' => $name] + $extra);
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

    /**
     * @param  array<string, string>  $headers
     * @return list<array<string, mixed>>
     */
    private function settleFields(array $headers, Order $order): array
    {
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}")->assertOk();

        return collect($response->json('data.available_transitions'))
            ->firstWhere('status', OrderStatus::Settled->value)['fields'] ?? [];
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

        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => ['to_status_code' => 4, 'order_price' => $collect],
            'status_code' => 4,
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

    // ── the switch ──────────────────────────────────────────────────────────────────────

    public function test_it_starts_off_and_the_screen_asks_nothing(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $order = $this->order('200.00');
        $this->pay($headers, $order, '200', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $settings = $this->getJson('/api/v1/treasury/settings', $headers);
        $fields = $this->settleFields($headers, $order);
        $this->settle($headers, $order)->assertOk();

        // Assert
        $settings->assertJsonPath('data.pick_settlement_accounts', false);
        $this->assertNotContains('settlement_cash_account_id', array_column($fields, 'key'));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_the_switch_is_saved_and_read_back(): void
    {
        // Arrange
        [, $headers] = $this->staff();

        // Act
        $saved = $this->putJson('/api/v1/treasury/settings', ['pick_settlement_accounts' => true], $headers);

        // Assert
        $saved->assertOk()->assertJsonPath('data.pick_settlement_accounts', true);
        $this->getJson('/api/v1/treasury/settings', $headers)->assertJsonPath('data.pick_settlement_accounts', true);
    }

    public function test_a_pick_sent_while_the_switch_is_off_is_refused_and_moves_nothing(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $order = $this->order('100.00');
        $this->pay($headers, $order, '100', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $response = $this->settle($headers, $order, ['settlement_cash_account_id' => $misrata->id]);

        // Assert — a box the screen did not offer is not an answer
        $response->assertUnprocessable()->assertJsonValidationErrors('fields');
        $this->assertSame('0.00', $this->balance($misrata));
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    // ── the boxes ───────────────────────────────────────────────────────────────────────

    public function test_one_required_box_per_kind_the_order_holds_listing_only_that_kind(): void
    {
        // Arrange — cash and a transfer; no ليبيانا
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $omarsBank = $this->account(AccountKind::Bank, 'مصرف عمر');
        $this->account(AccountKind::Cash, 'كاش قديم', null, ['is_active' => false]);
        $order = $this->order('500.00');
        $this->pay($headers, $order, '200', $misrata)->assertCreated();
        $this->pay($headers, $order, '300', $omarsBank)->assertCreated();

        // Act
        $fields = collect($this->settleFields($headers, $order));

        // Assert
        $cash = $fields->firstWhere('key', 'settlement_cash_account_id');
        $bank = $fields->firstWhere('key', 'settlement_bank_account_id');
        $this->assertNull($fields->firstWhere('key', 'settlement_wallet_account_id'));
        $this->assertTrue($cash['required']);
        $this->assertSame(['cash'], array_values(array_unique(array_column($cash['options'], 'kind'))));
        $this->assertSame(['bank'], array_values(array_unique(array_column($bank['options'], 'kind'))));
        $this->assertNotContains('كاش قديم', array_column($cash['options'], 'label'));
        // Opens on where the money already sits.
        $this->assertSame((string) $misrata->id, $cash['value']);
        $this->assertSame((string) $omarsBank->id, $bank['value']);
        $this->assertStringContainsString('كاش مصراتة 200', $cash['hint']);
        $this->assertNull($fields->firstWhere('key', 'settler_plan'));
    }

    public function test_the_box_opens_on_the_collecting_account_when_collection_is_on(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true, 'collect_cash' => true]);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $order = $this->order('100.00');
        $this->pay($headers, $order, '100', $misrata)->assertCreated();

        // Act
        $cash = collect($this->settleFields($headers, $order))->firstWhere('key', 'settlement_cash_account_id');

        // Assert
        $this->assertSame((string) $this->defaultOf(AccountKind::Cash)->id, $cash['value']);
    }

    // ── what moves ──────────────────────────────────────────────────────────────────────

    public function test_each_kind_goes_to_the_account_picked_for_it(): void
    {
        // Arrange — cash in two boxes, a transfer in Omar's bank
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $safe = $this->account(AccountKind::Cash, 'الخزنة');
        $omarsBank = $this->account(AccountKind::Bank, 'مصرف عمر');
        $companyBank = $this->account(AccountKind::Bank, 'مصرف الشركة');
        $order = $this->order('600.00');
        $this->pay($headers, $order, '200', $misrata)->assertCreated();
        $this->pay($headers, $order, '100', $this->defaultOf(AccountKind::Cash))->assertCreated();
        $this->pay($headers, $order, '300', $omarsBank)->assertCreated();

        // Act
        $this->settle($headers, $order, [
            'settlement_cash_account_id' => $safe->id,
            'settlement_bank_account_id' => $companyBank->id,
        ])->assertOk();

        // Assert — both boxes' cash into the safe, the transfer into the company's bank
        $this->assertSame('300.00', $this->balance($safe));
        $this->assertSame('0.00', $this->balance($misrata));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('300.00', $this->balance($companyBank));
        $this->assertSame('0.00', $this->balance($omarsBank));
        $this->assertSame(
            "الطلبية {$order->code} إلى الحساب المختار",
            TreasuryOperation::query()->where('type', OperationType::Settlement->value)->first()->notes,
        );
    }

    public function test_leaving_the_box_on_where_the_money_sits_moves_nothing(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $order = $this->order('100.00');
        $this->pay($headers, $order, '100', $misrata)->assertCreated();

        // Act
        $this->settle($headers, $order, ['settlement_cash_account_id' => $misrata->id])->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($misrata));
        $this->assertSame(0, TreasuryOperation::query()->where('type', OperationType::Settlement->value)->count());
    }

    public function test_an_account_marked_not_collected_still_gives_its_money_to_the_pick(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $float = $this->account(AccountKind::Cash, 'كاش بنغازي', null, ['is_collected' => false]);
        $safe = $this->account(AccountKind::Cash, 'الخزنة');
        $order = $this->order('80.00');
        $this->pay($headers, $order, '80', $float)->assertCreated();

        // Act
        $this->settle($headers, $order, ['settlement_cash_account_id' => $safe->id])->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($float));
        $this->assertSame('80.00', $this->balance($safe));
    }

    public function test_the_pick_wins_over_the_settlers_own_account(): void
    {
        // Arrange — «التسوية إلى حساب المسوّي» on too; the box opens on Ali's, he picks the safe
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true, 'settle_into_settler' => true]);
        $alisCash = $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $safe = $this->account(AccountKind::Cash, 'الخزنة');
        $order = $this->order('150.00');
        $this->pay($headers, $order, '150', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $cash = collect($this->settleFields($headers, $order))->firstWhere('key', 'settlement_cash_account_id');
        $this->settle($headers, $order, ['settlement_cash_account_id' => $safe->id])->assertOk();

        // Assert
        $this->assertSame((string) $alisCash->id, $cash['value']);
        $this->assertSame('150.00', $this->balance($safe));
        $this->assertSame('0.00', $this->balance($alisCash));
    }

    // ── refused ─────────────────────────────────────────────────────────────────────────

    public function test_an_account_of_another_kind_is_refused_and_nothing_moves(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $companyBank = $this->account(AccountKind::Bank, 'مصرف الشركة');
        $order = $this->order('100.00');
        $this->pay($headers, $order, '100', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $response = $this->settle($headers, $order, ['settlement_cash_account_id' => $companyBank->id]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('fields.settlement_cash_account_id');
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);
    }

    public function test_a_kind_left_unanswered_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $order = $this->order('100.00');
        $this->pay($headers, $order, '100', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $response = $this->settle($headers, $order);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('fields.settlement_cash_account_id');
    }

    // ── custody ─────────────────────────────────────────────────────────────────────────

    public function test_nawris_money_is_asked_under_bank_and_lands_in_the_pick_in_one_step(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $companyBank = $this->account(AccountKind::Bank, 'مصرف الشركة');
        $order = $this->deliveredByNawris('100.00');

        // Act
        $fields = collect($this->settleFields($headers, $order));
        $this->settle($headers, $order, ['settlement_bank_account_id' => $companyBank->id])->assertOk();

        // Assert — no «استُلم المال في»; the bank box opens on the default bank Nawris pays into
        $this->assertNull($fields->firstWhere('key', 'settlement_account_id'));
        $this->assertSame((string) $this->defaultOf(AccountKind::Bank)->id, $fields->firstWhere('key', 'settlement_bank_account_id')['value']);
        $this->assertSame('100.00', $this->balance($companyBank));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(1, TreasuryOperation::query()->count());
    }

    // ── the customer's wallet ───────────────────────────────────────────────────────────

    public function test_what_was_paid_from_the_customers_wallet_is_not_asked_and_does_not_move(): void
    {
        // Arrange — 100 topped up in cash before the order, 60 of it spent on the order, 40 at the counter
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $safe = $this->account(AccountKind::Cash, 'الخزنة');
        $order = $this->order('100.00');
        $this->withHeaders($headers)->postJson("/api/v1/customers/{$order->customer_id}/wallet/top-ups", [
            'amount' => '100', 'method' => 'cash',
        ])->assertCreated();
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/from-wallet", [
            'amount' => '60',
        ])->assertCreated();
        $this->pay($headers, $order, '40', $this->defaultOf(AccountKind::Cash))->assertCreated();
        $payable = app(TreasuryService::class)->customerWalletsPayable();
        $owedBefore = $this->balance($payable);

        // Act
        $fields = collect($this->settleFields($headers, $order));
        $this->settle($headers, $order, ['settlement_cash_account_id' => $safe->id])->assertOk();

        // Assert — the cash box asks about the counter's 40 alone; the top-up's 100 is no order's
        $this->assertStringContainsString(' 40', $fields->firstWhere('key', 'settlement_cash_account_id')['hint']);
        $this->assertNull($fields->firstWhere('key', 'settlement_wallet_account_id'));
        $this->assertSame('40.00', $this->balance($safe));
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame($owedBefore, $this->balance($payable));
    }

    // ── undoing ─────────────────────────────────────────────────────────────────────────

    public function test_unsettling_hands_each_share_back_where_it_landed(): void
    {
        // Arrange
        [, $headers] = $this->staff();
        $this->set($headers, ['pick_settlement_accounts' => true]);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $safe = $this->account(AccountKind::Cash, 'الخزنة');
        $order = $this->order('300.00');
        $this->pay($headers, $order, '200', $misrata)->assertCreated();
        $this->pay($headers, $order, '100', $this->defaultOf(AccountKind::Cash))->assertCreated();
        $this->settle($headers, $order, ['settlement_cash_account_id' => $safe->id])->assertOk();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/unsettle", [
            'reason' => 'خطأ في التسوية',
        ])->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($safe));
        $this->assertSame('200.00', $this->balance($misrata));
        $this->assertSame('100.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }
}
