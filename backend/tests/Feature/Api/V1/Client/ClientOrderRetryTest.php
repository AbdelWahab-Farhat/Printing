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
use App\Domain\Order\Models\Order;
use App\Domain\Wallet\WalletService;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * A retry of «إرسال الطلبية» is not a second order.
 *
 * **The case it is for**: the server wrote the order and the reply never reached the phone — a
 * timeout, a dropped signal. The basket is still full, the customer presses again, and before
 * `client_token` the shop got the order twice, and the wallet paid the عربون twice.
 *
 * Arrange - Act - Assert throughout. The basket is 1000 bags at 0.500 — 500.00 of goods.
 */
class ClientOrderRetryTest extends TestCase
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

    private function customer(string $phone = '0911111111'): Customer
    {
        return Customer::factory()->registered()->create(['phone' => $phone]);
    }

    /** @return array<string, mixed> */
    private function basket(): array
    {
        $category = ProductCategory::factory()->create(['production_mode' => ProductionMode::InHouse]);
        $product = Product::factory()->create([
            'product_category_id' => $category->id,
            'pricing_mode' => PricingMode::Tiered,
        ]);
        $variant = ProductVariant::factory()->create(['product_id' => $product->id]);
        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->id,
            'min_quantity' => 1,
            'unit_price' => '0.500',
        ]);

        return [
            'city_id' => City::factory()->create()->id,
            'items' => [['product_id' => $product->id, 'product_variant_id' => $variant->id, 'quantity' => 1000]],
        ];
    }

    /** @param  array<string, mixed>  $body */
    private function place(Customer $customer, array $body): TestResponse
    {
        return $this->withHeaders(['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken])
            ->postJson('/api/v1/client/orders', $body);
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

    // ── the same key again ──────────────────────────────────────────────────────────────

    public function test_a_request_sent_again_with_its_key_returns_the_first_order(): void
    {
        // Arrange
        $customer = $this->customer();
        $body = [...$this->basket(), 'client_token' => 'key-1'];
        $first = $this->place($customer, $body)->assertCreated();

        // Act
        $second = $this->place($customer, $body);

        // Assert — 200, the same order, and nothing more on the review queue.
        $second->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, Order::query()->count());
    }

    public function test_an_office_deposit_sent_again_with_its_key_returns_the_first_order(): void
    {
        // Arrange
        $customer = $this->customer();
        $body = [...$this->basket(), 'client_token' => 'key-1', 'deposit' => ['payment' => 'office', 'amount' => '125']];
        $first = $this->place($customer, $body)->assertCreated();

        // Act
        $second = $this->place($customer, $body);

        // Assert
        $second->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, Order::query()->count());
    }

    public function test_a_wallet_deposit_sent_again_with_its_key_pays_once(): void
    {
        // Arrange — the wallet case was the worst of the three: the retry was refused as a
        // reused payment key, the app took the refusal as final and dropped the key, and the
        // next press placed and paid a second order.
        $customer = $this->customer();
        $this->fillWallet($customer, '1000');
        $body = [
            ...$this->basket(),
            'client_token' => 'key-1',
            'deposit' => ['payment' => 'wallet', 'amount' => '125', 'client_token' => 'pay-1'],
        ];
        $first = $this->place($customer, $body)->assertCreated();

        // Act
        $second = $this->place($customer, $body);

        // Assert
        $second->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, Order::query()->count());
        $this->assertSame('875.00', $this->balance($customer));
    }

    public function test_the_first_order_is_returned_even_when_the_basket_changed_before_the_retry(): void
    {
        // Arrange — the customer edited the basket while unsure whether the first one went in.
        // It did, so that is the order they have; a second would be the duplicate this stops.
        $customer = $this->customer();
        $first = $this->place($customer, [...$this->basket(), 'client_token' => 'key-1'])->assertCreated();

        // Act
        $second = $this->place($customer, [...$this->basket(), 'client_token' => 'key-1']);

        // Assert
        $second->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(1, Order::query()->count());
    }

    public function test_the_database_refuses_a_second_order_with_the_same_key(): void
    {
        // Arrange — the last guard, under the customer's lock in `PlaceOrderOnce`: should two
        // copies ever get past it, the second row is refused rather than written.
        $customer = $this->customer();
        $this->place($customer, [...$this->basket(), 'client_token' => 'key-1'])->assertCreated();

        // Assert
        $this->expectException(UniqueConstraintViolationException::class);

        // Act
        Order::factory()->create(['customer_id' => $customer->id, 'client_token' => 'key-1']);
    }

    // ── what is still a second order ────────────────────────────────────────────────────

    public function test_a_new_key_is_a_new_order(): void
    {
        // Arrange — the same basket ordered twice on purpose is two orders.
        $customer = $this->customer();
        $basket = $this->basket();
        $this->place($customer, [...$basket, 'client_token' => 'key-1'])->assertCreated();

        // Act
        $second = $this->place($customer, [...$basket, 'client_token' => 'key-2']);

        // Assert
        $second->assertCreated();
        $this->assertSame(2, Order::query()->count());
    }

    public function test_a_key_belongs_to_one_customer(): void
    {
        // Arrange — another phone that happened on the same key is not answered with an order
        // that is not theirs.
        $basket = $this->basket();
        $this->place($this->customer('0911111111'), [...$basket, 'client_token' => 'key-1'])->assertCreated();

        // Act
        $second = $this->place($this->customer('0922222222'), [...$basket, 'client_token' => 'key-1']);

        // Assert
        $second->assertCreated();
        $this->assertSame(2, Order::query()->count());
    }

    public function test_an_app_that_sends_no_key_orders_as_it_did(): void
    {
        // Arrange — an app older than the key.
        $customer = $this->customer();
        $basket = $this->basket();
        $this->place($customer, $basket)->assertCreated();

        // Act
        $second = $this->place($customer, $basket);

        // Assert
        $second->assertCreated();
        $this->assertSame(2, Order::query()->count());
    }

    public function test_a_resend_of_an_order_the_shop_deleted_does_not_bring_it_back(): void
    {
        // Arrange
        $customer = $this->customer();
        $body = [...$this->basket(), 'client_token' => 'key-1'];
        $first = $this->place($customer, $body)->assertCreated();
        Order::query()->findOrFail($first->json('data.id'))->delete();

        // Act
        $second = $this->place($customer, $body);

        // Assert — answered with the deleted one; no fresh copy for the review queue.
        $second->assertOk()->assertJsonPath('data.id', $first->json('data.id'));
        $this->assertSame(0, Order::query()->count());
        $this->assertSame(1, Order::withTrashed()->count());
    }
}
