<?php

declare(strict_types=1);

namespace Tests\Feature\OnlinePayment;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Gateway\EzonePay\EzonePayGateway;
use App\Domain\OnlinePayment\Gateway\Fake\FakeEzonePayGateway;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * `EZONE_PAY_DRIVER=fake` — the pretend EzonePay for trying the top-up on an emulator before the
 * sandbox credentials exist. CUSTOMER-WALLET §٥.
 *
 * What it is held to: nothing leaves the server; everything on our side runs for real (wallet,
 * «Ezone», the fee); `0000` is a wrong code; the card page's «ادفع» credits once however often it
 * is pressed; and **in production the real gateway is bound whatever the driver says**.
 *
 * Arrange - Act - Assert throughout. Libyana at the fake's 2.5 %, fee on the customer: 100 in the
 * wallet is 102.57 charged.
 */
class FakeEzonePayTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        config(['ezone_pay.enabled' => true, 'ezone_pay.driver' => 'fake']);
        Cache::flush();
        Http::preventStrayRequests();
    }

    /** @return array<string, string> */
    private function app(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    private function ezone(): string
    {
        $treasury = app(TreasuryService::class);

        return $treasury->balanceOf($treasury->systemAccount(TreasuryAccount::EZONE));
    }

    public function test_the_fake_is_bound_without_any_credentials(): void
    {
        // Act
        $gateway = app(OnlinePaymentGateway::class);

        // Assert
        $this->assertInstanceOf(FakeEzonePayGateway::class, $gateway);
        $this->assertTrue($gateway->isEnabled());
    }

    public function test_in_production_the_real_gateway_is_bound_whatever_the_driver_says(): void
    {
        // Arrange
        $this->app['env'] = 'production';

        // Act
        $gateway = app(OnlinePaymentGateway::class);

        // Assert — and without credentials it is off, so nothing is offered.
        $this->assertInstanceOf(EzonePayGateway::class, $gateway);
        $this->assertFalse($gateway->isEnabled());
    }

    public function test_an_otp_top_up_credits_the_wallet_for_real(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $headers = $this->app($customer);
        $intent = $this->withHeaders($headers)
            ->postJson('/api/v1/client/payments/intents', ['method' => 111, 'amount' => '100'])
            ->assertCreated()
            ->assertJsonPath('data.intent.requires_otp', true)
            ->json('data.intent.id');

        // Act
        $this->withHeaders($headers)
            ->postJson("/api/v1/client/payments/intents/{$intent}/otp", ['otp' => '1234'])
            ->assertOk()
            ->assertJsonPath('data.intent.status', 'succeeded')
            ->assertJsonPath('data.balance', '100.00');

        // Assert
        $this->assertSame('100.00', app(WalletService::class)->balanceOf((int) $customer->id));
        // «Ezone» holds what was charged, 102.57, less EzonePay's 2.5 % of it (2.56) recorded as
        // an expense.
        $this->assertSame('2.56', (string) PaymentIntent::query()->sole()->provider_fee);
        $this->assertSame('100.01', $this->ezone());
    }

    public function test_0000_is_a_wrong_code_and_the_attempt_keeps_waiting(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $headers = $this->app($customer);
        $intent = $this->withHeaders($headers)
            ->postJson('/api/v1/client/payments/intents', ['method' => 111, 'amount' => '100'])
            ->json('data.intent.id');

        // Act
        $wrong = $this->withHeaders($headers)
            ->postJson("/api/v1/client/payments/intents/{$intent}/otp", ['otp' => '0000']);

        // Assert
        $wrong->assertUnprocessable()->assertJsonValidationErrors('otp');
        $this->assertSame(IntentStatus::Pending, PaymentIntent::query()->sole()->status);
        $this->assertSame(0, CustomerWalletEntry::query()->count());
    }

    public function test_the_card_page_pays_once_however_often_it_is_pressed(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $url = $this->withHeaders($this->app($customer))
            ->postJson('/api/v1/client/payments/intents', ['method' => 101, 'amount' => '100'])
            ->assertCreated()
            ->json('data.intent.payment_url');
        $path = (string) parse_url((string) $url, PHP_URL_PATH);

        // Act
        $page = $this->get($path);
        $this->post($path)->assertOk();
        $this->post($path)->assertOk();

        // Assert
        $page->assertOk()->assertSee('دفع تجريبي');
        $intent = PaymentIntent::query()->sole();
        $this->assertSame(IntentStatus::Succeeded, $intent->status);
        $this->assertSame(1, CustomerWalletEntry::query()->count());
        $this->assertSame('100.00', app(WalletService::class)->balanceOf((int) $customer->id));
    }

    public function test_ezonepay_keeps_its_rate_of_the_whole_charge_on_every_method(): void
    {
        // Arrange — a bank card: 100 for the wallet is 100 ÷ 0.975 = 102.57 charged, as the
        // sandbox quoted every method (2026-10-11).
        $customer = Customer::factory()->registered()->create();
        $url = $this->withHeaders($this->app($customer))
            ->postJson('/api/v1/client/payments/intents', ['method' => 101, 'amount' => '100'])
            ->assertJsonPath('data.intent.total', '102.57')
            ->json('data.intent.payment_url');

        // Act
        $this->post((string) parse_url((string) $url, PHP_URL_PATH))->assertOk();

        // Assert — 2.56, 2.5 % of the whole 102.57; «Ezone» holds the 100.01 left, a hundredth
        // above the wallet's 100 — the charge was rounded up.
        $this->assertSame('2.56', (string) PaymentIntent::query()->sole()->provider_fee);
        $this->assertSame('100.01', $this->ezone());
        $this->assertSame('100.00', app(WalletService::class)->balanceOf((int) $customer->id));
    }

    public function test_the_card_page_pays_nothing_in_production(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $url = $this->withHeaders($this->app($customer))
            ->postJson('/api/v1/client/payments/intents', ['method' => 101, 'amount' => '100'])
            ->json('data.intent.payment_url');
        $this->app['env'] = 'production';

        // Act
        $response = $this->post((string) parse_url((string) $url, PHP_URL_PATH));

        // Assert
        $response->assertNotFound();
        $this->assertSame(0, CustomerWalletEntry::query()->count());
    }
}
