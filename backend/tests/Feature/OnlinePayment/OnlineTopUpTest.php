<?php

declare(strict_types=1);

namespace Tests\Feature\OnlinePayment;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Models\GatewayWebhookEvent;
use App\Domain\OnlinePayment\Models\OnlinePaymentMethod;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\Models\TreasurySetting;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as HttpRequest;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * الشحن الإلكتروني عبر EzonePay — Docs/payments/CUSTOMER-WALLET.md §٥.
 *
 * **EzonePay is faked with the shapes its own documentation gives** (2026-10-11); what only a real
 * account can confirm is listed in the doc and checked by `ezone:smoke-test`.
 *
 * What the suite holds the feature to: off by default; the customer is credited exactly the net
 * they were quoted, once, whoever learns of the payment first (OTP, QR, webhook, recheck); a webhook
 * is signed and confirmed with EzonePay before anything is credited; a wrong OTP is not the end; a
 * different amount waits for a person; limits count pending attempts; «Ezone» holds what EzonePay
 * owes and its fee is an expense; «اشحن وادفع» pays the order; the payout moves «Ezone» to the bank.
 *
 * Arrange - Act - Assert throughout. Libyana at 2.5 %, fee on the customer: 100 in the wallet is
 * 100 ÷ 0.975 = 102.57 charged, and EzonePay keeps 2.56 of it.
 */
class OnlineTopUpTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'test-webhook-secret';

    /** What EzonePay answers about transaction 5001, set per test. */
    private array $transaction = [];

    /** How the next OTP answers: true, or EzonePay's refusal. */
    private bool $otpAccepted = true;

    /** EzonePay numbers each payment it starts; the first in a test is 5001. */
    private int $nextTransaction = 5001;

    /** What EzonePay lists as paid on card link 77. */
    private array $linkPayments = [];

    /** A quote EzonePay answers whatever is asked — null: worked out at 2.5 %. */
    private ?array $quote = null;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        config([
            'ezone_pay.enabled' => true,
            'ezone_pay.base_url' => 'https://ezone.test',
            'ezone_pay.email' => 'shop@example.com',
            'ezone_pay.password' => 'secret',
            'ezone_pay.shop_id' => 42,
            'ezone_pay.webhook_secret' => self::SECRET,
        ]);

        Cache::flush();

        $this->transaction = $this->paid(102.57, 2.56);

        Http::fake(function (HttpRequest $request) {
            $path = parse_url($request->url(), PHP_URL_PATH);

            return match (true) {
                $path === '/Auth/login' => Http::response(['accessToken' => 'token', 'refreshToken' => 'refresh', 'expiresIn' => 3600]),
                $path === '/LookUp/paymentMethods' => Http::response([
                    ['id' => 101, 'name' => 'Moamalat', 'minPayment' => null, 'maxPayment' => 5000],
                    ['id' => 102, 'name' => 'MobiCash', 'minPayment' => 10, 'maxPayment' => 1000],
                    ['id' => 111, 'name' => 'Libyana', 'minPayment' => null, 'maxPayment' => 500],
                    ['id' => 123, 'name' => 'OnePay QR', 'minPayment' => null, 'maxPayment' => 1000],
                ]),
                $path === '/online-payment/commission/quote' => Http::response($this->quote ?? $this->quoteFor($request->data())),
                str_ends_with((string) $path, '/initiate') => Http::response(['transactionId' => $this->nextTransaction++]),
                $path === '/online-payment/onepay-qr/scan' => Http::response(['isComplete' => true, 'transactionId' => $this->nextTransaction++]),
                $path === '/online-payment/complete' => $this->otpAccepted
                    ? Http::response(['details' => 'ok'])
                    : Http::response(['message' => 'رمز التحقق غير صحيح'], 400),
                $path === '/payment-link/new' => Http::response(['id' => 77, 'link' => 'https://pay.ezone.test/l/77']),
                $path === '/payment-link/77/transactions' => Http::response(['data' => $this->linkPayments]),
                // The documented address alone — the old `/payments/transactions/{id}` is a 404 here.
                preg_match('#^/payments/transactions/\d+/online$#', (string) $path) === 1 => Http::response($this->transaction),
                $path === '/Webhook/subscribe' => Http::response(['id' => 9, 'event' => 2, 'secretKey' => 'c2VjcmV0']),
                $path === '/Webhook/test-event/2' => Http::response(['message' => 'Webhook Event Sent Successfully!']),
                default => Http::response(['message' => 'unexpected '.$path], 404),
            };
        });
    }

    // ── helpers ─────────────────────────────────────────────────────────────────────────

    /**
     * A paid transaction exactly as the sandbox answered it (OnePay, 7252, 2026-10-11) — camelCase,
     * `comission` as EzonePay spells it, `status` 3 and its name in Arabic.
     *
     * @return array<string, mixed>
     */
    private function paid(float $amount, float $fee): array
    {
        return [
            'id' => 5001,
            'paymentMethodName' => 'ون باي - تجريبي',
            'amount' => $amount,
            'currency' => 'LYD',
            'comission' => $fee,
            'source' => 'diaya',
            'initiatedUtc' => '2026-10-11T22:30:28.3830000Z',
            'pendingUtc' => null,
            'paidUtc' => '2026-10-11T22:30:35.5630000Z',
            'failedUtc' => null,
            'cancelledUtc' => null,
            'status' => 3,
            'statusName' => 'تم الدفع',
        ];
    }

    /** @return array<string, mixed> */
    private function pending(): array
    {
        return ['paidUtc' => null, 'status' => 1, 'statusName' => 'قيد الانتظار'] + $this->paid(102.57, 2.56);
    }

    /**
     * EzonePay's quote at 2.5 %, as the sandbox answers it: reversed, the charge that leaves
     * `amount` with the shop — the fee out of the whole charge, every method — in thousandths.
     *
     * @param  array<string, mixed>  $body
     * @return array<string, float>
     */
    private function quoteFor(array $body): array
    {
        $rate = 0.025;
        $amount = (float) $body['amount'];

        if (($body['isReverseCalculation'] ?? false) !== true) {
            return ['totalCommissionPercentage' => $rate, 'totalCommissionAmount' => round($amount * $rate, 3), 'amountToCharge' => $amount];
        }

        $charge = $amount / (1 - $rate);

        return ['totalCommissionPercentage' => $rate, 'totalCommissionAmount' => round($charge - $amount, 3), 'amountToCharge' => round($charge, 3)];
    }

    /** @return array<string, string> */
    private function app(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    /** @return array<string, string> */
    private function staff(array $permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @param  array<string, mixed>  $extra
     */
    private function start(Customer $customer, int $method = 111, string $amount = '100', array $extra = []): TestResponse
    {
        return $this->withHeaders($this->app($customer))->postJson('/api/v1/client/payments/intents', [
            'method' => $method,
            'amount' => $amount,
            ...$extra,
        ]);
    }

    private function otp(Customer $customer, string $intent, string $code = '1234'): TestResponse
    {
        return $this->withHeaders($this->app($customer))
            ->postJson("/api/v1/client/payments/intents/{$intent}/otp", ['otp' => $code]);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function webhook(array $payload, ?string $secret = self::SECRET): TestResponse
    {
        $body = json_encode($payload);
        $signature = $secret === null ? null : base64_encode(hash_hmac('sha256', (string) $body, $secret, true));

        return $this->call('POST', '/api/v1/webhooks/ezonepay', [], [], [], array_filter([
            'CONTENT_TYPE' => 'application/json',
            'HTTP_ACCEPT' => 'application/json',
            'HTTP_X_SIGNATURE' => $signature,
        ]), (string) $body);
    }

    private function balance(Customer $customer): string
    {
        return app(WalletService::class)->balanceOf((int) $customer->id);
    }

    private function ezone(): string
    {
        $treasury = app(TreasuryService::class);

        return $treasury->balanceOf($treasury->systemAccount(TreasuryAccount::EZONE));
    }

    // ── switched off ────────────────────────────────────────────────────────────────────

    public function test_off_by_default_nothing_is_offered_and_nothing_starts(): void
    {
        config(['ezone_pay.enabled' => false]);
        $customer = Customer::factory()->registered()->create();

        $this->withHeaders($this->app($customer))->getJson('/api/v1/client/payments/methods')
            ->assertOk()
            ->assertJsonPath('data.enabled', false)
            ->assertJsonCount(0, 'data.methods');

        $this->start($customer)->assertStatus(503);
        Http::assertNothingSent();
    }

    // ── the methods ─────────────────────────────────────────────────────────────────────

    public function test_the_methods_carry_their_fee_and_limits_libyana_first(): void
    {
        OnlinePaymentMethod::query()->where('method', 111)->update(['daily_limit' => '300.00']);
        $customer = Customer::factory()->registered()->create();

        $methods = $this->withHeaders($this->app($customer))->getJson('/api/v1/client/payments/methods')
            ->assertOk()
            ->assertJsonPath('data.enabled', true)
            ->assertJsonPath('data.fee_payer', 'customer')
            ->assertJsonPath('data.methods.0.id', 111)
            ->assertJsonPath('data.methods.0.fee_percentage', '2.5')
            ->assertJsonPath('data.methods.0.limits.daily.limit', '300.00')
            ->assertJsonPath('data.methods.0.limits.daily.remaining', '300.00')
            ->json('data.methods');

        // Only what the merchant account offers: 101, 102, 111, 123 — not 103, which it does not list.
        $this->assertEqualsCanonicalizing([101, 102, 111, 123], array_column($methods, 'id'));
    }

    public function test_a_quote_says_what_is_charged_for_what_reaches_the_wallet(): void
    {
        $customer = Customer::factory()->registered()->create();

        $this->withHeaders($this->app($customer))->postJson('/api/v1/client/payments/quote', ['method' => 111, 'amount' => '100'])
            ->assertOk()
            ->assertJsonPath('data.amount', '100.00')
            ->assertJsonPath('data.total', '102.57')
            ->assertJsonPath('data.fee', '2.57');

        // Every method alike — EzonePay keeps 2.5 % of the whole charge.
        $this->withHeaders($this->app($customer))->postJson('/api/v1/client/payments/quote', ['method' => 102, 'amount' => '100'])
            ->assertOk()
            ->assertJsonPath('data.total', '102.57');
    }

    // ── OTP ─────────────────────────────────────────────────────────────────────────────

    public function test_an_otp_top_up_credits_exactly_the_quoted_net_and_books_the_fee(): void
    {
        $customer = Customer::factory()->registered()->create();

        $intent = $this->start($customer)
            ->assertCreated()
            ->assertJsonPath('data.intent.requires_otp', true)
            ->assertJsonPath('data.intent.total', '102.57')
            ->json('data.intent.id');

        $this->otp($customer, $intent)
            ->assertOk()
            ->assertJsonPath('data.intent.status', IntentStatus::Succeeded->value)
            ->assertJsonPath('data.balance', '100.00');

        // The wallet: 100. «Ezone»: 102.57 in, 2.56 out as the fee → 100.01, what EzonePay owes.
        $this->assertSame('100.00', $this->balance($customer));
        $this->assertSame('100.01', $this->ezone());

        $fee = TreasuryOperation::query()->where('type', 'expense')->firstOrFail();
        $this->assertSame('2.56', (string) $fee->amount);
        $this->assertSame(ExpenseCategory::ONLINE_PAYMENT_FEE, $fee->category?->code);

        $entry = CustomerWalletEntry::query()->firstOrFail();
        $this->assertSame('online', $entry->method->value);
        $this->artisan('wallets:check')->assertSuccessful();

        // Libyana's number is the customer's own phone, sent though the app left it out.
        Http::assertSent(fn (HttpRequest $r) => str_ends_with($r->url(), '/libyana/initiate')
            && $r['serviceMobileNumber'] === $customer->phone
            && $r['amount'] === 102.57
            && $r['shopId'] === 42);
    }

    /**
     * «محفظتي» puts the method's own logo and name on an online top-up — «رصيد ليبيانا», not
     * the bare «دفع إلكتروني» every online row would otherwise share.
     */
    public function test_the_customers_list_names_the_method_an_online_top_up_came_through(): void
    {
        // Arrange — a Libyana top-up, credited by its code.
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();

        // Act
        $response = $this->withHeaders($this->app($customer))->getJson('/api/v1/client/wallet/entries');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.method', 'online')
            ->assertJsonPath('data.0.online_method', OnlineMethod::Libyana->value)
            ->assertJsonPath('data.0.method_label', OnlineMethod::Libyana->label());
    }

    // ── the ezone:* commands ──────────────────────────────────────────────────────────────

    public function test_the_smoke_test_signs_in_and_lists_the_methods_and_their_rates(): void
    {
        // Act — the commands name the real gateway; it has to be buildable on its own.
        $this->artisan('ezone:smoke-test')
            // Assert
            ->expectsOutputToContain('رصيد ليبيانا')
            ->expectsOutputToContain('2.50 %')
            ->assertSuccessful();
    }

    public function test_without_a_shop_id_ezonepay_is_left_to_use_the_merchants_default_shop(): void
    {
        // Arrange
        config(['ezone_pay.shop_id' => null]);
        $customer = Customer::factory()->registered()->create();

        // Act
        $this->start($customer)->assertCreated();

        // Assert — sent without `shopId` rather than with a zero.
        Http::assertSent(fn (HttpRequest $request) => str_ends_with($request->url(), '/initiate')
            && ! array_key_exists('shopId', $request->data()));
    }

    public function test_subscribing_the_webhook_prints_the_secret_for_env(): void
    {
        // Act & Assert
        $this->artisan('ezone:webhook-subscribe', ['url' => 'https://shop.example/api/v1/webhooks/ezonepay'])
            ->expectsOutputToContain('EZONE_PAY_WEBHOOK_SECRET=c2VjcmV0')
            ->assertSuccessful();
    }

    public function test_the_webhook_test_asks_ezonepay_to_send_one(): void
    {
        // Act & Assert
        $this->artisan('ezone:webhook-test')->assertSuccessful();
        Http::assertSent(fn (HttpRequest $request) => str_ends_with($request->url(), '/Webhook/test-event/2'));
    }

    public function test_the_poll_does_not_use_up_the_limit_of_the_otp(): void
    {
        // Arrange — the card page asks every four seconds; twenty asks is five minutes of it.
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');

        foreach (range(1, 20) as $ignored) {
            $this->withHeaders($this->app($customer))->getJson("/api/v1/client/payments/intents/{$intent}")->assertOk();
        }

        // Act
        $response = $this->otp($customer, $intent);

        // Assert — each route counts its own: the OTP's ten a minute are untouched.
        $response->assertOk()->assertJsonPath('data.intent.status', 'succeeded');
    }

    public function test_a_wrong_otp_keeps_the_attempt_waiting_until_its_tries_run_out(): void
    {
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->otpAccepted = false;
        $this->transaction = $this->pending();

        $this->otp($customer, $intent)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'رمز التحقق غير صحيح');

        $this->assertSame(IntentStatus::Pending, PaymentIntent::query()->firstOrFail()->status);

        $this->otp($customer, $intent)->assertUnprocessable();
        $this->otp($customer, $intent)->assertUnprocessable();
        $this->otp($customer, $intent)->assertUnprocessable()->assertJsonValidationErrors('otp');

        $this->assertSame(IntentStatus::Failed, PaymentIntent::query()->firstOrFail()->status);
        $this->assertSame('0.00', $this->balance($customer));
    }

    public function test_another_customers_attempt_is_a_404(): void
    {
        $owner = Customer::factory()->registered()->create();
        $intent = $this->start($owner)->assertCreated()->json('data.intent.id');

        $this->otp(Customer::factory()->registered()->create(), $intent)->assertNotFound();
        $this->assertSame(0, PaymentIntent::query()->firstOrFail()->otp_attempts);
    }

    public function test_the_same_request_key_returns_the_first_attempt(): void
    {
        $customer = Customer::factory()->registered()->create();

        $first = $this->start($customer, extra: ['client_token' => 'k-1'])->assertCreated()->json('data.intent.id');
        $second = $this->start($customer, extra: ['client_token' => 'k-1'])->assertCreated()->json('data.intent.id');

        $this->assertSame($first, $second);
        $this->assertSame(1, PaymentIntent::query()->count());
    }

    // ── the webhook ─────────────────────────────────────────────────────────────────────

    public function test_an_unsigned_or_wrongly_signed_webhook_is_refused(): void
    {
        $this->webhook(['event' => 2, 'transactionId' => 5001], null)->assertUnauthorized();
        $this->webhook(['event' => 2, 'transactionId' => 5001], 'wrong')->assertUnauthorized();

        config(['ezone_pay.webhook_secret' => null]);
        $this->webhook(['event' => 2, 'transactionId' => 5001])->assertUnauthorized();

        $this->assertSame(0, GatewayWebhookEvent::query()->count());
    }

    public function test_a_paid_webhook_credits_once_however_often_it_comes_and_with_the_otp_too(): void
    {
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $payload = ['event' => 2, 'transactionId' => 5001, 'transactionType' => 'online', 'orderReference' => 'x'];

        $this->webhook($payload)->assertOk()->assertJsonPath('message', 'Received');
        $this->webhook($payload)->assertOk();
        $this->otp($customer, $intent)->assertUnprocessable(); // already settled — nothing waits for a code

        $this->assertSame('100.00', $this->balance($customer));
        $this->assertSame(1, CustomerWalletEntry::query()->count());
        $this->assertSame(1, GatewayWebhookEvent::query()->count());
        $this->assertSame(GatewayWebhookEvent::PROCESSED, GatewayWebhookEvent::query()->firstOrFail()->status);
    }

    public function test_the_webhook_is_confirmed_with_ezonepay_before_anything_is_credited(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->start($customer)->assertCreated();
        $this->transaction = $this->pending();

        $this->webhook(['event' => 2, 'transactionId' => 5001])->assertOk();

        $this->assertSame('0.00', $this->balance($customer));
        $this->assertSame(IntentStatus::Pending, PaymentIntent::query()->firstOrFail()->status);
    }

    public function test_a_different_amount_waits_for_a_person_and_credits_nothing(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->start($customer)->assertCreated();
        $this->transaction = $this->paid(50, 1.25);

        $this->webhook(['event' => 2, 'transactionId' => 5001])->assertOk();

        $this->assertSame(IntentStatus::NeedsReview, PaymentIntent::query()->firstOrFail()->status);
        $this->assertSame('0.00', $this->balance($customer));
    }

    public function test_a_paid_webhook_revives_an_attempt_we_had_given_up_on(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->start($customer)->assertCreated();
        PaymentIntent::query()->update(['status' => IntentStatus::Expired->value]);

        $this->webhook(['event' => 2, 'transactionId' => 5001])->assertOk();

        $this->assertSame(IntentStatus::Succeeded, PaymentIntent::query()->firstOrFail()->status);
        $this->assertSame('100.00', $this->balance($customer));
    }

    // ── card link and QR ────────────────────────────────────────────────────────────────

    public function test_a_card_link_is_opened_once_and_credited_by_the_webhook_through_our_reference(): void
    {
        $customer = Customer::factory()->registered()->create();

        $first = $this->start($customer, 101)
            ->assertCreated()
            ->assertJsonPath('data.intent.flow', 'link')
            ->assertJsonPath('data.intent.payment_url', 'https://pay.ezone.test/l/77')
            ->json('data.intent.id');

        // The same amount again within the hour: the same link, not a second one.
        $this->assertSame($first, $this->start($customer, 101)->assertCreated()->json('data.intent.id'));

        $this->transaction = $this->paid(102.57, 2.56);
        $reference = PaymentIntent::query()->firstOrFail()->our_reference;
        $this->webhook(['event' => 2, 'transactionId' => 5001, 'orderReference' => $reference])->assertOk();

        $this->withHeaders($this->app($customer))->getJson("/api/v1/client/payments/intents/{$first}")
            ->assertOk()
            ->assertJsonPath('data.intent.status', IntentStatus::Succeeded->value)
            ->assertJsonPath('data.intent.is_final', true);

        $this->assertSame(5001, (int) PaymentIntent::query()->firstOrFail()->provider_transaction_id);
    }

    public function test_a_qr_payment_is_credited_in_the_same_request(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->transaction = $this->paid(102.57, 2.56);

        $this->start($customer, 123, '100', ['qr_content' => 'QR-PAYLOAD'])
            ->assertCreated()
            ->assertJsonPath('data.intent.status', IntentStatus::Succeeded->value);

        $this->assertSame('100.00', $this->balance($customer));
    }

    // ── limits, fields, fee payer ───────────────────────────────────────────────────────

    public function test_limits_count_pending_attempts_and_landing_on_the_cap_is_allowed(): void
    {
        OnlinePaymentMethod::query()->where('method', 111)->update(['daily_limit' => '150.00']);
        $customer = Customer::factory()->registered()->create();

        $this->start($customer, 111, '100')->assertCreated();   // pending, still counts
        $this->start($customer, 111, '60')->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->start($customer, 111, '50')->assertCreated();    // exactly 150
    }

    public function test_a_method_that_needs_a_card_number_says_so(): void
    {
        $this->start(Customer::factory()->registered()->create(), 102)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('card_number');
    }

    public function test_a_switched_off_method_is_refused(): void
    {
        OnlinePaymentMethod::query()->where('method', 111)->update(['is_active' => false]);

        $this->start(Customer::factory()->registered()->create())
            ->assertUnprocessable()
            ->assertJsonValidationErrors('method');
    }

    public function test_when_the_shop_pays_the_fee_the_customer_is_charged_the_net_alone(): void
    {
        TreasurySetting::current()->forceFill(['online_fee_payer' => 'shop'])->save();
        $customer = Customer::factory()->registered()->create();
        $this->transaction = $this->paid(100, 2.5);

        $intent = $this->start($customer)->assertCreated()->assertJsonPath('data.intent.total', '100.00')->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();

        // The wallet still receives 100; «Ezone» holds 97.50 — the shop carried the 2.50.
        $this->assertSame('100.00', $this->balance($customer));
        $this->assertSame('97.50', $this->ezone());
    }

    // ── «اشحن وادفع» ────────────────────────────────────────────────────────────────────

    public function test_a_top_up_for_an_order_pays_the_order_from_the_wallet(): void
    {
        $customer = Customer::factory()->registered()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'items_total' => '80.00',
            'delivery_price' => '0.00',
            'grand_total' => '80.00',
            'status' => OrderStatus::Ready,
        ]);

        $intent = $this->start($customer, extra: ['order_id' => $order->id])->assertCreated()->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();

        // 100 in, 80 to the order, 20 left in the wallet.
        $this->assertSame('80.00', (string) $order->refresh()->paid_amount);
        $this->assertSame('20.00', $this->balance($customer));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_top_up_for_a_deposit_pays_the_deposit_and_no_more(): void
    {
        // Arrange — the عربون chosen in the basket (2026-10-19): 30 of an 80 order.
        $customer = Customer::factory()->registered()->create();
        $order = Order::factory()->create([
            'customer_id' => $customer->id,
            'items_total' => '80.00',
            'delivery_price' => '0.00',
            'grand_total' => '80.00',
            'status' => OrderStatus::AwaitingDeposit,
            'deposit_expected_amount' => '30.00',
        ]);

        // Act
        $intent = $this->start($customer, extra: ['order_id' => $order->id, 'order_amount' => '30'])
            ->assertCreated()
            ->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();

        // Assert — 100 in, the 30 chosen to the order, the rest stays the customer's.
        $this->assertSame('30.00', (string) $order->refresh()->paid_amount);
        $this->assertSame(OrderStatus::DepositPaid, $order->status);
        $this->assertSame('70.00', $this->balance($customer));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_an_order_amount_needs_an_order(): void
    {
        $this->start(Customer::factory()->registered()->create(), extra: ['order_amount' => '30'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('order_amount');
    }

    public function test_another_customers_order_is_refused(): void
    {
        $theirs = Order::factory()->create();

        $this->start(Customer::factory()->registered()->create(), extra: ['order_id' => $theirs->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('order_id');
    }

    // ── recheck and reconcile ───────────────────────────────────────────────────────────

    public function test_the_sweep_credits_a_payment_whose_webhook_was_lost_and_expires_the_stale(): void
    {
        $paid = Customer::factory()->registered()->create();
        $this->start($paid)->assertCreated();
        PaymentIntent::query()->update(['created_at' => now()->subMinutes(15)]);

        $this->artisan('payments:reconcile')->assertSuccessful();

        $this->assertSame('100.00', $this->balance($paid));

        $stale = Customer::factory()->registered()->create();
        $this->start($stale)->assertCreated();
        $this->transaction = $this->pending();
        PaymentIntent::query()->where('customer_id', $stale->id)->update([
            'created_at' => now()->subHour(),
            'expires_at' => now()->subMinute(),
        ]);

        $this->artisan('payments:reconcile')->assertSuccessful();

        $this->assertSame(IntentStatus::Expired, PaymentIntent::query()->where('customer_id', $stale->id)->firstOrFail()->status);
    }

    public function test_staff_see_the_attempts_and_can_recheck_one(): void
    {
        $customer = Customer::factory()->registered()->create();
        $this->start($customer)->assertCreated();
        $uuid = PaymentIntent::query()->firstOrFail()->uuid;
        $headers = $this->staff([PermissionName::ViewOnlinePayments, PermissionName::ReconcileOnlinePayments]);

        $this->withHeaders($headers)->getJson('/api/v1/online-payments')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.can_recheck', true)
            ->assertJsonPath('meta.enabled', true);

        $this->withHeaders($headers)->postJson("/api/v1/online-payments/{$uuid}/recheck")
            ->assertOk()
            ->assertJsonPath('data.status', IntentStatus::Succeeded->value);

        $this->assertSame('100.00', $this->balance($customer));
    }

    // ── what staff may not do ───────────────────────────────────────────────────────────

    public function test_an_online_top_up_is_not_undone_by_hand_and_not_typed_at_the_counter(): void
    {
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();
        $headers = $this->staff([
            PermissionName::ViewCustomerWallets,
            PermissionName::TopUpCustomerWallets,
            PermissionName::ReverseCustomerWalletEntries,
        ]);

        $entry = CustomerWalletEntry::query()->firstOrFail();
        $this->withHeaders($headers)->postJson("/api/v1/wallet-entries/{$entry->id}/reverse", ['reason' => 'خطأ'])
            ->assertUnprocessable();

        $this->withHeaders($headers)->postJson("/api/v1/customers/{$customer->id}/wallet/top-ups", [
            'amount' => '10',
            'method' => 'online',
        ])->assertUnprocessable()->assertJsonValidationErrors('method');
    }

    // ── step 6: the payout ──────────────────────────────────────────────────────────────

    public function test_ezonepays_payout_moves_ezone_to_the_bank_and_books_what_it_kept(): void
    {
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();
        $bank = TreasuryAccount::query()->where('kind', AccountKind::Bank->value)->where('is_default', true)->firstOrFail();
        $headers = $this->staff([PermissionName::RecordTreasuryOperations]);

        $this->withHeaders($headers)->postJson('/api/v1/ezone-payouts', [
            'amount' => '99.01',
            'kept' => '1.00',
            'to_account_id' => $bank->id,
            'reference' => 'EZ-0001',
            'client_token' => 'payout-1',
        ])->assertCreated()->assertJsonPath('data.ezone_balance', '0.00');

        // The same request again records nothing.
        $this->withHeaders($headers)->postJson('/api/v1/ezone-payouts', [
            'amount' => '99.01',
            'kept' => '1.00',
            'to_account_id' => $bank->id,
            'client_token' => 'payout-1',
        ])->assertOk();

        // The bank has what arrived; «Ezone» is empty; two fees — the top-up's and the payout's.
        $this->assertSame('99.01', app(TreasuryService::class)->balanceOf($bank));
        $this->assertSame('0.00', $this->ezone());
        $this->assertSame(2, TreasuryOperation::query()->where('type', 'expense')->count());
        $this->assertSame(1, TreasuryOperation::query()->where('type', 'transfer')->count());
    }

    public function test_a_payout_naming_no_account_lands_in_the_banks_default(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->otp($customer, $intent)->assertOk();
        $bank = TreasuryAccount::query()->where('kind', AccountKind::Bank->value)->where('is_default', true)->firstOrFail();

        // Act — what the app sends when «وصل إلى» is left on «تلقائي».
        $response = $this->withHeaders($this->staff([PermissionName::RecordTreasuryOperations]))
            ->postJson('/api/v1/ezone-payouts', ['amount' => '100.01', 'client_token' => 'payout-2']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.ezone_balance', '0.00');
        $this->assertSame('100.01', app(TreasuryService::class)->balanceOf($bank));
    }

    // ── «Ezone» is filled by EzonePay alone ───────────────────────────────────────────────

    public function test_ezone_cannot_be_made_the_default_wallet_account(): void
    {
        // Arrange — it is a wallet, so the kind alone would let it be Libyana's default.
        $ezone = TreasuryAccount::query()->where('system_code', TreasuryAccount::EZONE)->firstOrFail();
        $libyana = TreasuryAccount::query()->where('kind', AccountKind::Wallet->value)->where('is_default', true)->firstOrFail();

        // Act
        $response = $this->withHeaders($this->staff([PermissionName::ManageTreasury]))
            ->putJson("/api/v1/treasury/accounts/{$ezone->id}", ['is_default' => true]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('is_default');
        $this->assertTrue($libyana->fresh()?->is_default);
        $this->assertFalse((bool) $ezone->fresh()?->is_default);
    }

    public function test_wallet_money_is_never_collected_into_ezone(): void
    {
        // Arrange
        $ezone = TreasuryAccount::query()->where('system_code', TreasuryAccount::EZONE)->firstOrFail();

        // Act
        $response = $this->withHeaders($this->staff([PermissionName::ManageTreasury]))
            ->putJson('/api/v1/treasury/settings', ['collect_wallet' => true, 'collect_wallet_into_id' => $ezone->id]);

        // Assert — and nothing of the refused request was kept.
        $response->assertUnprocessable()->assertJsonValidationErrors('collect_wallet_into_id');
        $this->assertNull(TreasurySetting::current()->collect_wallet_into_id);
        $this->assertFalse((bool) TreasurySetting::current()->collect_wallet);
    }

    public function test_nothing_is_paid_from_or_into_ezone_by_hand_but_it_can_be_counted(): void
    {
        // Arrange — «Ezone» holds the 100.01 EzonePay owes after one top-up.
        $customer = Customer::factory()->registered()->create();
        $this->otp($customer, $this->start($customer)->assertCreated()->json('data.intent.id'))->assertOk();
        $ezone = TreasuryAccount::query()->where('system_code', TreasuryAccount::EZONE)->firstOrFail();
        $cash = TreasuryAccount::query()->where('kind', AccountKind::Cash->value)->where('is_default', true)->firstOrFail();
        $category = ExpenseCategory::query()->where('name', 'إيجار')->firstOrFail();
        $headers = $this->staff([PermissionName::ViewTreasury, PermissionName::RecordTreasuryOperations, PermissionName::AdjustTreasuryBalances]);
        $operate = fn (array $body) => $this->withHeaders($headers)->postJson('/api/v1/treasury/operations', $body + ['amount' => '10', 'notes' => 'باليد']);

        // Act & Assert — out of it, into it, spent from it: refused.
        $operate(['type' => 'withdrawal', 'from_account_id' => $ezone->id])->assertUnprocessable()->assertJsonValidationErrors('from_account_id');
        $operate(['type' => 'deposit', 'to_account_id' => $ezone->id])->assertUnprocessable()->assertJsonValidationErrors('to_account_id');
        $operate(['type' => 'expense', 'from_account_id' => $ezone->id, 'category_id' => $category->id])->assertUnprocessable();
        $operate(['type' => 'transfer', 'from_account_id' => $ezone->id, 'to_account_id' => $cash->id])->assertUnprocessable();
        $operate(['type' => 'transfer', 'from_account_id' => $cash->id, 'to_account_id' => $ezone->id])->assertUnprocessable();
        $this->assertSame('100.01', $this->ezone());

        // A count still records what EzonePay's statement says.
        $this->withHeaders($headers)->postJson('/api/v1/treasury/operations', [
            'type' => 'adjustment',
            'to_account_id' => $ezone->id,
            'counted_balance' => '100.00',
            'notes' => 'كشف EzonePay',
        ])->assertCreated();
        $this->assertSame('100.00', $this->ezone());

        // And the app is told to offer none of it.
        $this->withHeaders($headers)->getJson("/api/v1/treasury/accounts/{$ezone->id}")
            ->assertOk()
            ->assertJsonPath('data.account.is_spendable', false);
    }

    // ── EzonePay's documented API (2026-10-11) ───────────────────────────────────────────

    public function test_a_payment_is_confirmed_at_the_online_transaction_address(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');

        // Act
        $this->otp($customer, $intent)->assertOk()->assertJsonPath('data.intent.status', 'succeeded');

        // Assert — and EzonePay's own `Comission` is the fee booked.
        Http::assertSent(fn (HttpRequest $request) => $request->method() === 'GET'
            && str_ends_with($request->url(), '/payments/transactions/5001/online'));
        $this->assertSame('2.56', (string) PaymentIntent::query()->sole()->provider_fee);
    }

    public function test_an_amount_reported_after_the_fee_is_still_the_charge_we_asked_for(): void
    {
        // Arrange — `Amount` as what reached the merchant: 102.57 − 2.56.
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = $this->paid(100.01, 2.56);

        // Act
        $this->otp($customer, $intent)->assertOk();

        // Assert
        $this->assertSame('100.00', $this->balance($customer));
    }

    public function test_a_half_paid_answer_is_never_credited_and_waits_for_a_person_once_its_time_is_up(): void
    {
        // Arrange — a paid date, but a status that does not say paid.
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['statusName' => 'Processing', 'status' => 7] + $this->paid(102.57, 2.56);

        // Act — the OTP is accepted, the confirmation is not clear.
        $this->otp($customer, $intent)->assertOk()->assertJsonPath('data.intent.status', 'pending');

        // Assert — still waiting while it has time …
        $this->assertSame('0.00', $this->balance($customer));
        $this->assertSame(IntentStatus::Pending, PaymentIntent::query()->sole()->status);

        // … and a person's, not the sweep's to expire, once it is up.
        PaymentIntent::query()->update(['created_at' => now()->subHour(), 'expires_at' => now()->subMinute()]);
        $this->artisan('payments:reconcile')->assertSuccessful();

        $after = PaymentIntent::query()->sole();
        $this->assertSame(IntentStatus::NeedsReview, $after->status);
        $this->assertStringContainsString('processing', (string) $after->failure_reason);
        $this->assertSame('0.00', $this->balance($customer));
    }

    public function test_status_3_is_paid_beside_a_paid_date_whatever_the_name_says(): void
    {
        // Arrange — the sandbox's 3, under a name we have not met.
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['statusName' => 'Completed'] + $this->paid(102.57, 2.56);

        // Act
        $this->otp($customer, $intent)->assertOk()->assertJsonPath('data.intent.status', 'succeeded');

        // Assert
        $this->assertSame('100.00', $this->balance($customer));
    }

    public function test_status_3_without_a_paid_date_credits_nothing(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['paidUtc' => null] + $this->paid(102.57, 2.56);

        // Act
        $this->otp($customer, $intent)->assertOk()->assertJsonPath('data.intent.status', 'pending');

        // Assert
        $this->assertSame('0.00', $this->balance($customer));
    }

    public function test_a_second_code_after_the_payment_went_through_credits_it_and_sends_nothing(): void
    {
        // Arrange — the sandbox, 2026-10-11: the first code paid, our answer was not yet clear, the
        // app asked again, and EzonePay answered the second code «السجل غير موجود».
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['paidUtc' => null] + $this->paid(102.57, 2.56);
        $this->otp($customer, $intent)->assertOk()->assertJsonPath('data.intent.status', 'pending');
        $this->transaction = $this->paid(102.57, 2.56);

        // Act
        $response = $this->otp($customer, $intent);

        // Assert — credited from EzonePay's answer; the code was sent once.
        $response->assertOk()->assertJsonPath('data.intent.status', 'succeeded');
        $this->assertSame('100.00', $this->balance($customer));
        $codes = Http::recorded(fn (HttpRequest $request) => str_ends_with($request->url(), '/online-payment/complete'));
        $this->assertCount(1, $codes);
    }

    public function test_a_second_code_while_the_payment_is_unclear_is_not_sent(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['paidUtc' => null] + $this->paid(102.57, 2.56);
        $this->otp($customer, $intent)->assertOk();

        // Act
        $response = $this->otp($customer, $intent);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('otp');
        $this->assertStringContainsString('لا ترسل الرمز مرة أخرى', (string) $response->json('message'));
        $this->assertSame(1, PaymentIntent::query()->sole()->otp_attempts);
    }

    public function test_once_the_code_is_taken_the_app_stops_asking_for_one_and_its_poll_credits_the_payment(): void
    {
        // Arrange — EzonePay took the code; its answer is not yet clear.
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['paidUtc' => null] + $this->paid(102.57, 2.56);

        $this->otp($customer, $intent)
            ->assertOk()
            ->assertJsonPath('data.intent.requires_otp', false)
            ->assertJsonPath('data.intent.is_confirming', true)
            ->assertJsonPath('data.intent.is_final', false);

        // Act — EzonePay now says paid; the app's next poll.
        $this->transaction = $this->paid(102.57, 2.56);
        $poll = $this->withHeaders($this->app($customer))->getJson("/api/v1/client/payments/intents/{$intent}");

        // Assert
        $poll->assertOk()
            ->assertJsonPath('data.intent.status', 'succeeded')
            ->assertJsonPath('data.intent.is_confirming', false)
            ->assertJsonPath('data.balance', '100.00');
    }

    public function test_the_poll_asks_ezonepay_at_most_every_ten_seconds(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $intent = $this->start($customer)->assertCreated()->json('data.intent.id');
        $this->transaction = ['paidUtc' => null] + $this->paid(102.57, 2.56);
        $this->otp($customer, $intent)->assertOk();

        // Act — three polls in a row, as the app makes them.
        foreach (range(1, 3) as $ignored) {
            $this->withHeaders($this->app($customer))->getJson("/api/v1/client/payments/intents/{$intent}")->assertOk();
        }

        // Assert — once for the code, once for the first poll; the other two read what we had.
        $asked = Http::recorded(fn (HttpRequest $request) => str_ends_with($request->url(), '/payments/transactions/5001/online'));
        $this->assertCount(2, $asked);
    }

    public function test_a_cancelled_transaction_fails_the_attempt(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $this->start($customer)->assertCreated();
        $this->transaction = ['statusName' => 'ملغاة', 'status' => 4, 'paidUtc' => null, 'cancelledUtc' => '2026-10-11T10:02:00Z'] + $this->paid(102.57, 2.56);
        PaymentIntent::query()->update(['created_at' => now()->subMinutes(15)]);

        // Act
        $this->artisan('payments:reconcile')->assertSuccessful();

        // Assert
        $this->assertSame(IntentStatus::Failed, PaymentIntent::query()->sole()->status);
    }

    public function test_a_card_link_takes_one_payment_and_ends_with_the_attempt(): void
    {
        // Act
        $customer = Customer::factory()->registered()->create(['name' => 'سالم علي', 'phone' => '+218 91-234-5678']);
        $this->start($customer, 101)->assertCreated();

        // Assert — one use, an end, and the customer EzonePay requires for one use.
        $expires = PaymentIntent::query()->sole()->expires_at?->utc()->format('Y-m-d\TH:i:s\Z');

        Http::assertSent(fn (HttpRequest $request) => str_ends_with($request->url(), '/payment-link/new')
            && $request['maxUsageCount'] === 1
            && $request['expiresAt'] === $expires
            && $request['customer'] === ['firstName' => 'سالم', 'lastName' => 'علي', 'phoneNumber' => '0912345678']);
    }

    public function test_a_card_payment_whose_webhook_never_came_is_found_on_its_link(): void
    {
        // Arrange — paid on the hosted page; no webhook.
        $customer = Customer::factory()->registered()->create();
        $this->start($customer, 101)->assertCreated();
        $this->transaction = $this->paid(102.57, 2.56);
        $this->linkPayments = [['transactionId' => 5001, 'amount' => 102.57, 'paymentMethod' => 'بطاقة']];
        PaymentIntent::query()->update(['created_at' => now()->subMinutes(31)]);

        // Act
        $this->artisan('payments:reconcile')->assertSuccessful();

        // Assert
        $intent = PaymentIntent::query()->sole();
        $this->assertSame(IntentStatus::Succeeded, $intent->status);
        $this->assertSame(5001, (int) $intent->provider_transaction_id);
        $this->assertSame('100.00', $this->balance($customer));
    }

    public function test_an_unpaid_card_link_is_given_up_on_only_after_its_grace(): void
    {
        // Arrange
        $this->start(Customer::factory()->registered()->create(), 101)->assertCreated();
        PaymentIntent::query()->update(['created_at' => now()->subMinutes(70), 'expires_at' => now()->subMinutes(10)]);

        // Act & Assert — ten minutes past its end: a last-minute payment may not be listed yet.
        $this->artisan('payments:reconcile')->assertSuccessful();
        $this->assertSame(IntentStatus::Pending, PaymentIntent::query()->sole()->status);

        PaymentIntent::query()->update(['expires_at' => now()->subMinutes(16)]);
        $this->artisan('payments:reconcile')->assertSuccessful();
        $this->assertSame(IntentStatus::Expired, PaymentIntent::query()->sole()->status);
    }

    public function test_a_card_link_paid_twice_credits_nothing_and_waits_for_a_person(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $this->start($customer, 101)->assertCreated();
        $this->linkPayments = [['transactionId' => 5001, 'amount' => 102.57], ['transactionId' => 5002, 'amount' => 102.57]];
        $uuid = PaymentIntent::query()->sole()->uuid;

        // Act
        $this->withHeaders($this->staff([PermissionName::ViewOnlinePayments, PermissionName::ReconcileOnlinePayments]))
            ->postJson("/api/v1/online-payments/{$uuid}/recheck")
            ->assertOk();

        // Assert
        $this->assertSame(IntentStatus::NeedsReview, PaymentIntent::query()->sole()->status);
        $this->assertSame('0.00', $this->balance($customer));
    }

    public function test_the_price_is_ezonepays_own_reverse_quote_and_the_start_charges_it(): void
    {
        // Arrange — a method whose rule we could not guess: 3 on 100.
        $this->quote = ['totalCommissionPercentage' => 0.03, 'totalCommissionAmount' => 3.0, 'amountToCharge' => 103.0];
        $customer = Customer::factory()->registered()->create();

        // Act
        $this->withHeaders($this->app($customer))->postJson('/api/v1/client/payments/quote', ['method' => 111, 'amount' => '100'])
            ->assertOk()
            ->assertJsonPath('data.total', '103.00')
            ->assertJsonPath('data.fee', '3.00');
        $this->start($customer)->assertCreated()->assertJsonPath('data.intent.total', '103.00');

        // Assert — asked once, in reverse, for what must reach the shop; the start reused it.
        Http::assertSent(fn (HttpRequest $request) => str_ends_with($request->url(), '/commission/quote')
            && $request['isReverseCalculation'] === true
            && $request['amount'] === 100.0);
        Http::assertSent(fn (HttpRequest $request) => str_ends_with($request->url(), '/libyana/initiate') && $request['amount'] === 103.0);
        Http::assertSentCount(5); // sign-in, methods, rate at 100, the quote, the start
    }

    public function test_below_a_methods_least_payment_is_refused_before_ezonepay_is_asked_to_charge(): void
    {
        // Arrange — MobiCash takes 10 at least: 5 + its fee is 5.13.
        $customer = Customer::factory()->registered()->create();

        // Act & Assert
        $this->withHeaders($this->app($customer))->postJson('/api/v1/client/payments/quote', ['method' => 102, 'amount' => '5'])
            ->assertUnprocessable()
            ->assertJsonPath('message', 'أقل مبلغٍ يُدفع بهذه الطريقة 10.00 د.ل');
        $this->start($customer, 102, '5', ['card_number' => '1234567890'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('amount');

        Http::assertNotSent(fn (HttpRequest $request) => str_ends_with($request->url(), '/initiate'));
        $this->assertSame(0, PaymentIntent::query()->count());
    }
}
