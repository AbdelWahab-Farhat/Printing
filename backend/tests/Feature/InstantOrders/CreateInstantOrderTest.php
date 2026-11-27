<?php

declare(strict_types=1);

namespace Tests\Feature\InstantOrders;

use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Enums\MovementType;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\OrderType;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\SellsAtTheCounter;
use Tests\TestCase;

/**
 * Taking an instant order at a branch counter — INSTANT-ORDERS-PLAN.md §3–§4.
 *
 * The customer, the order and the stock in one step; refused whole, with nothing left behind,
 * when any part of the sale cannot go ahead.
 */
class CreateInstantOrderTest extends TestCase
{
    use RefreshDatabase;
    use SellsAtTheCounter;

    protected function setUp(): void
    {
        parent::setUp();

        $this->registerPermissions();
    }

    public function test_a_sale_creates_the_customer_and_the_order_and_takes_the_stock(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct('10.000');
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $home = City::factory()->create();

        // Act
        $response = $this->withHeaders($this->headersFor($employee))->postJson('/api/v1/instant-orders', $this->sale(
            $branch,
            [[$product, $variant, 15]],
            ['phone' => '+218 91 234 5678', 'name' => 'سالم', 'city_id' => $home->getKey()],
        ));

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.order_type', OrderType::Instant->value)
            ->assertJsonPath('data.status', OrderStatus::New->value);

        $order = Order::query()->findOrFail($response->json('data.id'));
        $this->assertSame(OrderType::Instant, $order->order_type);
        $this->assertSame(OrderFlow::NoProduction, $order->production_flow);
        $this->assertSame((int) $branch->getKey(), (int) $order->city_id);
        $this->assertSame((int) $branch->default_warehouse_id, (int) $order->fulfillment_warehouse_id);
        $this->assertNotNull($order->stock_deducted_at);
        $this->assertSame('0.00', (string) $order->delivery_price);
        $this->assertSame('150.00', (string) $order->grand_total);

        // The stock left at creation: 20 − 15.
        $this->assertSame('5.000', $this->shelf((int) $branch->default_warehouse_id, $variant));

        // The customer is new, with the normalised phone and their own address — not the branch's.
        $customer = Customer::query()->where('phone', '0912345678')->firstOrFail();
        $this->assertSame('سالم', $customer->name);
        $this->assertSame((int) $home->getKey(), (int) $customer->city_id);
        $this->assertSame((int) $customer->getKey(), (int) $order->customer_id);
    }

    public function test_an_existing_customer_is_linked_not_duplicated_and_keeps_their_details(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $customer = Customer::factory()->create(['name' => 'سالم الأصلي', 'phone' => '0912345678', 'city_id' => null]);
        $typedCity = City::factory()->create();

        // Act — typed with Arabic digits and another name.
        $response = $this->withHeaders($this->headersFor($employee))->postJson('/api/v1/instant-orders', $this->sale(
            $branch,
            [[$product, $variant, 2]],
            ['phone' => '٠٩١٢٣٤٥٦٧٨', 'name' => 'اسم آخر', 'city_id' => $typedCity->getKey()],
        ));

        // Assert
        $response->assertCreated();
        $this->assertSame(1, Customer::query()->where('phone', '0912345678')->count());
        $this->assertSame((int) $customer->getKey(), (int) $response->json('data.customer_id'));

        $customer->refresh();
        $this->assertSame('سالم الأصلي', $customer->name, 'the stored name is kept');
        $this->assertSame((int) $typedCity->getKey(), (int) $customer->city_id, 'a blank address is filled');
        $this->assertStringContainsString('سالم الأصلي', (string) $response->json('meta.customer_notice'));
    }

    public function test_an_existing_address_is_never_replaced(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $home = City::factory()->create();
        $customer = Customer::factory()->create(['name' => 'سالم', 'phone' => '0912345678', 'city_id' => $home->getKey()]);

        // Act
        $this->withHeaders($this->headersFor($employee))->postJson('/api/v1/instant-orders', $this->sale(
            $branch,
            [[$product, $variant, 2]],
            ['name' => 'سالم', 'city_id' => City::factory()->create()->getKey()],
        ))->assertCreated();

        // Assert
        $this->assertSame((int) $home->getKey(), (int) $customer->refresh()->city_id);
    }

    public function test_a_short_line_refuses_the_whole_sale_and_names_the_product_the_warehouse_and_the_figures(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct('10.000', 'أكياس شحن', '35×40');
        $this->stockUp($branch->default_warehouse_id, $variant, '7');
        $employee = $this->branchEmployee($branch);

        // Act
        $response = $this->withHeaders($this->headersFor($employee))->postJson(
            '/api/v1/instant-orders',
            $this->sale($branch, [[$product, $variant, 10]], ['phone' => '0920000000']),
        );

        // Assert
        $response->assertUnprocessable();
        $this->assertSame(
            ['أكياس شحن 35×40 — مخزن بريمولا: المطلوب 10 كجم، المتاح 7 كجم'],
            $response->json('errors.items'),
        );
        $this->assertSame(0, Order::query()->count());
        $this->assertFalse(Customer::query()->where('phone', '0920000000')->exists(), 'no customer from a failed sale');
        $this->assertSame('7.000', $this->shelf((int) $branch->default_warehouse_id, $variant));
    }

    public function test_the_same_product_on_two_lines_is_added_together(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '10');
        $employee = $this->branchEmployee($branch);

        // Act — 6 + 6 against a shelf of 10.
        $response = $this->withHeaders($this->headersFor($employee))->postJson(
            '/api/v1/instant-orders',
            $this->sale($branch, [[$product, $variant, 6], [$product, $variant, 6]]),
        );

        // Assert
        $response->assertUnprocessable();
        $this->assertStringContainsString('المطلوب 12 كجم، المتاح 10 كجم', $response->json('errors.items.0'));
    }

    public function test_zero_and_negative_quantities_are_refused(): void
    {
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $employee = $this->branchEmployee($branch);

        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, 0]]))
            ->assertUnprocessable()->assertJsonValidationErrors('items.0.quantity');

        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, -3]]))
            ->assertUnprocessable()->assertJsonValidationErrors('items.0.quantity');
    }

    public function test_only_eligible_products_can_be_sold(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        $employee = $this->branchEmployee($branch);

        [$switchedOff, $offSize] = $this->plainProduct();
        $switchedOff->forceFill(['is_instant_sale' => false])->save();

        [$printed, $printedSize] = $this->plainProduct();
        $printed->forceFill(['product_category_id' => ProductCategory::factory()->create()->getKey()])->save();

        // Act / Assert
        $refused = $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$switchedOff, $offSize, 1]]))
            ->assertUnprocessable();
        $this->assertSame("«{$switchedOff->name}» غير متاح للبيع الفوري", $refused->json('errors')['items.0.product_id'][0]);

        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$printed, $printedSize, 1]]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('items.0.product_id');

        $this->assertSame(0, Order::query()->count());
    }

    public function test_the_branch_must_be_active_assigned_and_configured(): void
    {
        // Arrange
        [$product, $variant] = $this->plainProduct();

        $mine = $this->counterBranch();
        $other = $this->counterBranch(name: 'مكتب ولي العهد');
        $employee = $this->branchEmployee($mine);

        $inactive = $this->counterBranch(name: 'فرع مغلق');
        $inactive->forceFill(['is_branch_active' => false])->save();
        $inactive->employees()->attach($employee->getKey());

        $unconfigured = $this->counterBranch(name: 'فرع بلا مخزن');
        $unconfigured->forceFill(['default_warehouse_id' => null])->save();
        $unconfigured->employees()->attach($employee->getKey());

        $delivery = City::factory()->create();

        // Act / Assert
        $headers = $this->headersFor($employee);

        $this->withHeaders($headers)->postJson('/api/v1/instant-orders', $this->sale($other, [[$product, $variant, 1]]))
            ->assertUnprocessable()->assertJsonPath('errors.branch_id.0', 'لست مصرحاً بالعمل في «مكتب ولي العهد»');

        $this->withHeaders($headers)->postJson('/api/v1/instant-orders', $this->sale($inactive, [[$product, $variant, 1]]))
            ->assertUnprocessable()->assertJsonPath('errors.branch_id.0', 'الفرع «فرع مغلق» غير نشط ولا يقبل طلبات جديدة');

        $this->withHeaders($headers)->postJson('/api/v1/instant-orders', $this->sale($unconfigured, [[$product, $variant, 1]]))
            ->assertUnprocessable()->assertJsonValidationErrors('branch_id');

        $this->withHeaders($headers)->postJson('/api/v1/instant-orders', $this->sale($delivery, [[$product, $variant, 1]]))
            ->assertUnprocessable()->assertJsonPath('errors.branch_id.0', 'مكان الاستلام يجب أن يكون مكتب استلام');

        $this->assertSame(0, Order::query()->count());
    }

    public function test_whoever_manages_branches_may_sell_at_any_branch_without_being_assigned(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '5');
        $manager = User::factory()->create();
        $manager->givePermissionTo([PermissionName::CreateInstantOrders->value, PermissionName::ManageBranches->value]);

        // Act / Assert
        $this->withHeaders($this->headersFor($manager))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, 1]]))
            ->assertCreated();
    }

    public function test_a_retried_sale_with_the_same_token_is_written_once(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);
        $payload = $this->sale($branch, [[$product, $variant, 4]], extra: ['client_token' => 'tap-1']);
        $headers = $this->headersFor($employee);

        // Act
        $first = $this->withHeaders($headers)->postJson('/api/v1/instant-orders', $payload)->assertCreated();
        $second = $this->withHeaders($headers)->postJson('/api/v1/instant-orders', $payload)->assertCreated();

        // Assert
        $this->assertSame($first->json('data.id'), $second->json('data.id'));
        $this->assertSame(1, Order::query()->count());
        $this->assertSame('16.000', $this->shelf((int) $branch->default_warehouse_id, $variant));
        $this->assertSame(1, StockMovement::query()->where('movement_type', MovementType::OrderFulfillment->value)->count());
    }

    public function test_a_discount_needs_the_discount_grant(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '20');
        $employee = $this->branchEmployee($branch);

        // Act / Assert — the seeded role has no discount grant.
        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, 2]], extra: ['discount' => 5]))
            ->assertForbidden();
        $this->assertSame(0, Order::query()->count());

        $employee->givePermissionTo(PermissionName::DiscountOrders->value);

        $response = $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, 2]], extra: ['discount' => 5]))
            ->assertCreated();

        $this->assertSame('15.00', (string) Order::query()->findOrFail($response->json('data.id'))->grand_total);
    }

    public function test_name_and_phone_are_required_and_a_region_must_fit_its_city(): void
    {
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $employee = $this->branchEmployee($branch);
        $line = [['product_id' => $product->getKey(), 'product_variant_id' => $variant->getKey(), 'quantity' => 1]];

        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', [
                'branch_id' => $branch->getKey(),
                'customer' => ['phone' => '12'],
                'items' => $line,
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['customer.phone', 'customer.name'])
            ->assertJsonMissingValidationErrors(['customer.city_id', 'customer.region_id']);

        $city = City::factory()->create();
        $elsewhere = Region::factory()->create(['city_id' => City::factory()->create()->getKey()]);

        // A region from another city.
        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', $this->sale($branch, [[$product, $variant, 1]], [
                'city_id' => $city->getKey(),
                'region_id' => $elsewhere->getKey(),
            ]))
            ->assertUnprocessable()
            ->assertJsonValidationErrors('customer.region_id');

        // A region with no city at all.
        $this->withHeaders($this->headersFor($employee))
            ->postJson('/api/v1/instant-orders', [
                'branch_id' => $branch->getKey(),
                'customer' => ['phone' => '0912345678', 'name' => 'سالم', 'region_id' => $elsewhere->getKey()],
                'items' => $line,
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('customer.city_id');
    }

    public function test_the_address_is_optional_and_a_customer_may_be_created_without_one(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct();
        $this->stockUp($branch->default_warehouse_id, $variant, '5');
        $employee = $this->branchEmployee($branch);

        // Act
        $this->withHeaders($this->headersFor($employee))->postJson('/api/v1/instant-orders', [
            'branch_id' => $branch->getKey(),
            'customer' => ['phone' => '0915555555', 'name' => 'زبون عابر'],
            'items' => [['product_id' => $product->getKey(), 'product_variant_id' => $variant->getKey(), 'quantity' => 1]],
        ])->assertCreated()->assertJsonPath('meta.customer_notice', null);

        // Assert — the order is at the branch; the customer simply has no address.
        $customer = Customer::query()->where('phone', '0915555555')->sole();
        $this->assertNull($customer->city_id);
        $this->assertNull($customer->region_id);
    }

    public function test_the_product_list_shows_eligible_sizes_with_what_the_branch_warehouse_holds(): void
    {
        // Arrange
        $branch = $this->counterBranch();
        [$product, $variant] = $this->plainProduct('12.500');
        $this->stockUp($branch->default_warehouse_id, $variant, '7');
        $this->stockUp(Warehouse::factory()->create(), $variant, '100');
        [$hidden] = $this->plainProduct();
        $hidden->forceFill(['is_instant_sale' => false])->save();
        $employee = $this->branchEmployee($branch);

        // Act
        $response = $this->withHeaders($this->headersFor($employee))
            ->getJson('/api/v1/instant-orders/products?branch_id='.$branch->getKey());

        // Assert
        $response->assertOk()->assertJsonPath('meta.warehouse_name', 'مخزن بريمولا');
        $products = collect($response->json('data'));
        $this->assertSame([$product->getKey()], $products->pluck('id')->all());
        $this->assertSame('7.000', $products[0]['variants'][0]['available_quantity']);
        $this->assertSame('12.500', $products[0]['variants'][0]['price_tiers'][0]['unit_price']);
    }

    public function test_a_customer_is_found_by_any_spelling_of_their_phone(): void
    {
        $branch = $this->counterBranch();
        $employee = $this->branchEmployee($branch);
        Customer::factory()->create(['name' => 'سالم', 'phone' => '0912345678']);

        $this->withHeaders($this->headersFor($employee))
            ->getJson('/api/v1/instant-orders/customer?phone='.urlencode('00218912345678'))
            ->assertOk()
            ->assertJsonPath('data.found', true)
            ->assertJsonPath('data.customer.name', 'سالم');

        $this->withHeaders($this->headersFor($employee))
            ->getJson('/api/v1/instant-orders/customer?phone=0919999999')
            ->assertOk()
            ->assertJsonPath('data.found', false);
    }

    public function test_my_branches_lists_only_active_assigned_ones(): void
    {
        $mine = $this->counterBranch();
        $closed = $this->counterBranch(name: 'مغلق');
        $closed->forceFill(['is_branch_active' => false])->save();
        $this->counterBranch(name: 'ليس لي');
        $employee = $this->branchEmployee($mine, $closed);

        $response = $this->withHeaders($this->headersFor($employee))->getJson('/api/v1/instant-orders/branches');

        $response->assertOk();
        $this->assertSame([$mine->getKey()], collect($response->json('data'))->pluck('id')->all());
        $this->assertSame('مخزن بريمولا', $response->json('data.0.warehouse_name'));
    }

    public function test_a_branch_employee_cannot_take_a_normal_order(): void
    {
        $branch = $this->counterBranch();
        $employee = $this->branchEmployee($branch);
        [$product, $variant] = $this->plainProduct();

        $this->withHeaders($this->headersFor($employee))->postJson('/api/v1/orders', [
            'customer_id' => Customer::factory()->create()->getKey(),
            'city_id' => $branch->getKey(),
            'items' => [['product_id' => $product->getKey(), 'product_variant_id' => $variant->getKey(), 'quantity' => 1]],
        ])->assertForbidden();

        $this->withHeaders($this->headersFor($employee))->postJson('/api/v1/customers', [
            'name' => 'عميل', 'phone' => '0911111111',
        ])->assertForbidden();
    }
}
