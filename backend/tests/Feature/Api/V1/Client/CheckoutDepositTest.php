<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Definitions\OrderAwaitsReview;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Order\Enums\CustomerOrderStage;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\CheckoutDeposit;
use App\Domain\Wallet\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The عربون chosen in the basket — owner, 2026-10-19; CUSTOMER-APP-DESIGN «عربون السلة».
 *
 * **What the suite holds the feature to**: a priced basket of our own goods may skip review and be
 * born «انتظار العربون» with the amount the customer chose — at least a quarter of the goods, at
 * most all of them; the wallet pays it in the same breath or nothing is written; a basket review
 * still has something to add («حسب الطلب», a وسيط) is refused the step, both by the quote that
 * draws it and by the order that would skip it.
 *
 * Arrange - Act - Assert throughout. The basket is 1000 bags at 0.500 — 500.00 of goods.
 */
class CheckoutDepositTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    // ── helpers ─────────────────────────────────────────────────────────────────────────

    private function customer(): Customer
    {
        return Customer::factory()->registered()->create(['phone' => '0911111111', 'name' => 'عبدو']);
    }

    /** @return array<string, string> */
    private function app(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    private function product(
        ProductionMode $mode = ProductionMode::InHouse,
        PricingMode $pricing = PricingMode::Tiered,
    ): Product {
        $category = ProductCategory::factory()->create(['production_mode' => $mode]);
        $product = Product::factory()->create([
            'product_category_id' => $category->id,
            'pricing_mode' => $pricing,
        ]);
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);

        if ($pricing === PricingMode::Tiered) {
            ProductPriceTier::factory()->create([
                'product_variant_id' => $variant->id,
                'min_quantity' => 1,
                'unit_price' => '0.500',
            ]);
        }

        return $product->refresh();
    }

    /** @return array<string, mixed> */
    private function basket(Product $product): array
    {
        return [
            'city_id' => City::factory()->create()->id,
            'items' => [[
                'product_id' => $product->id,
                'product_variant_id' => $product->variants()->first()->id,
                'quantity' => 1000,
            ]],
        ];
    }

    private function place(Customer $customer, Product $product, string $payment, string $amount): TestResponse
    {
        return $this->withHeaders($this->app($customer))->postJson('/api/v1/client/orders', [
            ...$this->basket($product),
            'deposit' => ['payment' => $payment, 'amount' => $amount],
        ]);
    }

    private function quote(Customer $customer, Product $product): TestResponse
    {
        return $this->withHeaders($this->app($customer))
            ->postJson('/api/v1/client/orders/quote', $this->basket($product));
    }

    private function fillWallet(Customer $customer, string $amount): void
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewCustomerWallets->value,
            PermissionName::TopUpCustomerWallets->value,
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken])
            ->postJson("/api/v1/customers/{$customer->id}/wallet/top-ups", ['amount' => $amount, 'method' => 'cash'])
            ->assertCreated();
    }

    private function balance(Customer $customer): string
    {
        return app(WalletService::class)->balanceOf((int) $customer->id);
    }

    // ── the rule ────────────────────────────────────────────────────────────────────────

    public function test_the_deposit_is_in_whole_dinars_a_quarter_rounded_up_and_the_goods_rounded_down(): void
    {
        // Arrange - Act - Assert — rounding the floor down would let a payment short of a
        // quarter through; rounding the ceiling up would ask for more than the goods.
        $this->assertSame('125.00', CheckoutDeposit::minimum('500.00'));
        $this->assertSame('3.00', CheckoutDeposit::minimum('10.01'));
        $this->assertSame('1.00', CheckoutDeposit::minimum('1.00'));
        $this->assertSame('500.00', CheckoutDeposit::maximum('500.50'));

        // Under a dinar there is no whole dinar to take.
        $this->assertTrue(CheckoutDeposit::fits('1.00'));
        $this->assertFalse(CheckoutDeposit::fits('0.50'));
    }

    // ── the quote draws the step ────────────────────────────────────────────────────────

    public function test_a_priced_basket_of_our_goods_is_offered_the_deposit_between_a_quarter_and_all(): void
    {
        // Act
        $response = $this->quote($this->customer(), $this->product());

        // Assert — goods only, no delivery.
        $response->assertOk()
            ->assertJsonPath('data.deposit.offered', true)
            ->assertJsonPath('data.deposit.min_percent', 25)
            ->assertJsonPath('data.deposit.min_amount', '125.00')
            ->assertJsonPath('data.deposit.max_amount', '500.00');
    }

    public function test_a_basket_waiting_on_a_price_or_a_vendor_is_not_offered_the_deposit(): void
    {
        // Arrange
        $me = $this->customer();

        // Act - Assert
        $this->quote($me, $this->product(pricing: PricingMode::QuoteOnRequest))
            ->assertOk()
            ->assertJsonPath('data.deposit.offered', false)
            ->assertJsonPath('data.deposit.min_amount', null);

        $this->quote($me, $this->product(ProductionMode::Outsourced))
            ->assertOk()
            ->assertJsonPath('data.deposit.offered', false);
    }

    // ── في المكتب ───────────────────────────────────────────────────────────────────────

    public function test_at_the_office_the_order_is_born_waiting_on_the_deposit_the_customer_chose(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->place($me, $this->product(), 'office', '200');

        // Assert — no review, no payment; the amount and the counter on the order.
        $response->assertCreated()
            ->assertJsonPath('data.stage', CustomerOrderStage::AwaitingDeposit->value)
            ->assertJsonPath('data.deposit_expected', '200.00')
            ->assertJsonPath('data.deposit_at_office', true)
            ->assertJsonPath('data.deposit_due', '200.00');

        $order = Order::query()->sole();
        $this->assertSame(OrderStatus::AwaitingDeposit, $order->status);
        $this->assertSame('200.00', (string) $order->deposit_expected_amount);
        $this->assertSame(PaymentMethod::Cash, $order->deposit_expected_method);
        $this->assertSame('0.00', (string) $order->paid_amount);

        // Born there rather than walked there: one row, from nowhere.
        $this->assertSame(1, $order->transitions()->count());
        $this->assertNull($order->transitions()->sole()->from_status);
    }

    public function test_the_whole_amount_is_a_deposit_too(): void
    {
        // Act
        $response = $this->place($this->customer(), $this->product(), 'office', '500');

        // Assert — `deposit_due` is for «العربون أو كاملاً», and here they are one.
        $response->assertCreated()
            ->assertJsonPath('data.deposit_expected', '500.00')
            ->assertJsonPath('data.deposit_due', null);
    }

    // ── من المحفظة ──────────────────────────────────────────────────────────────────────

    public function test_from_the_wallet_the_deposit_is_paid_at_once_and_the_order_goes_ahead(): void
    {
        // Arrange
        $me = $this->customer();
        $this->fillWallet($me, '300');

        // Act
        $response = $this->place($me, $this->product(), 'wallet', '125');

        // Assert
        $response->assertCreated()->assertJsonPath('data.stage', CustomerOrderStage::Preparing->value);

        $order = Order::query()->sole();
        $this->assertSame(OrderStatus::DepositPaid, $order->status);
        $this->assertSame('125.00', (string) $order->paid_amount);
        $this->assertTrue($order->is_deposit_received);
        $this->assertNotNull($order->deposit_payment_id);
        $this->assertSame('175.00', $this->balance($me));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_wallet_that_cannot_cover_the_deposit_writes_nothing(): void
    {
        // Arrange
        $me = $this->customer();
        $this->fillWallet($me, '100');

        // Act
        $response = $this->place($me, $this->product(), 'wallet', '125');

        // Assert — the order goes with the payment.
        $response->assertUnprocessable();
        $this->assertSame(0, Order::query()->withTrashed()->count());
        $this->assertSame('100.00', $this->balance($me));
    }

    // ── refused ─────────────────────────────────────────────────────────────────────────

    public function test_less_than_a_quarter_more_than_the_goods_or_a_fraction_is_refused_under_the_amount(): void
    {
        // Arrange
        $me = $this->customer();
        $product = $this->product();

        // Act - Assert
        $this->place($me, $product, 'office', '124')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit.amount');

        $this->place($me, $product, 'office', '501')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit.amount');

        // Whole dinars only (owner, 2026-10-19).
        $this->place($me, $product, 'office', '200.5')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit.amount');

        $this->assertSame(0, Order::query()->withTrashed()->count());
    }

    public function test_a_basket_review_still_has_to_price_or_place_is_refused_the_deposit(): void
    {
        // Arrange
        $me = $this->customer();

        // Act - Assert — a line «حسب الطلب» has no total to take a quarter of; a وسيط order
        // needs a vendor only staff can name.
        $this->place($me, $this->product(pricing: PricingMode::QuoteOnRequest), 'office', '10')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit');

        $this->place($me, $this->product(ProductionMode::Outsourced), 'office', '200')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit');

        $this->assertSame(0, Order::query()->withTrashed()->count());
    }

    public function test_an_unknown_way_to_pay_is_refused_and_online_is_not_one(): void
    {
        // Arrange — online is a top-up the app finishes first, then a wallet order (owner,
        // 2026-10-19): no order may wait on a payment that has not happened.
        $me = $this->customer();

        // Act - Assert
        foreach (['cheque', 'online'] as $way) {
            $this->place($me, $this->product(), $way, '200')
                ->assertUnprocessable()
                ->assertJsonValidationErrors('deposit.payment');
        }

        $this->assertSame(0, Order::query()->withTrashed()->count());
    }

    public function test_a_topped_up_wallet_pays_the_deposit_the_order_was_placed_with(): void
    {
        // Arrange — the online path as the app walks it: the top-up has landed, then the order.
        $me = $this->customer();
        $this->fillWallet($me, '250');

        // Act
        $this->place($me, $this->product(), 'wallet', '250')->assertCreated();

        // Assert
        $order = Order::query()->sole();
        $this->assertSame(OrderStatus::DepositPaid, $order->status);
        $this->assertSame('250.00', (string) $order->paid_amount);
        $this->assertSame('0.00', $this->balance($me));
    }

    public function test_without_a_deposit_the_order_still_goes_to_review(): void
    {
        // Act — what an app older than the step sends.
        $this->withHeaders($this->app($this->customer()))
            ->postJson('/api/v1/client/orders', $this->basket($this->product()))
            ->assertCreated()
            ->assertJsonPath('data.stage', CustomerOrderStage::UnderReview->value);

        // Assert
        $this->assertSame(OrderStatus::Requested, Order::query()->sole()->status);
    }

    // ── the staff are told ──────────────────────────────────────────────────────────────

    public function test_whoever_reviews_requests_is_told_of_it_and_of_the_deposit(): void
    {
        // Arrange
        $reviewer = User::factory()->create(['is_active' => true]);
        $reviewer->givePermissionTo(PermissionName::ManageOrders->value);
        $me = $this->customer();
        $this->fillWallet($me, '300');

        // Act
        $this->place($me, $this->product(), 'office', '200')->assertCreated();
        $this->place($me, $this->product(), 'wallet', '125')->assertCreated();

        // Assert
        $bodies = Notification::query()
            ->where('type', NotificationType::OrderRequested)
            ->orderBy('id')
            ->get()
            ->map(fn (Notification $n) => app(OrderAwaitsReview::class)->render($n->payload)->body)
            ->all();

        $this->assertSame([
            'العميل: عبدو · بانتظار عربون 200 د.ل',
            'العميل: عبدو · عربون 125 د.ل مدفوع من المحفظة',
        ], $bodies);
    }
}
