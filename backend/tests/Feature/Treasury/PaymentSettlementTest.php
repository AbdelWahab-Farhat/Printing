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
use App\Domain\Treasury\Models\ExpenseCategory;
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
 * «تسوية دفعة» — one payment's money carried to the account it reached, before the order is
 * settled, and taken back. TREASURY-DESIGN §٢٣.
 *
 * Arrange - Act - Assert throughout.
 */
class PaymentSettlementTest extends TestCase
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
     * @param  list<PermissionName>  $without
     * @return array{0: User, 1: array<string, string>}
     */
    private function owner(array $without = []): array
    {
        $user = User::factory()->create();
        $granted = array_filter([
            PermissionName::ViewTreasury,
            PermissionName::RecordTreasuryOperations,
            PermissionName::ManageTreasury,
            PermissionName::ViewOrders,
            PermissionName::SettleOrders,
            PermissionName::UnsettleOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::SettleOrderPayments,
        ], fn (PermissionName $p) => ! in_array($p, $without, true));
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, array_values($granted)));

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

    private function bank(string $name): TreasuryAccount
    {
        return TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => $name]);
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
    private function pay(array $headers, Order $order, string $amount, TreasuryAccount $into): OrderPayment
    {
        $body = ['amount' => $amount, 'method' => 'cash', 'treasury_account_id' => $into->id];

        if ($into->kind === AccountKind::Bank) {
            $body['method'] = 'bank_transfer';
            $body['receipt'] = UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf');
        }

        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/payments", $body)->assertCreated();

        return OrderPayment::query()->where('order_id', $order->id)->latest('id')->firstOrFail();
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

    private function paymentOf(Order $order): OrderPayment
    {
        return OrderPayment::query()->where('order_id', $order->id)->sole();
    }

    /**
     * @param  array<string, string>  $headers
     * @param  list<array<string, mixed>>  $rows
     */
    private function settle(array $headers, array $rows, ?TreasuryAccount $into = null): TestResponse
    {
        return $this->postJson('/api/v1/order-payments/settle', array_filter([
            'payments' => $rows,
            'account_id' => $into?->id,
        ], fn ($v) => $v !== null), $headers);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function unsettle(array $headers, OrderPayment $payment, string $reason = 'سُوّيت إلى الحساب الخطأ'): TestResponse
    {
        return $this->postJson("/api/v1/orders/{$payment->order_id}/payments/{$payment->id}/unsettle", ['reason' => $reason], $headers);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function settleOrder(array $headers, Order $order): TestResponse
    {
        return $this->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
            'fields' => [],
        ], $headers);
    }

    // ── settling ────────────────────────────────────────────────────────────────────────

    public function test_a_nawris_payment_goes_to_the_bank_without_touching_the_order(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);

        // Act
        $response = $this->settle($headers, [['payment_id' => $payment->id]]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.payments.0.settlement.to_account.id', $this->defaultOf(AccountKind::Bank)->id)
            ->assertJsonPath('data.payments.0.settlement.received', '250.00')
            ->assertJsonPath('data.payments.0.can_unsettle', true);
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame('250.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(OrderStatus::Delivered, $order->refresh()->status);

        $operation = TreasuryOperation::query()->sole();
        $this->assertSame(OperationType::Settlement, $operation->type);
        $this->assertSame($payment->id, (int) $operation->order_payment_id);
        $this->assertSame("تسوية دفعة الطلبية {$order->code}", $operation->notes);
    }

    public function test_settling_the_order_afterwards_finds_nothing_more_to_carry(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $this->settle($headers, [['payment_id' => $this->paymentOf($order)->id]])->assertOk();

        // Act
        $this->settleOrder($headers, $order)->assertOk();

        // Assert — still one operation, and the bank was not paid twice
        $this->assertSame(1, TreasuryOperation::query()->count());
        $this->assertSame('250.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(OrderStatus::Settled, $order->refresh()->status);
    }

    public function test_the_order_settlement_carries_only_the_payment_left_behind(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->putJson('/api/v1/treasury/settings', ['collect_bank' => true], $headers)->assertOk();
        $alisBank = $this->bank('مصرف علي');
        $order = $this->order('500.00');
        $first = $this->pay($headers, $order, '300', $alisBank);
        $this->pay($headers, $order, '200', $alisBank);
        $this->settle($headers, [['payment_id' => $first->id]])->assertOk();

        // Act
        $this->settleOrder($headers, $order)->assertOk();

        // Assert
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('500.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $amounts = TreasuryOperation::query()->orderBy('id')->pluck('amount')->map(fn ($a) => (string) $a)->all();
        $this->assertSame(['300.00', '200.00'], $amounts);
    }

    public function test_what_the_carrier_kept_is_booked_as_its_fee(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');

        // Act
        $response = $this->settle($headers, [['payment_id' => $this->paymentOf($order)->id, 'fee' => '15']]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.payments.0.settlement.fee', '15.00')
            ->assertJsonPath('data.payments.0.settlement.received', '235.00');
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame('235.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertSame(
            ExpenseCategory::query()->where('code', ExpenseCategory::CARRIER_FEE)->value('id'),
            TreasuryOperation::query()->sole()->category_id,
        );
    }

    public function test_a_fee_is_refused_on_money_no_carrier_held(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $alisBank = $this->bank('مصرف علي');
        $order = $this->order('100.00');
        $payment = $this->pay($headers, $order, '100', $alisBank);

        // Act
        $response = $this->settle($headers, [['payment_id' => $payment->id, 'fee' => '5']], $this->defaultOf(AccountKind::Bank));

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['payments.0.fee']);
        $this->assertSame(0, TreasuryOperation::query()->count());
    }

    public function test_a_hand_picked_account_wins_over_the_automatic_one(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $libyana = $this->defaultOf(AccountKind::Wallet);

        // Act
        $this->settle($headers, [['payment_id' => $this->paymentOf($order)->id]], $libyana)->assertOk();

        // Assert
        $this->assertSame('250.00', $this->balance($libyana));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_a_payment_already_in_its_place_needs_an_account_named(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $bank = $this->defaultOf(AccountKind::Bank);
        $order = $this->order('100.00');
        $payment = $this->pay($headers, $order, '100', $bank);

        // Act
        $automatic = $this->settle($headers, [['payment_id' => $payment->id]]);
        $same = $this->settle($headers, [['payment_id' => $payment->id]], $bank);
        $custody = $this->settle($headers, [['payment_id' => $payment->id]], $this->nawris());

        // Assert
        $automatic->assertUnprocessable()->assertJsonValidationErrors(['account_id']);
        $same->assertUnprocessable()->assertJsonValidationErrors(['account_id']);
        $custody->assertUnprocessable()->assertJsonValidationErrors(['account_id']);
        $this->assertSame(0, TreasuryOperation::query()->count());
    }

    public function test_a_payment_is_settled_once(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);
        $this->settle($headers, [['payment_id' => $payment->id]])->assertOk();

        // Act
        $again = $this->settle($headers, [['payment_id' => $payment->id]], $this->defaultOf(AccountKind::Cash));

        // Assert
        $again->assertUnprocessable()->assertJsonValidationErrors(['payments.0.payment_id']);
        $this->assertSame(1, TreasuryOperation::query()->count());
    }

    public function test_a_payment_on_a_settled_order_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $this->settleOrder($headers, $order)->assertOk();

        // Act
        $response = $this->settle($headers, [['payment_id' => $this->paymentOf($order)->id]]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['payments.0.payment_id']);
    }

    public function test_one_refusal_takes_the_whole_batch_back(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $good = $this->deliveredByNawris('250.00');
        $settled = $this->deliveredByNawris('100.00');
        $this->settleOrder($headers, $settled)->assertOk();

        // Act
        $response = $this->settle($headers, [
            ['payment_id' => $this->paymentOf($good)->id],
            ['payment_id' => $this->paymentOf($settled)->id],
        ]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['payments.1.payment_id']);
        $this->assertSame(0, TreasuryOperation::query()->whereNotNull('order_payment_id')->count());
        $this->assertSame('250.00', $this->balance($this->nawris()));
    }

    public function test_several_payments_settle_together(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $first = $this->deliveredByNawris('250.00');
        $second = $this->deliveredByNawris('100.00');

        // Act
        $response = $this->settle($headers, [
            ['payment_id' => $this->paymentOf($first)->id, 'fee' => '10'],
            ['payment_id' => $this->paymentOf($second)->id, 'fee' => '10'],
        ]);

        // Assert — one operation each, so each can be undone alone
        $response->assertOk()->assertJsonCount(2, 'data.payments');
        $this->assertSame(2, TreasuryOperation::query()->count());
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame('330.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_settling_needs_the_grant(): void
    {
        // Arrange
        [, $headers] = $this->owner(without: [PermissionName::SettleOrderPayments]);
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);

        // Act
        $settle = $this->settle($headers, [['payment_id' => $payment->id]]);
        $queue = $this->getJson('/api/v1/order-payments/settlement-queue', $headers);
        $ledger = $this->getJson("/api/v1/orders/{$order->id}/payments", $headers);

        // Assert
        $settle->assertForbidden();
        $queue->assertForbidden();
        $ledger->assertOk()->assertJsonPath('data.payments.0.can_settle', false);
    }

    // ── undoing ─────────────────────────────────────────────────────────────────────────

    public function test_undoing_puts_the_money_back_where_it_landed(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);
        $this->settle($headers, [['payment_id' => $payment->id, 'fee' => '15']])->assertOk();

        // Act
        $response = $this->unsettle($headers, $payment);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.payment.settlement', null)
            ->assertJsonPath('data.payment.can_settle', true);
        $this->assertSame('250.00', $this->balance($this->nawris()));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $reversal = TreasuryOperation::query()->whereNotNull('reverses_operation_id')->sole();
        $this->assertSame('سُوّيت إلى الحساب الخطأ', $reversal->notes);
        $this->assertSame($payment->id, (int) $reversal->order_payment_id);
    }

    public function test_an_undone_payment_can_be_settled_again(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);
        $this->settle($headers, [['payment_id' => $payment->id]])->assertOk();
        $this->unsettle($headers, $payment)->assertOk();

        // Act
        $response = $this->settle($headers, [['payment_id' => $payment->id]], $this->defaultOf(AccountKind::Cash));

        // Assert
        $response->assertOk();
        $this->assertSame('250.00', $this->balance($this->defaultOf(AccountKind::Cash)));
        $this->assertSame('0.00', $this->balance($this->defaultOf(AccountKind::Bank)));
    }

    public function test_undoing_needs_a_reason_and_a_settled_payment(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);

        // Act
        $notSettled = $this->unsettle($headers, $payment);
        $this->settle($headers, [['payment_id' => $payment->id]])->assertOk();
        $noReason = $this->unsettle($headers, $payment, '');

        // Assert
        $notSettled->assertUnprocessable();
        $noReason->assertUnprocessable()->assertJsonValidationErrors(['reason']);
    }

    public function test_undoing_waits_for_the_order_to_be_unsettled_and_survives_it(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');
        $payment = $this->paymentOf($order);
        $this->settle($headers, [['payment_id' => $payment->id]])->assertOk();
        $this->settleOrder($headers, $order)->assertOk();

        // Act
        $refused = $this->unsettle($headers, $payment);
        $this->postJson("/api/v1/orders/{$order->id}/unsettle", ['reason' => 'خطأ'], $headers)->assertOk();
        $stillSettled = $this->getJson("/api/v1/orders/{$order->id}/payments", $headers);
        $undone = $this->unsettle($headers, $payment);

        // Assert — un-settling the order left the payment's settlement standing
        $refused->assertUnprocessable();
        $stillSettled->assertJsonPath('data.payments.0.settlement.to_account.id', $this->defaultOf(AccountKind::Bank)->id);
        $undone->assertOk();
        $this->assertSame('250.00', $this->balance($this->nawris()));
    }

    // ── reversing the payment ───────────────────────────────────────────────────────────

    public function test_reversing_a_payment_unwinds_its_own_settlement_and_no_other(): void
    {
        // Arrange — two payments in Ali's bank, each settled on its own
        [, $headers] = $this->owner();
        $this->putJson('/api/v1/treasury/settings', ['collect_bank' => true], $headers)->assertOk();
        $alisBank = $this->bank('مصرف علي');
        $order = $this->order('500.00');
        $first = $this->pay($headers, $order, '300', $alisBank);
        $second = $this->pay($headers, $order, '200', $alisBank);
        $this->settle($headers, [['payment_id' => $first->id], ['payment_id' => $second->id]])->assertOk();

        // Act
        $this->postJson("/api/v1/orders/{$order->id}/payments/{$first->id}/reverse", ['reason' => 'مكررة'], $headers)
            ->assertSuccessful();

        // Assert
        $this->assertSame('0.00', $this->balance($alisBank));
        $this->assertSame('200.00', $this->balance($this->defaultOf(AccountKind::Bank)));
        $this->assertFalse($first->refresh()->isSettled());
        $this->assertTrue($second->refresh()->isSettled());
    }

    // ── the list ────────────────────────────────────────────────────────────────────────

    public function test_the_list_holds_what_waits_and_what_was_settled_apart(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $waiting = $this->deliveredByNawris('250.00');
        $done = $this->deliveredByNawris('100.00');
        $inPlace = $this->order('80.00');
        $this->pay($headers, $inPlace, '80', $this->defaultOf(AccountKind::Bank));
        $closed = $this->deliveredByNawris('60.00');
        $this->settleOrder($headers, $closed)->assertOk();
        $this->settle($headers, [['payment_id' => $this->paymentOf($done)->id]])->assertOk();

        // Act
        $pending = $this->getJson('/api/v1/order-payments/settlement-queue', $headers);
        $settled = $this->getJson('/api/v1/order-payments/settlement-queue?state=settled', $headers);

        // Assert
        $pending->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $this->paymentOf($waiting)->id)
            ->assertJsonPath('data.0.order.code', $waiting->code)
            ->assertJsonPath('data.0.can_settle', true)
            ->assertJsonPath('data.0.settlement_target.id', $this->defaultOf(AccountKind::Bank)->id)
            ->assertJsonPath('meta.amount_total', '250.00')
            ->assertJsonPath('meta.total', 1);
        $settled->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $this->paymentOf($done)->id)
            ->assertJsonPath('meta.amount_total', '100.00');
    }

    public function test_the_dates_filter_when_paid_while_waiting_and_when_settled_once_settled(): void
    {
        // Arrange — paid on the 1st, settled on the 5th
        [, $headers] = $this->owner();
        $this->travelTo('2026-10-01 10:00:00');
        $old = $this->deliveredByNawris('250.00');
        $this->travelTo('2026-10-05 10:00:00');
        $this->deliveredByNawris('100.00');
        $this->settle($headers, [['payment_id' => $this->paymentOf($old)->id]])->assertOk();

        // Act
        $pendingOnThe5th = $this->getJson('/api/v1/order-payments/settlement-queue?from=2026-10-05&to=2026-10-05', $headers);
        $settledOnThe5th = $this->getJson('/api/v1/order-payments/settlement-queue?state=settled&from=2026-10-05&to=2026-10-05', $headers);
        $settledOnThe1st = $this->getJson('/api/v1/order-payments/settlement-queue?state=settled&from=2026-10-01&to=2026-10-01', $headers);

        // Assert
        $pendingOnThe5th->assertJsonPath('meta.amount_total', '100.00');
        $settledOnThe5th->assertJsonPath('meta.amount_total', '250.00');
        $settledOnThe1st->assertJsonCount(0, 'data');
    }

    public function test_the_list_filters_by_account_and_order_code(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->putJson('/api/v1/treasury/settings', ['collect_bank' => true], $headers)->assertOk();
        $alisBank = $this->bank('مصرف علي');
        $byNawris = $this->deliveredByNawris('250.00');
        $byAli = $this->order('90.00');
        $this->pay($headers, $byAli, '90', $alisBank);

        // Act
        $ali = $this->getJson("/api/v1/order-payments/settlement-queue?account_id={$alisBank->id}", $headers);
        $code = $this->getJson('/api/v1/order-payments/settlement-queue?q='.urlencode((string) $byNawris->code), $headers);

        // Assert
        $ali->assertJsonCount(1, 'data')->assertJsonPath('data.0.order_id', $byAli->id);
        $code->assertJsonCount(1, 'data')->assertJsonPath('data.0.order_id', $byNawris->id);
    }

    public function test_the_accounts_name_where_money_waits_and_where_it_may_go(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $this->putJson('/api/v1/treasury/settings', ['collect_bank' => true], $headers)->assertOk();
        $alisBank = $this->bank('مصرف علي');

        // Act
        $response = $this->getJson('/api/v1/order-payments/settlement-accounts', $headers);

        // Assert — Nawris waits; the default bank is where the bank's money goes, so it does not
        $response->assertOk();
        $sources = collect($response->json('data.sources'))->pluck('id');
        $destinations = collect($response->json('data.destinations'))->pluck('id');
        $this->assertContains($this->nawris()->id, $sources);
        $this->assertContains($alisBank->id, $sources);
        $this->assertNotContains($this->defaultOf(AccountKind::Bank)->id, $sources);
        $this->assertContains($this->defaultOf(AccountKind::Bank)->id, $destinations);
        $this->assertNotContains($this->nawris()->id, $destinations);
    }

    public function test_the_movements_carry_the_order_so_the_ledger_reads_them(): void
    {
        // Arrange
        [, $headers] = $this->owner();
        $order = $this->deliveredByNawris('250.00');

        // Act
        $this->settle($headers, [['payment_id' => $this->paymentOf($order)->id]])->assertOk();

        // Assert
        $this->assertSame(
            2,
            TreasuryMovement::query()->where('order_id', $order->id)->where('kind', 'settlement')->count(),
        );
    }
}
