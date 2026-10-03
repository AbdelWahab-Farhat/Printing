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
 * «التسوية إلى حساب المسوّي» — at «تم التسوية», each kind of the order's money goes to the
 * settler's own account of that kind; a kind they hold none of follows collection, or stays.
 * TREASURY-DESIGN §٢٢.
 *
 * Arrange - Act - Assert throughout.
 */
class SettleIntoSettlerTest extends TestCase
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

    public function test_it_starts_off_and_settling_leaves_the_money_where_it_landed(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $alisCash = $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $order = $this->order('200.00');
        $this->pay($headers, $order, '200', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $settings = $this->getJson('/api/v1/treasury/settings', $headers);
        $this->settle($headers, $order)->assertOk();

        // Assert
        $settings->assertJsonPath('data.settle_into_settler', false);
        $this->assertSame('0.00', $this->balance($alisCash));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Cash)));
    }

    public function test_the_switch_is_saved_and_read_back(): void
    {
        // Arrange
        [, $headers] = $this->staff();

        // Act
        $saved = $this->putJson('/api/v1/treasury/settings', ['settle_into_settler' => true], $headers);

        // Assert
        $saved->assertOk()->assertJsonPath('data.settle_into_settler', true);
        $this->getJson('/api/v1/treasury/settings', $headers)->assertJsonPath('data.settle_into_settler', true);
    }

    // ── kind by kind ────────────────────────────────────────────────────────────────────

    public function test_cash_goes_to_the_settlers_cash_and_bank_money_to_the_settlers_bank(): void
    {
        // Arrange — the counter took cash, Omar's bank took a transfer
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $alisCash = $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $alisBank = $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $omarsBank = $this->account(AccountKind::Bank, 'مصرف عمر');
        $order = $this->order('500.00');
        $this->pay($headers, $order, '200', $this->defaultOf(AccountKind::Cash))->assertCreated();
        $this->pay($headers, $order, '300', $omarsBank)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert — never mixed: the cash is in a cash account, the transfer in a bank
        $this->assertSame('200.00', $this->balance($alisCash));
        $this->assertSame('300.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('0.00', $this->balance($omarsBank));
        $this->assertSame(
            "الطلبية {$order->code} إلى حساب المسوّي",
            TreasuryOperation::query()->where('type', OperationType::Settlement->value)->first()->notes,
        );
    }

    public function test_a_kind_the_settler_has_no_account_of_follows_collection(): void
    {
        // Arrange — Ali holds a bank only; cash is collected into the default box
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true, 'collect_cash' => true]);
        $alisBank = $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $order = $this->order('150.00');
        $this->pay($headers, $order, '150', $misrata)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($misrata));
        $this->assertSame('150.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('0.00', $this->balance($alisBank));
    }

    public function test_a_kind_with_no_account_of_the_settlers_and_no_collection_stays_put(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $misrata = $this->account(AccountKind::Cash, 'كاش مصراتة');
        $order = $this->order('150.00');
        $this->pay($headers, $order, '150', $misrata)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame('150.00', $this->balance($misrata));
        $this->assertSame(0, TreasuryOperation::query()->where('type', OperationType::Settlement->value)->count());
    }

    public function test_an_account_marked_not_collected_still_goes_to_the_settler(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $alisCash = $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $float = $this->account(AccountKind::Cash, 'كاش بنغازي', null, ['is_collected' => false]);
        $order = $this->order('80.00');
        $this->pay($headers, $order, '80', $float)->assertCreated();

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($float));
        $this->assertSame('80.00', $this->balance($alisCash));
    }

    public function test_nawris_money_lands_in_the_settlers_bank_in_one_step(): void
    {
        // Arrange — bank collection on too: the settler's account wins over it
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true, 'collect_bank' => true]);
        $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $alisBank = $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->settle($headers, $order)->assertOk();

        // Assert — Nawris → «مصرف علي», not via the default bank
        $this->assertSame('100.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(1, TreasuryOperation::query()->count());
    }

    public function test_an_account_picked_by_hand_on_the_settle_screen_still_wins(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $omarsBank = $this->account(AccountKind::Bank, 'مصرف عمر');
        $order = $this->deliveredByNawris('100.00');

        // Act
        $this->settle($headers, $order, ['settlement_account_id' => $omarsBank->id])->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($omarsBank));
    }

    // ── several accounts of a kind ──────────────────────────────────────────────────────

    public function test_with_two_banks_the_settler_must_say_which(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $this->account(AccountKind::Bank, 'مصرف علي الأول', $ali);
        $second = $this->account(AccountKind::Bank, 'مصرف علي الثاني', $ali);
        $order = $this->order('300.00');
        $this->pay($headers, $order, '300', $this->defaultOf(AccountKind::Bank))->assertCreated();

        // Act
        $fields = $this->settleFields($headers, $order);
        $unanswered = $this->settle($headers, $order);
        $answered = $this->settle($headers, $order, ['settler_bank_account_id' => $second->id]);

        // Assert — a required box offering his two banks and nothing else
        $box = collect($fields)->firstWhere('key', 'settler_bank_account_id');
        $this->assertTrue($box['required']);
        $this->assertSame(['مصرف علي الأول', 'مصرف علي الثاني'], array_column($box['options'], 'label'));
        $unanswered->assertUnprocessable()->assertJsonValidationErrors('fields.settler_bank_account_id');
        $answered->assertOk();
        $this->assertSame('300.00', $this->balance($second));
    }

    public function test_somebody_elses_account_is_refused_in_the_box(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $this->account(AccountKind::Bank, 'مصرف علي الأول', $ali);
        $this->account(AccountKind::Bank, 'مصرف علي الثاني', $ali);
        $omarsBank = $this->account(AccountKind::Bank, 'مصرف عمر');
        $order = $this->order('300.00');
        $this->pay($headers, $order, '300', $this->defaultOf(AccountKind::Bank))->assertCreated();

        // Act
        $response = $this->settle($headers, $order, ['settler_bank_account_id' => $omarsBank->id]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('fields.settler_bank_account_id');
        $this->assertSame('300.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    // ── what the screen says ────────────────────────────────────────────────────────────

    public function test_the_settle_screen_says_where_each_kind_goes(): void
    {
        // Arrange — cash to his box, bank to his bank, ليبيانا he has no account of
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $order = $this->order('550.00');
        $this->pay($headers, $order, '200', $this->defaultOf(AccountKind::Cash))->assertCreated();
        $this->pay($headers, $order, '300', $this->defaultOf(AccountKind::Bank))->assertCreated();
        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments", [
            'amount' => '50', 'method' => 'libyana', 'treasury_account_id' => $this->defaultOf(AccountKind::Wallet)->id,
        ])->assertCreated();

        // Act
        $notice = collect($this->settleFields($headers, $order))->firstWhere('key', 'settler_plan');

        // Assert
        $this->assertSame('notice', $notice['type']);
        $this->assertStringContainsString('← «كاش علي»', $notice['hint']);
        $this->assertStringContainsString('← «مصرف علي»', $notice['hint']);
        $this->assertStringContainsString('يبقى مكانه، ليس لك حساب', $notice['hint']);
    }

    public function test_nothing_is_said_while_the_switch_is_off(): void
    {
        // Arrange
        [$ali, $headers] = $this->staff();
        $this->account(AccountKind::Cash, 'كاش علي', $ali);
        $order = $this->order('200.00');
        $this->pay($headers, $order, '200', $this->defaultOf(AccountKind::Cash))->assertCreated();

        // Act
        $fields = $this->settleFields($headers, $order);

        // Assert
        $this->assertNotContains('settler_plan', array_column($fields, 'key'));
    }

    // ── undoing ─────────────────────────────────────────────────────────────────────────

    public function test_unsettling_hands_the_money_back_and_then_omars_payment_reverses(): void
    {
        // Arrange — both bank payments went to Ali's bank at settlement, then it was undone
        [$ali, $headers] = $this->staff();
        $this->set($headers, ['settle_into_settler' => true]);
        $alisBank = $this->account(AccountKind::Bank, 'مصرف علي', $ali);
        $omarsBank = $this->account(AccountKind::Bank, 'مصرف عمر');
        $order = $this->order('500.00');
        $this->pay($headers, $order, '300', $omarsBank)->assertCreated();
        $this->pay($headers, $order, '200', $this->defaultOf(AccountKind::Bank))->assertCreated();
        $this->settle($headers, $order)->assertOk();
        $this->assertSame('500.00', $this->balance($alisBank));

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/unsettle", [
            'reason' => 'تحويلُ عمر لم يصل',
        ])->assertOk();
        $omarsPayment = OrderPayment::query()->where('order_id', $order->id)->where('treasury_account_id', $omarsBank->id)->sole();
        $reversed = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/{$omarsPayment->id}/reverse", [
            'reason' => 'التحويل لم يصل',
        ]);

        // Assert — every share went back where it landed, then Omar's 300 alone left
        $reversed->assertCreated();
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('0.00', $this->balance($omarsBank));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }
}
