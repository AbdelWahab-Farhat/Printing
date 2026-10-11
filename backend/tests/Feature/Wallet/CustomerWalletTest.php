<?php

declare(strict_types=1);

namespace Tests\Feature\Wallet;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «محفظة الزبون» — Docs/payments/CUSTOMER-WALLET.md.
 *
 * **What the suite holds the feature to**: one wallet per customer, topped up and spent on orders
 * and never paid out; every wallet move mirrored on «أرصدة محافظ الزبائن» so the payable is always
 * minus the wallets (`wallets:check`); a wallet never below zero; money paid from the wallet goes
 * back only to the wallet; and «انتظار العربون» moves on by itself when the wallet pays the عربون.
 */
class CustomerWalletTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake('local');
    }

    // ── helpers ─────────────────────────────────────────────────────────────────────────

    /**
     * @param  list<PermissionName>  $permissions
     * @return array<string, string>
     */
    private function auth(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @return array<string, string> */
    private function cashier(): array
    {
        return $this->auth([
            PermissionName::ViewCustomerWallets,
            PermissionName::TopUpCustomerWallets,
            PermissionName::AdjustCustomerWallets,
            PermissionName::ReverseCustomerWalletEntries,
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
            PermissionName::SettleOrderPayments,
            PermissionName::MoveOrderToAwaitingDeposit,
        ]);
    }

    /** @return array<string, string> */
    private function customerHeaders(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    private function order(Customer $customer, string $total = '100.00', OrderStatus $status = OrderStatus::Ready): Order
    {
        return Order::factory()->create([
            'customer_id' => $customer->id,
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
            'status' => $status,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    private function topUp(array $headers, Customer $customer, array $payload = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/customers/{$customer->id}/wallet/top-ups", [
            'amount' => '100',
            'method' => 'cash',
            ...$payload,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function payFromWallet(array $headers, Order $order, ?string $amount = null): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/payments/from-wallet",
            $amount === null ? [] : ['amount' => $amount],
        );
    }

    private function balance(Customer $customer): string
    {
        return app(WalletService::class)->balanceOf((int) $customer->id);
    }

    private function accountBalance(TreasuryAccount $account): string
    {
        return app(TreasuryService::class)->balanceOf($account);
    }

    private function walletsPayable(): TreasuryAccount
    {
        return app(TreasuryService::class)->customerWalletsPayable();
    }

    private function defaultCash(): TreasuryAccount
    {
        return TreasuryAccount::query()->where('kind', AccountKind::Cash->value)->where('is_default', true)->firstOrFail();
    }

    // ── top-up ──────────────────────────────────────────────────────────────────────────

    public function test_a_cash_top_up_fills_the_wallet_the_drawer_and_the_debt(): void
    {
        $customer = Customer::factory()->create();
        $cash = $this->defaultCash();

        $this->topUp($this->cashier(), $customer, ['amount' => '150'])
            ->assertCreated()
            ->assertJsonPath('data.entry.type', WalletEntryType::Topup->value)
            ->assertJsonPath('data.entry.direction', 'in')
            ->assertJsonPath('data.balance', '150.00');

        $this->assertSame('150.00', $this->balance($customer));
        $this->assertSame('150.00', $this->accountBalance($cash));
        $this->assertSame('-150.00', $this->accountBalance($this->walletsPayable()));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_top_up_by_transfer_needs_its_receipt(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();

        $this->topUp($headers, $customer, ['method' => 'bank_transfer'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('receipt');

        $this->topUp($headers, $customer, [
            'method' => 'bank_transfer',
            'receipt' => UploadedFile::fake()->create('waseel.pdf', 20, 'application/pdf'),
        ])->assertCreated()->assertJsonPath('data.entry.has_receipt', true);
    }

    public function test_a_wallet_cannot_be_topped_up_by_wallet(): void
    {
        $this->topUp($this->cashier(), Customer::factory()->create(), ['method' => 'wallet'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('method');
    }

    public function test_topping_up_needs_its_own_grant(): void
    {
        $headers = $this->auth([PermissionName::ViewCustomerWallets]);

        $this->topUp($headers, Customer::factory()->create())->assertForbidden();
    }

    public function test_the_wallet_payable_takes_no_hand_operation(): void
    {
        $payable = $this->walletsPayable();
        $headers = $this->auth([PermissionName::RecordTreasuryOperations, PermissionName::ViewTreasury]);

        $this->withHeaders($headers)->postJson('/api/v1/treasury/operations', [
            'type' => 'transfer',
            'amount' => '10',
            'from_account_id' => $this->defaultCash()->id,
            'to_account_id' => $payable->id,
        ])->assertUnprocessable();
    }

    // ── paying an order ─────────────────────────────────────────────────────────────────

    public function test_an_order_paid_from_the_wallet_moves_no_cash(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer, ['amount' => '100'])->assertCreated();
        $order = $this->order($customer, '80.00');

        $response = $this->payFromWallet($headers, $order, '80')
            ->assertCreated()
            ->assertJsonPath('data.payment.method', PaymentMethod::Wallet->value)
            ->assertJsonPath('data.payment.requires_review', false)
            ->assertJsonPath('data.payment.can_settle', false)
            ->assertJsonPath('data.summary.paid_amount', '80.00')
            ->assertJsonPath('data.summary.wallet_balance', '20.00');

        $this->assertSame('20.00', $this->balance($customer));
        $this->assertSame('100.00', $this->accountBalance($this->defaultCash()));
        $this->assertSame('-20.00', $this->accountBalance($this->walletsPayable()));

        $entry = CustomerWalletEntry::query()->where('type', WalletEntryType::OrderPayment->value)->firstOrFail();
        $this->assertSame((int) $response->json('data.payment.id'), (int) $entry->order_payment_id);
        $this->assertSame((int) $order->id, (int) $entry->order_id);
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_with_no_amount_the_wallet_pays_what_it_can(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer, ['amount' => '30'])->assertCreated();

        $this->payFromWallet($headers, $this->order($customer, '80.00'))
            ->assertCreated()
            ->assertJsonPath('data.payment.amount', '30.00');

        $this->assertSame('0.00', $this->balance($customer));

        // And on an order owing less than the wallet holds, only the debt.
        $this->topUp($headers, $customer, ['amount' => '100'])->assertCreated();
        $this->payFromWallet($headers, $this->order($customer, '25.00'))
            ->assertCreated()
            ->assertJsonPath('data.payment.amount', '25.00');

        $this->assertSame('75.00', $this->balance($customer));
    }

    public function test_the_wallet_never_pays_beyond_its_balance_or_the_debt(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer, ['amount' => '50'])->assertCreated();

        $this->payFromWallet($headers, $this->order($customer, '80.00'), '60')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('amount');

        $this->topUp($headers, $customer, ['amount' => '100'])->assertCreated();

        $this->payFromWallet($headers, $this->order($customer, '80.00'), '90')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('amount');

        $this->assertSame('150.00', $this->balance($customer));
        $this->assertSame(0, OrderPayment::query()->count());
    }

    public function test_a_retry_with_the_same_key_pays_nothing_and_answers_with_the_first_payment(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer, ['amount' => '100'])->assertCreated();
        $order = $this->order($customer, '80.00');
        $key = '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d';

        $first = $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/payments/from-wallet",
            ['amount' => '30', 'client_token' => $key],
        )->assertCreated();

        // The connection dropped; the app sends the very same request again.
        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/payments/from-wallet",
            ['amount' => '30', 'client_token' => $key],
        )->assertOk()
            ->assertJsonPath('message', 'هذه الدفعة مسجَّلة من قبل')
            ->assertJsonPath('data.payment.id', $first->json('data.payment.id'));

        $this->assertSame(1, OrderPayment::query()->count());
        $this->assertSame('70.00', $this->balance($customer));
        $this->artisan('wallets:check')->assertSuccessful();

        // A new key is a new payment.
        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/payments/from-wallet",
            ['amount' => '30', 'client_token' => '9a8b7c6d-5e4f-4a3b-8c1d-0e9f8a7b6c5d'],
        )->assertCreated();

        $this->assertSame('40.00', $this->balance($customer));
    }

    public function test_a_key_spent_on_one_order_is_refused_on_another(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer, ['amount' => '100'])->assertCreated();
        $key = '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d';

        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$this->order($customer, '30.00')->id}/payments/from-wallet",
            ['client_token' => $key],
        )->assertCreated();

        $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$this->order($customer, '30.00')->id}/payments/from-wallet",
            ['client_token' => $key],
        )->assertUnprocessable()->assertJsonValidationErrors('client_token');

        $this->assertSame('70.00', $this->balance($customer));
    }

    public function test_the_customer_app_retry_is_answered_with_the_order_as_it_stands(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->topUp($this->cashier(), $customer, ['amount' => '120'])->assertCreated();
        $order = $this->order($customer, '90.00');
        $app = $this->customerHeaders($customer);
        $key = '3f2b1c4d-5e6f-4a1b-8c2d-9e0f1a2b3c4d';

        $this->withHeaders($app)
            ->postJson("/api/v1/client/orders/{$order->id}/pay-from-wallet", ['client_token' => $key])
            ->assertCreated();

        $this->withHeaders($app)
            ->postJson("/api/v1/client/orders/{$order->id}/pay-from-wallet", ['client_token' => $key])
            ->assertOk()
            ->assertJsonPath('data.balance', '30.00');

        $this->assertSame(1, OrderPayment::query()->count());
    }

    public function test_an_empty_wallet_is_refused_rather_than_paying_nothing(): void
    {
        $customer = Customer::factory()->create();

        $this->payFromWallet($this->cashier(), $this->order($customer))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('amount');
    }

    public function test_the_payment_form_refuses_the_wallet_method(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$this->order($customer)->id}/payments", [
            'amount' => '50',
            'method' => 'wallet',
        ])->assertUnprocessable()->assertJsonValidationErrors('method');

        $this->assertSame('100.00', $this->balance($customer));
    }

    public function test_a_payment_from_the_wallet_is_not_waiting_to_be_settled(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $this->payFromWallet($headers, $this->order($customer, '60.00'), '60')->assertCreated();

        $this->withHeaders($headers)->getJson('/api/v1/order-payments/settlement-queue')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    // ── undoing ─────────────────────────────────────────────────────────────────────────

    public function test_reversing_a_payment_from_the_wallet_gives_the_money_back(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $order = $this->order($customer, '70.00');
        $paymentId = $this->payFromWallet($headers, $order, '70')->assertCreated()->json('data.payment.id');

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/{$paymentId}/reverse", [
            'reason' => 'خطأ',
        ])->assertCreated();

        $this->assertSame('100.00', $this->balance($customer));
        $this->assertSame('-100.00', $this->accountBalance($this->walletsPayable()));
        $this->assertSame('0.00', (string) $order->refresh()->paid_amount);
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_refund_into_the_wallet_credits_it(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $order = $this->order($customer, '70.00');
        $this->payFromWallet($headers, $order, '70')->assertCreated();

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '20',
            'method' => 'wallet',
        ])->assertCreated()->assertJsonPath('data.payment.requires_review', false);

        $this->assertSame('50.00', $this->balance($customer));
        $this->assertSame('-50.00', $this->accountBalance($this->walletsPayable()));
        $this->assertSame(
            1,
            CustomerWalletEntry::query()->where('type', WalletEntryType::OrderRefund->value)->count(),
        );
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_money_paid_from_the_wallet_is_never_refunded_in_cash(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $order = $this->order($customer, '100.00');
        $this->payFromWallet($headers, $order, '60')->assertCreated();
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments", [
            'amount' => '40',
            'method' => 'cash',
        ])->assertCreated();

        // 40 came in cash, so 40 may go back in cash — the 60 only to the wallet.
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '50',
            'method' => 'cash',
        ])->assertUnprocessable()->assertJsonValidationErrors('amount');

        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '40',
            'method' => 'cash',
        ])->assertCreated();
    }

    public function test_a_top_up_is_reversed_with_both_its_movements(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $entryId = $this->topUp($headers, $customer)->assertCreated()->json('data.entry.id');

        $this->withHeaders($headers)->postJson("/api/v1/wallet-entries/{$entryId}/reverse", ['reason' => 'خطأ'])
            ->assertCreated()
            ->assertJsonPath('data.entry.type', WalletEntryType::Reversal->value)
            ->assertJsonPath('data.entry.direction', 'out')
            ->assertJsonPath('data.balance', '0.00');

        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
        $this->assertSame('0.00', $this->accountBalance($this->walletsPayable()));

        $this->withHeaders($headers)->postJson("/api/v1/wallet-entries/{$entryId}/reverse", ['reason' => 'مرة ثانية'])
            ->assertUnprocessable();
    }

    public function test_a_spent_top_up_cannot_be_reversed(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $entryId = $this->topUp($headers, $customer)->assertCreated()->json('data.entry.id');
        $this->payFromWallet($headers, $this->order($customer, '70.00'), '70')->assertCreated();

        $this->withHeaders($headers)->postJson("/api/v1/wallet-entries/{$entryId}/reverse", ['reason' => 'خطأ'])
            ->assertUnprocessable();

        $this->assertSame('30.00', $this->balance($customer));
    }

    public function test_a_payment_from_the_wallet_is_undone_on_the_order_not_the_wallet(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $this->payFromWallet($headers, $this->order($customer, '70.00'), '70')->assertCreated();
        $entry = CustomerWalletEntry::query()->where('type', WalletEntryType::OrderPayment->value)->firstOrFail();

        $this->withHeaders($headers)->postJson("/api/v1/wallet-entries/{$entry->id}/reverse", ['reason' => 'خطأ'])
            ->assertUnprocessable();
    }

    // ── adjustments ─────────────────────────────────────────────────────────────────────

    public function test_an_adjustment_moves_the_debt_and_no_cash(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();

        $this->withHeaders($headers)->postJson("/api/v1/customers/{$customer->id}/wallet/adjustments", [
            'direction' => 'credit',
            'amount' => '25',
            'reason' => 'تعويض',
        ])->assertCreated()->assertJsonPath('data.balance', '25.00');

        $this->withHeaders($headers)->postJson("/api/v1/customers/{$customer->id}/wallet/adjustments", [
            'direction' => 'debit',
            'amount' => '30',
            'reason' => 'أكثر من الرصيد',
        ])->assertUnprocessable()->assertJsonValidationErrors('amount');

        $this->assertSame('0.00', $this->accountBalance($this->defaultCash()));
        $this->assertSame('-25.00', $this->accountBalance($this->walletsPayable()));
        $this->assertSame(1, TreasuryMovement::query()->where('kind', MovementKind::WalletAdjustment->value)->count());
        $this->artisan('wallets:check')->assertSuccessful();
    }

    // ── the deposit ─────────────────────────────────────────────────────────────────────

    public function test_paying_the_agreed_deposit_from_the_wallet_moves_the_order_on(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $order = $this->order($customer, '200.00', OrderStatus::AwaitingDeposit);
        $order->forceFill(['deposit_expected_amount' => '50.00'])->save();

        $paymentId = $this->payFromWallet($headers, $order, '50')->assertCreated()->json('data.payment.id');

        $order->refresh();
        $this->assertSame(OrderStatus::DepositPaid, $order->status);
        $this->assertSame((int) $paymentId, (int) $order->deposit_payment_id);
        $this->assertTrue((bool) $order->is_deposit_received);
        $this->assertNull($order->deposit_confirmed_by);
    }

    public function test_less_than_the_agreed_deposit_leaves_the_order_waiting(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $order = $this->order($customer, '200.00', OrderStatus::AwaitingDeposit);
        $order->forceFill(['deposit_expected_amount' => '50.00'])->save();

        $this->payFromWallet($headers, $order, '30')->assertCreated();

        $this->assertSame(OrderStatus::AwaitingDeposit, $order->refresh()->status);
    }

    public function test_walking_the_deposit_back_returns_the_money_to_the_wallet(): void
    {
        $customer = Customer::factory()->create();
        $headers = $this->cashier();
        $this->topUp($headers, $customer)->assertCreated();
        $order = $this->order($customer, '200.00', OrderStatus::AwaitingDeposit);
        $order->forceFill(['deposit_expected_amount' => '50.00'])->save();
        $this->payFromWallet($headers, $order, '50')->assertCreated();

        $this->withHeaders($headers)->post("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::AwaitingDeposit->value,
            'reason' => 'لم يصل',
            'fields' => ['deposit_amount' => '50', 'deposit_method' => PaymentMethod::Cash->value],
        ])->assertOk();

        $this->assertSame('100.00', $this->balance($customer));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    // ── the transactions page ───────────────────────────────────────────────────────────

    public function test_the_transactions_page_lists_every_wallet_and_finds_a_customer(): void
    {
        $headers = $this->cashier();
        $ali = Customer::factory()->create(['name' => 'علي المصراتي']);
        $omar = Customer::factory()->create(['name' => 'عمر الزاوي']);
        $this->topUp($headers, $ali)->assertCreated();
        $this->topUp($headers, $omar)->assertCreated();

        $this->withHeaders($headers)->getJson('/api/v1/wallet-entries')
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->withHeaders($headers)->getJson('/api/v1/wallet-entries?q=المصراتي')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.customer.name', 'علي المصراتي');

        $this->withHeaders($headers)->getJson("/api/v1/customers/{$ali->id}/wallet/entries")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('meta.balance', '100.00');
    }

    // ── the customer app ────────────────────────────────────────────────────────────────

    public function test_the_customer_sees_their_wallet_and_pays_from_it(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->topUp($this->cashier(), $customer, ['amount' => '120'])->assertCreated();
        $order = $this->order($customer, '90.00');
        $app = $this->customerHeaders($customer);

        $this->withHeaders($app)->getJson('/api/v1/client/wallet')
            ->assertOk()
            ->assertJsonPath('data.balance', '120.00');

        $this->withHeaders($app)->postJson("/api/v1/client/orders/{$order->id}/pay-from-wallet")
            ->assertCreated()
            ->assertJsonPath('data.balance', '30.00');

        $this->withHeaders($app)->getJson('/api/v1/client/wallet/entries')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.type', WalletEntryType::OrderPayment->value)
            ->assertJsonPath('data.0.direction', 'out')
            ->assertJsonMissingPath('data.0.notes')
            ->assertJsonPath('meta.balance', '30.00');

        $this->assertNull(OrderPayment::query()->firstOrFail()->recorded_by);
    }

    public function test_the_customer_cannot_pay_another_customers_order(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->topUp($this->cashier(), $customer)->assertCreated();
        $theirs = $this->order(Customer::factory()->create());

        $this->withHeaders($this->customerHeaders($customer))
            ->postJson("/api/v1/client/orders/{$theirs->id}/pay-from-wallet")
            ->assertNotFound();

        $this->assertSame('100.00', $this->balance($customer));
    }

    public function test_a_request_awaiting_review_cannot_be_paid_from_the_wallet(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->topUp($this->cashier(), $customer)->assertCreated();
        $request = $this->order($customer, '50.00', OrderStatus::Requested);

        $this->withHeaders($this->customerHeaders($customer))
            ->postJson("/api/v1/client/orders/{$request->id}/pay-from-wallet")
            ->assertUnprocessable();
    }

    public function test_an_adjustments_reason_is_not_shown_to_the_customer(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->withHeaders($this->cashier())->postJson("/api/v1/customers/{$customer->id}/wallet/adjustments", [
            'direction' => 'credit',
            'amount' => '10',
            'reason' => 'ملاحظة داخلية',
        ])->assertCreated();

        $this->withHeaders($this->customerHeaders($customer))->getJson('/api/v1/client/wallet/entries')
            ->assertOk()
            ->assertJsonPath('data.0.description', null);
    }
}
