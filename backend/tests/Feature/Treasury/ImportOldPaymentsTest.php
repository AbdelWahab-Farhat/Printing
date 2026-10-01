<?php

declare(strict_types=1);

namespace Tests\Feature\Treasury;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ReverseOrderPayment;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\DTOs\OperationData;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * `treasury:import-old-payments` — the payments from before the treasury, into its accounts on
 * their own dates. TREASURY-DESIGN §١٧.
 *
 * **Old rows are made the only way they ever existed: with no account.** The CHECK that forbids
 * that today is dropped inside each test's own transaction, which PostgreSQL rolls back with the
 * rest — so production's watermark is exactly what is being simulated.
 *
 * Arrange - Act - Assert throughout.
 */
class ImportOldPaymentsTest extends TestCase
{
    use RefreshDatabase;

    private User $carrier;

    protected function setUp(): void
    {
        parent::setUp();

        DB::statement('ALTER TABLE order_payments DROP CONSTRAINT order_payments_money_names_an_account');

        $this->carrier = User::factory()->create(['email' => 'nawris@carrier.local', 'is_active' => false]);
    }

    private function account(AccountKind $kind): TreasuryAccount
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

    private function oldPayment(
        Order $order,
        string $amount,
        PaymentMethod $method,
        string $paidAt,
        ?User $by = null,
        OrderPaymentType $type = OrderPaymentType::Payment,
    ): OrderPayment {
        return OrderPayment::factory()->forOrder($order)->create([
            'type' => $type,
            'amount' => $amount,
            'method' => $method,
            'paid_at' => $paidAt,
            'recorded_by' => ($by ?? User::factory()->create())->getKey(),
            'treasury_account_id' => null,
            'receipt_disk' => 'local',
            'receipt_path' => 'payment-receipts/old/receipt.pdf',
        ]);
    }

    public function test_a_dry_run_reports_and_writes_nothing(): void
    {
        // Arrange
        $order = Order::factory()->create(['grand_total' => '300.00']);
        $this->oldPayment($order, '100.00', PaymentMethod::Cash, '2026-08-28 10:00:00');
        $this->oldPayment($order, '200.00', PaymentMethod::BankTransfer, '2026-08-29 10:00:00');

        // Act
        $this->artisan('treasury:import-old-payments')
            ->expectsOutputToContain('تجربة')
            ->assertSuccessful();

        // Assert
        $this->assertSame(0, TreasuryMovement::query()->count());
        $this->assertSame(0, OrderPayment::query()->whereNotNull('treasury_account_id')->count());
    }

    public function test_apply_puts_each_old_payment_in_its_account_on_its_own_date(): void
    {
        // Arrange
        $order = Order::factory()->create(['grand_total' => '425.00']);
        $cash = $this->oldPayment($order, '100.00', PaymentMethod::Cash, '2026-08-28 10:00:00');
        $this->oldPayment($order, '200.00', PaymentMethod::BankTransfer, '2026-08-29 10:00:00');
        $this->oldPayment($order, '25.00', PaymentMethod::Libyana, '2026-08-30 10:00:00');
        $this->oldPayment($order, '100.00', PaymentMethod::Cash, '2026-09-08 10:00:00', $this->carrier);

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Assert
        $this->assertSame('100.00', $this->balance($this->account(AccountKind::Cash)));
        $this->assertSame('200.00', $this->balance($this->account(AccountKind::Bank)));
        $this->assertSame('25.00', $this->balance($this->account(AccountKind::Wallet)));
        $this->assertSame('100.00', $this->balance($this->nawris()));

        $this->assertSame((int) $this->account(AccountKind::Cash)->id, (int) $cash->refresh()->treasury_account_id);
        $movement = TreasuryMovement::query()->where('source_id', $cash->id)->sole();
        $this->assertSame('2026-08-28', $movement->occurred_at->toDateString());
        $this->assertSame((int) $order->id, (int) $movement->order_id);
    }

    public function test_a_second_run_writes_nothing(): void
    {
        // Arrange
        $order = Order::factory()->create(['grand_total' => '100.00']);
        $this->oldPayment($order, '100.00', PaymentMethod::Cash, '2026-08-28 10:00:00');
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Assert
        $this->assertSame(1, TreasuryMovement::query()->count());
        $this->assertSame('100.00', $this->balance($this->account(AccountKind::Cash)));
    }

    public function test_an_old_order_already_settled_moves_its_nawris_money_to_the_bank_on_the_settled_day(): void
    {
        // Arrange
        $order = Order::factory()->create([
            'status' => OrderStatus::Settled,
            'grand_total' => '150.00',
            'settled_at' => '2026-09-10 12:00:00',
        ]);
        $this->oldPayment($order, '150.00', PaymentMethod::Cash, '2026-09-08 10:00:00', $this->carrier);

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Assert
        $this->assertSame('0.00', $this->balance($this->nawris()));
        $this->assertSame('150.00', $this->balance($this->account(AccountKind::Bank)));

        $settlement = TreasuryOperation::query()->where('type', 'settlement')->sole();
        $this->assertSame('2026-09-10', $settlement->occurred_at->toDateString());
    }

    public function test_today_s_switches_do_not_redirect_an_old_settlement(): void
    {
        // Arrange — «تُسوّى إلى» على النورس، والتجميعُ في «مصرف ٢» مفعّل: مفاتيحُ اليوم، والمالُ
        // القديم سُجِّل في الافتراضيات (§١٧)
        $secondBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف ٢']);
        $thirdBank = TreasuryAccount::factory()->kind(AccountKind::Bank)->create(['name' => 'مصرف ٣']);
        $this->nawris()->forceFill(['settles_into_account_id' => $thirdBank->id])->save();
        TreasurySetting::current()
            ->forceFill(['collect_bank' => true, 'collect_bank_into_id' => $secondBank->id])
            ->save();
        $order = Order::factory()->create([
            'status' => OrderStatus::Settled,
            'grand_total' => '150.00',
            'settled_at' => '2026-09-10 12:00:00',
        ]);
        $this->oldPayment($order, '150.00', PaymentMethod::Cash, '2026-09-08 10:00:00', $this->carrier);

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Assert — في المصرف الافتراضي، لا حيث تقول مفاتيحُ اليوم
        $this->assertSame('150.00', $this->balance($this->account(AccountKind::Bank)));
        $this->assertSame('0.00', $this->balance($secondBank));
        $this->assertSame('0.00', $this->balance($thirdBank));
    }

    public function test_an_old_refund_and_an_old_reversal_leave_the_account_again(): void
    {
        // Arrange
        $order = Order::factory()->create(['grand_total' => '500.00']);
        $typo = $this->oldPayment($order, '500.00', PaymentMethod::Cash, '2026-08-28 10:00:00');
        $reversal = OrderPayment::factory()->forOrder($order)->create([
            'type' => OrderPaymentType::Reversal,
            'amount' => '500.00',
            'method' => null,
            'paid_at' => '2026-08-28 11:00:00',
            'reverses_payment_id' => $typo->id,
            'treasury_account_id' => null,
        ]);
        $this->oldPayment($order, '50.00', PaymentMethod::Cash, '2026-08-29 10:00:00');
        $this->oldPayment($order, '20.00', PaymentMethod::Cash, '2026-08-30 10:00:00', type: OrderPaymentType::Refund);

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Assert — 500 in and out, 50 in, 20 back out
        $this->assertSame('30.00', $this->balance($this->account(AccountKind::Cash)));
        $this->assertNotNull($reversal);
    }

    public function test_a_payment_reversed_after_go_live_is_not_mirrored_twice(): void
    {
        // Arrange — the treasury already wrote the reversal's mirror, onto the cash default.
        $order = Order::factory()->create(['grand_total' => '80.00']);
        $old = $this->oldPayment($order, '80.00', PaymentMethod::Cash, '2026-08-28 10:00:00');
        app(ReverseOrderPayment::class)($order, $old, 'مكرر', User::factory()->create());
        $this->assertSame('-80.00', $this->balance($this->account(AccountKind::Cash)));

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])->assertSuccessful();

        // Assert — the payment goes in where its reversal came out, and the pair cancels
        $this->assertSame('0.00', $this->balance($this->account(AccountKind::Cash)));
        $this->assertSame(2, TreasuryMovement::query()->count());
    }

    public function test_it_refuses_once_any_account_has_its_opening_balance(): void
    {
        // Arrange
        $order = Order::factory()->create(['grand_total' => '100.00']);
        $this->oldPayment($order, '100.00', PaymentMethod::Cash, '2026-08-28 10:00:00');
        app(TreasuryService::class)->recordOperation(
            OperationData::fromArray([
                'type' => 'opening',
                'to_account_id' => $this->account(AccountKind::Cash)->id,
                'amount' => '8450',
            ]),
            null,
        );

        // Act
        $this->artisan('treasury:import-old-payments', ['--apply' => true])
            ->expectsOutputToContain('رصيد افتتاحي')
            ->assertFailed();

        // Assert — only the opening itself moved anything
        $this->assertSame(1, TreasuryMovement::query()->count());
        $this->assertNull(OrderPayment::query()->whereNotNull('treasury_account_id')->where('type', 'payment')->value('id'));
    }
}
