<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Catalog\Enums\ProductionMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Definitions\CustomerChoseDeposit;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Order\Enums\CustomerOrderStage;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Vendor\Models\Vendor;
use App\Domain\Wallet\WalletService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * The عربون of an app order the shop accepted after review — owner, 2026-10-19.
 *
 * **What the suite holds the feature to**: a basket that could not be offered a deposit (a وسيط
 * line here) is offered one once accepted to «جديدة» — at least a quarter in whole dinars; the
 * office parks it in «انتظار العربون», the wallet pays it into «عربون مدفوع» or writes nothing;
 * and the offer is gone for a clerk's order, an order not yet accepted, and once it is answered.
 *
 * Arrange - Act - Assert throughout. 1000 bags at 0.500 from a vendor — 500.00 of goods.
 */
class ReviewedOrderDepositTest extends TestCase
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

    /** @return array<string, string> */
    private function staff(PermissionName ...$permissions): array
    {
        $user = User::factory()->create(['is_active' => true]);
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** A وسيط product — the basket could not take its deposit, so it went to review. */
    private function outsourced(): Product
    {
        $category = ProductCategory::factory()->create(['production_mode' => ProductionMode::Outsourced]);
        $product = Product::factory()->create(['product_category_id' => $category->id]);
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->id,
            'min_quantity' => 1,
            'unit_price' => '0.500',
        ]);

        return $product->refresh();
    }

    /** The customer's request, then the shop accepting it with a vendor named. */
    private function accepted(Customer $customer): Order
    {
        $product = $this->outsourced();

        $this->withHeaders($this->app($customer))->postJson('/api/v1/client/orders', [
            'city_id' => City::factory()->create()->id,
            'items' => [[
                'product_id' => $product->id,
                'product_variant_id' => $product->variants()->first()->id,
                'quantity' => 1000,
            ]],
        ])->assertCreated();

        $order = Order::query()->latest('id')->firstOrFail();

        $this->withHeaders($this->staff(PermissionName::ViewOrders, PermissionName::ManageOrders))
            ->postJson("/api/v1/orders/{$order->id}/status", [
                'status' => OrderStatus::New->value,
                'fields' => ['vendor_id' => Vendor::factory()->create()->id],
            ])->assertOk();

        return $order->refresh();
    }

    private function choose(Customer $customer, Order $order, string $payment, string $amount): TestResponse
    {
        return $this->withHeaders($this->app($customer))
            ->postJson("/api/v1/client/orders/{$order->id}/deposit", [
                'payment' => $payment,
                'amount' => $amount,
            ]);
    }

    private function fillWallet(Customer $customer, string $amount): void
    {
        $this->withHeaders($this->staff(PermissionName::ViewCustomerWallets, PermissionName::TopUpCustomerWallets))
            ->postJson("/api/v1/customers/{$customer->id}/wallet/top-ups", ['amount' => $amount, 'method' => 'cash'])
            ->assertCreated();
    }

    private function balance(Customer $customer): string
    {
        return app(WalletService::class)->balanceOf((int) $customer->id);
    }

    // ── the offer ───────────────────────────────────────────────────────────────────────

    public function test_an_accepted_order_from_review_asks_the_customer_for_the_deposit(): void
    {
        // Arrange
        $me = $this->customer();
        $order = $this->accepted($me);

        // Act
        $response = $this->withHeaders($this->app($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert — «بانتظار العربون» to the customer though «جديدة» to the shop, the basket's
        // bounds, and a line that says what is wanted.
        $response->assertOk()
            ->assertJsonPath('data.stage', CustomerOrderStage::AwaitingDeposit->value)
            ->assertJsonPath('data.stage_label', 'بانتظار العربون')
            ->assertJsonPath('data.deposit_offer.min_amount', '125.00')
            ->assertJsonPath('data.deposit_offer.max_amount', '500.00')
            ->assertJsonPath('data.deposit_offer.min_percent', 25)
            ->assertJsonPath('data.stage_hint', 'قبلنا طلبيتك — اختر العربون لنبدأ العمل');
    }

    public function test_the_list_and_its_stage_filter_say_awaiting_deposit_too(): void
    {
        // Arrange — one waiting on its deposit, and a clerk's «جديدة» beside it.
        $me = $this->customer();
        $offered = $this->accepted($me);
        $clerks = Order::factory()->create([
            'customer_id' => $me->id,
            'status' => OrderStatus::New,
            'items_total' => '500.00',
            'grand_total' => '500.00',
        ]);
        $headers = $this->app($me);

        // Act
        $all = $this->withHeaders($headers)->getJson('/api/v1/client/orders');
        $waiting = $this->withHeaders($headers)->getJson('/api/v1/client/orders?stage=awaiting_deposit');
        $review = $this->withHeaders($headers)->getJson('/api/v1/client/orders?stage=under_review');

        // Assert — the card, and the filter that must agree with it. A clerk's «جديدة» reads as
        // «بانتظار المراجعة» since 2026-10-23.
        $stages = collect($all->assertOk()->json('data'))->pluck('stage', 'id');
        $this->assertSame(CustomerOrderStage::AwaitingDeposit->value, $stages[$offered->id]);
        $this->assertSame(CustomerOrderStage::UnderReview->value, $stages[$clerks->id]);
        $this->assertSame([$offered->id], array_column($waiting->assertOk()->json('data'), 'id'));
        $this->assertSame([$clerks->id], array_column($review->assertOk()->json('data'), 'id'));
    }

    public function test_a_clerks_order_and_a_request_not_yet_accepted_are_not_offered_one(): void
    {
        // Arrange
        $me = $this->customer();
        $clerks = Order::factory()->create([
            'customer_id' => $me->id,
            'status' => OrderStatus::New,
            'items_total' => '500.00',
            'grand_total' => '500.00',
        ]);

        // Act - Assert
        $this->withHeaders($this->app($me))->getJson("/api/v1/client/orders/{$clerks->id}")
            ->assertOk()
            ->assertJsonPath('data.deposit_offer', null);

        $this->choose($me, $clerks, 'office', '200')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit');

        $this->assertSame(OrderStatus::New, $clerks->refresh()->status);
    }

    // ── في المكتب ───────────────────────────────────────────────────────────────────────

    public function test_at_the_office_it_waits_on_the_deposit_the_customer_chose_and_the_staff_are_told(): void
    {
        // Arrange
        $me = $this->customer();
        $order = $this->accepted($me);
        User::factory()->create(['is_active' => true])->givePermissionTo(PermissionName::ManageOrders->value);

        // Act
        $response = $this->choose($me, $order, 'office', '200');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.stage', CustomerOrderStage::AwaitingDeposit->value)
            ->assertJsonPath('data.deposit_expected', '200.00')
            ->assertJsonPath('data.deposit_at_office', true)
            ->assertJsonPath('data.deposit_offer', null);

        $order->refresh();
        $this->assertSame(OrderStatus::AwaitingDeposit, $order->status);
        $this->assertSame('200.00', (string) $order->deposit_expected_amount);
        $this->assertSame(PaymentMethod::Cash, $order->deposit_expected_method);

        $bell = Notification::query()->where('type', NotificationType::OrderDepositChosen)->sole();
        $this->assertSame(
            'عبدو · اختار العميل عربون 200 د.ل في المكتب',
            app(CustomerChoseDeposit::class)->render($bell->payload)->body,
        );
    }

    public function test_once_answered_the_deposit_cannot_be_chosen_again(): void
    {
        // Arrange
        $me = $this->customer();
        $order = $this->accepted($me);
        $this->choose($me, $order, 'office', '200')->assertOk();

        // Act - Assert
        $this->choose($me, $order, 'office', '300')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('deposit');

        $this->assertSame('200.00', (string) $order->refresh()->deposit_expected_amount);
    }

    // ── من المحفظة ──────────────────────────────────────────────────────────────────────

    public function test_from_the_wallet_it_is_paid_and_the_order_goes_ahead(): void
    {
        // Arrange
        $me = $this->customer();
        $order = $this->accepted($me);
        $this->fillWallet($me, '300');

        // Act
        $this->choose($me, $order, 'wallet', '150')
            ->assertOk()
            ->assertJsonPath('data.stage', CustomerOrderStage::Preparing->value);

        // Assert
        $order->refresh();
        $this->assertSame(OrderStatus::DepositPaid, $order->status);
        $this->assertSame('150.00', (string) $order->paid_amount);
        $this->assertTrue($order->is_deposit_received);
        $this->assertSame('150.00', $this->balance($me));
        $this->artisan('wallets:check')->assertSuccessful();
    }

    public function test_a_wallet_that_cannot_cover_it_changes_nothing(): void
    {
        // Arrange
        $me = $this->customer();
        $order = $this->accepted($me);
        $this->fillWallet($me, '100');

        // Act
        $this->choose($me, $order, 'wallet', '150')->assertUnprocessable();

        // Assert — the move is taken back with the payment.
        $order->refresh();
        $this->assertSame(OrderStatus::New, $order->status);
        $this->assertNull($order->deposit_expected_amount);
        $this->assertSame('100.00', $this->balance($me));
    }

    // ── refused ─────────────────────────────────────────────────────────────────────────

    public function test_less_than_a_quarter_more_than_the_goods_or_a_fraction_is_refused(): void
    {
        // Arrange
        $me = $this->customer();
        $order = $this->accepted($me);

        // Act - Assert
        foreach (['124', '501', '200.5'] as $amount) {
            $this->choose($me, $order, 'office', $amount)
                ->assertUnprocessable()
                ->assertJsonValidationErrors('amount');
        }

        $this->assertSame(OrderStatus::New, $order->refresh()->status);
    }

    public function test_another_customers_order_is_a_404(): void
    {
        // Arrange
        $order = $this->accepted($this->customer());
        $stranger = Customer::factory()->registered()->create(['phone' => '0922222222']);

        // Act - Assert
        $this->choose($stranger, $order, 'office', '200')->assertNotFound();
    }
}
