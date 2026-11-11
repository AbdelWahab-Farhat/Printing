<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «لا طلبية طباعة بلا ألوانها» — PRINT-COLORS.md §9.
 *
 * Arrange - Act - Assert throughout.
 */
class MandatoryPrintColorsTest extends TestCase
{
    use RefreshDatabase;

    private const BLACK = ['name' => 'أسود', 'code' => null, 'hex' => '#000000'];

    private const GOLD = ['name' => 'ذهبي', 'code' => null, 'hex' => '#C9A227'];

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * @return array<string, string>
     */
    private function everything(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, PermissionName::cases()));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function variant(?ProductCategory $category = null): ProductVariant
    {
        $product = Product::factory()->create([
            'pricing_mode' => PricingMode::Tiered,
            'min_order_quantity' => '100',
            'product_category_id' => $category?->getKey(),
        ]);
        $variant = ProductVariant::factory()->create(['product_id' => $product->getKey()]);
        ProductPriceTier::factory()->create([
            'product_variant_id' => $variant->getKey(),
            'min_quantity' => '100',
            'unit_price' => '1.000',
        ]);

        return $variant;
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(Customer $customer, array $overrides = [], ?ProductVariant $variant = null): array
    {
        $variant ??= $this->variant();

        return array_merge([
            'customer_id' => $customer->getKey(),
            'city_id' => City::factory()->create()->getKey(),
            'items' => [[
                'product_id' => $variant->product_id,
                'product_variant_id' => $variant->getKey(),
                'quantity' => '200',
            ]],
        ], $overrides);
    }

    private function take(array $payload): TestResponse
    {
        return $this->withHeaders($this->everything())->postJson('/api/v1/orders', $payload);
    }

    private function move(Order $order, OrderStatus $to): TestResponse
    {
        return $this->withHeaders($this->everything())
            ->postJson("/api/v1/orders/{$order->id}/status", ['status' => $to->value]);
    }

    /**
     * @param  list<array<string, mixed>>|null  $colors
     */
    private function version(Order $order, ?array $colors, OrderDesignStatus $status = OrderDesignStatus::Proposed): OrderDesign
    {
        $design = CustomerDesign::factory()->create([
            'customer_id' => $order->customer_id,
            'print_colors' => $colors,
        ]);

        return OrderDesign::factory()->create([
            'order_id' => $order->getKey(),
            'customer_design_id' => $design->getKey(),
            'version' => (int) $order->designs()->withTrashed()->max('version') + 1,
            'status' => $status,
            'print_colors' => $colors,
        ]);
    }

    // ───────────────────────────── taking an order ─────────────────────────────

    public function test_a_print_order_with_no_design_is_refused_and_nothing_is_written(): void
    {
        // Arrange
        $customer = Customer::factory()->create();

        // Act
        $response = $this->take($this->payload($customer, ['design_source' => DesignSource::Customer->value]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_ids');
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_a_design_with_no_colours_refuses_the_order(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->create(['customer_id' => $customer->getKey(), 'label' => 'شعار المحل']);

        // Act
        $response = $this->take($this->payload($customer, ['design_ids' => [$design->getKey()]]));

        // Assert — the message names the design that needs them.
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
        $this->assertStringContainsString('«شعار المحل»', $response->json('message'));
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_a_colour_named_without_its_swatch_does_not_count(): void
    {
        // Arrange — «أزرق» alone is how the wrong blue got printed.
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->create([
            'customer_id' => $customer->getKey(),
            'print_colors' => [self::BLACK, ['name' => 'أزرق', 'code' => null, 'hex' => null]],
        ]);

        // Act
        $response = $this->take($this->payload($customer, ['design_ids' => [$design->getKey()]]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
    }

    public function test_a_press_code_alone_is_enough(): void
    {
        // Arrange — colours written before swatches mattered, by somebody who knew the code.
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->create([
            'customer_id' => $customer->getKey(),
            'print_colors' => [['name' => 'أحمر', 'code' => 'PANTONE 186 C', 'hex' => null]],
        ]);

        // Act
        $response = $this->take($this->payload($customer, ['design_ids' => [$design->getKey()]]));

        // Assert
        $response->assertCreated();
    }

    public function test_every_design_on_the_order_must_carry_its_colours(): void
    {
        // Arrange — two files for one job, the second without colours.
        $customer = Customer::factory()->create();
        $front = CustomerDesign::factory()->printable()->create(['customer_id' => $customer->getKey()]);
        $back = CustomerDesign::factory()->create(['customer_id' => $customer->getKey(), 'label' => 'الخلف']);

        // Act
        $response = $this->take($this->payload($customer, ['design_ids' => [$front->getKey(), $back->getKey()]]));

        // Assert
        $response->assertStatus(422);
        $this->assertStringContainsString('«الخلف»', $response->json('message'));
    }

    public function test_a_print_order_with_a_coloured_design_is_taken(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->printable()->create(['customer_id' => $customer->getKey()]);

        // Act
        $response = $this->take($this->payload($customer, ['design_ids' => [$design->getKey()]]));

        // Assert
        $response->assertCreated();
        $this->assertDatabaseHas('order_designs', ['customer_design_id' => $design->getKey()]);
    }

    public function test_an_order_we_are_drawing_ourselves_may_wait_for_its_design(): void
    {
        // Arrange — the colours are asked for on the design ticket instead.
        $customer = Customer::factory()->create();

        // Act
        $response = $this->take($this->payload($customer, ['design_source' => DesignSource::InHouse->value]));

        // Assert
        $response->assertCreated();
    }

    public function test_plain_goods_need_no_design_and_no_colours(): void
    {
        // Arrange — «سادة»: nothing is printed.
        $customer = Customer::factory()->create();
        $plain = $this->variant(ProductCategory::factory()->skipsProduction()->create());

        // Act
        $response = $this->take($this->payload($customer, [], $plain));

        // Assert
        $response->assertCreated();
        $this->assertSame(OrderFlow::NoProduction->value, $response->json('data.production_flow'));
    }

    // ───────────────────────── colours typed in the form ─────────────────────────

    public function test_colours_typed_in_the_form_fill_an_empty_library_design(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->create(['customer_id' => $customer->getKey()]);

        // Act
        $response = $this->take($this->payload($customer, [
            'design_ids' => [$design->getKey()],
            'design_colors' => [['design_id' => $design->getKey(), 'print_colors' => [self::BLACK, self::GOLD]]],
        ]));

        // Assert — the library has them for the next order, and this order has its copy.
        $response->assertCreated();
        $this->assertSame([self::BLACK, self::GOLD], $design->fresh()->print_colors);
        $this->assertSame(
            [self::BLACK, self::GOLD],
            OrderDesign::query()->where('order_id', $response->json('data.id'))->sole()->print_colors,
        );
    }

    public function test_colours_typed_for_a_coloured_design_change_only_this_order(): void
    {
        // Arrange — «هالمرة بالذهبي».
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->create([
            'customer_id' => $customer->getKey(),
            'print_colors' => [self::BLACK],
        ]);

        // Act
        $response = $this->take($this->payload($customer, [
            'design_ids' => [$design->getKey()],
            'design_colors' => [['design_id' => $design->getKey(), 'print_colors' => [self::GOLD]]],
        ]));

        // Assert
        $response->assertCreated();
        $this->assertSame([self::BLACK], $design->fresh()->print_colors);
        $this->assertSame(
            [self::GOLD],
            OrderDesign::query()->where('order_id', $response->json('data.id'))->sole()->print_colors,
        );
    }

    public function test_a_typed_colour_needs_its_swatch(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $design = CustomerDesign::factory()->create(['customer_id' => $customer->getKey()]);

        // Act
        $response = $this->take($this->payload($customer, [
            'design_ids' => [$design->getKey()],
            'design_colors' => [['design_id' => $design->getKey(), 'print_colors' => [['name' => 'أزرق']]]],
        ]));

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_colors.0.print_colors.0.hex');
    }

    public function test_colours_for_a_design_not_on_the_order_are_refused(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $chosen = CustomerDesign::factory()->printable()->create(['customer_id' => $customer->getKey()]);
        $other = CustomerDesign::factory()->create(['customer_id' => $customer->getKey()]);

        // Act
        $response = $this->take($this->payload($customer, [
            'design_ids' => [$chosen->getKey()],
            'design_colors' => [['design_id' => $other->getKey(), 'print_colors' => [self::BLACK]]],
        ]));

        // Assert — and the other design's library entry is untouched.
        $response->assertStatus(422)->assertJsonValidationErrors('design_colors.0.design_id');
        $this->assertNull($other->fresh()->print_colors);
    }

    // ───────────────────────────── a customer's request ─────────────────────────────

    public function test_a_request_without_colours_cannot_be_accepted_until_they_are_set(): void
    {
        // Arrange — the customer app sent it with an uncoloured design.
        $order = Order::factory()->status(OrderStatus::Requested)->create(['production_flow' => OrderFlow::Standard]);
        $version = $this->version($order, null);

        // Act
        $refused = $this->move($order, OrderStatus::New);

        // Assert — still a request.
        $refused->assertStatus(422)->assertJsonValidationErrors('print_colors');
        $this->assertSame(OrderStatus::Requested, $order->fresh()->status);

        // Act — staff set the colours on the order, then accept.
        $this->withHeaders($this->everything())
            ->patchJson("/api/v1/orders/{$order->id}/designs/{$version->id}/colors", ['print_colors' => [self::BLACK]])
            ->assertOk();
        $accepted = $this->move($order->fresh(), OrderStatus::New);

        // Assert
        $accepted->assertOk()->assertJsonPath('data.status', 'new');
    }

    // ───────────────────────────── the press ─────────────────────────────

    public function test_the_press_refuses_a_version_without_colours(): void
    {
        // Arrange — an order taken before the rule.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $this->version($order, null);

        // Act — the move asks for the colours (§12), and is refused when they are not given.
        $response = $this->move($order, OrderStatus::Printing);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.press_colors');
        $this->assertSame(OrderStatus::ReadyToPrint, $order->fresh()->status);
    }

    public function test_the_domain_refuses_a_version_without_colours_whatever_door_it_comes_through(): void
    {
        // Arrange — no request, so no question: the guard itself.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create([
            'stock_deducted_at' => now(),
            'production_flow' => OrderFlow::Standard,
        ]);
        $this->version($order, null);

        // Act / Assert
        $this->expectException(\App\Domain\Order\Exceptions\PrintOrderNeedsColors::class);
        $this->expectExceptionMessage('قبل الانتقال إلى «قيد الطباعة»');
        app(\App\Domain\Order\Actions\ChangeOrderStatus::class)($order, OrderStatus::Printing);
    }

    public function test_the_press_refuses_an_order_with_no_design_at_all(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);

        // Act — colours answered, but nothing to put them on.
        $response = $this->moveWith($order, OrderStatus::Printing, ['press_colors' => [self::BLACK]]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('design_ids');
    }

    public function test_a_design_picked_in_the_move_with_its_own_colours_needs_no_answer(): void
    {
        // Arrange — the question is optional when there is no version yet.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $design = CustomerDesign::factory()->printable()->create(['customer_id' => $order->customer_id]);

        // Act
        $response = $this->moveWith($order, OrderStatus::Printing, ['design_ids' => [$design->getKey()]]);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'printing');
    }

    public function test_the_press_reads_the_approved_version_not_a_newer_proposal(): void
    {
        // Arrange — the approved file has its colours; a later proposal does not.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $this->version($order, [self::BLACK], OrderDesignStatus::Approved);
        $this->version($order, null);

        // Act
        $response = $this->move($order, OrderStatus::Printing);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'printing');
    }

    // ───────────────────── the colours answered on the move (§12) ─────────────────────

    /**
     * @param  array<string, mixed>  $fields
     */
    private function moveWith(Order $order, OrderStatus $to, array $fields): TestResponse
    {
        return $this->withHeaders($this->everything())
            ->postJson("/api/v1/orders/{$order->id}/status", ['status' => $to->value, 'fields' => $fields]);
    }

    /**
     * @return array<string, mixed>|null
     */
    private function pressField(Order $order, string $type): ?array
    {
        $transitions = $this->withHeaders($this->everything())
            ->getJson("/api/v1/orders/{$order->id}")
            ->json('data.available_transitions');

        $printing = collect($transitions)->firstWhere('status', OrderStatus::Printing->value);

        return collect($printing['fields'] ?? [])->firstWhere('type', $type);
    }

    public function test_the_move_asks_for_the_colours_the_version_is_missing_and_opens_on_what_it_has(): void
    {
        // Arrange — one colour named without its swatch.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $this->version($order, [['name' => 'أزرق', 'code' => null, 'hex' => null]]);

        // Act
        $asked = $this->pressField($order, 'print_colors_input');

        // Assert
        $this->assertNotNull($asked);
        $this->assertTrue($asked['required']);
        $this->assertSame([['name' => 'أزرق', 'code' => null, 'hex' => null]], $asked['colors']);
        $this->assertNull($this->pressField($order, 'print_colors'));
    }

    public function test_a_version_with_its_colours_gets_the_reminder_not_the_question(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $this->version($order, [self::BLACK]);

        // Act / Assert
        $this->assertNull($this->pressField($order, 'print_colors_input'));
        $this->assertNotNull($this->pressField($order, 'print_colors'));
    }

    public function test_colours_answered_on_the_move_go_on_the_version_and_the_order_goes_to_the_press(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $version = $this->version($order, null);
        $library = $version->customerDesign()->first();

        // Act
        $response = $this->moveWith($order, OrderStatus::Printing, ['press_colors' => [self::BLACK, self::GOLD]]);

        // Assert — this order's copy; the library is left as it was, as on «تعديل الطلبية».
        $response->assertOk()->assertJsonPath('data.status', 'printing');
        $this->assertSame([self::BLACK, self::GOLD], $version->fresh()->print_colors);
        $this->assertNull($library->fresh()->print_colors);
    }

    public function test_a_colour_answered_without_its_swatch_is_refused_under_the_field(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $version = $this->version($order, null);

        // Act
        $response = $this->moveWith($order, OrderStatus::Printing, ['press_colors' => [self::BLACK, ['name' => 'أزرق']]]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.press_colors.1.hex');
        $this->assertNull($version->fresh()->print_colors);
        $this->assertSame(OrderStatus::ReadyToPrint, $order->fresh()->status);
    }

    public function test_the_move_cannot_skip_the_question(): void
    {
        // Arrange
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $this->version($order, null);

        // Act
        $response = $this->move($order, OrderStatus::Printing);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.press_colors');
    }

    public function test_a_design_picked_in_the_move_takes_the_colours_answered_beside_it(): void
    {
        // Arrange — no artwork yet; the file is picked on the move itself.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $design = CustomerDesign::factory()->create(['customer_id' => $order->customer_id]);

        // Act
        $response = $this->moveWith($order, OrderStatus::Printing, [
            'design_ids' => [$design->getKey()],
            'press_colors' => [self::GOLD],
        ]);

        // Assert
        $response->assertOk();
        $this->assertSame(
            [self::GOLD],
            OrderDesign::query()->where('order_id', $order->id)->sole()->print_colors,
        );
    }

    public function test_a_rejected_version_is_not_what_the_press_prints(): void
    {
        // Arrange — the newest version was turned down; the one before it has colours.
        $order = Order::factory()->status(OrderStatus::ReadyToPrint)->create(['stock_deducted_at' => now()]);
        $this->version($order, [self::GOLD]);
        $this->version($order, null, OrderDesignStatus::Rejected);

        // Act
        $response = $this->move($order, OrderStatus::Printing);

        // Assert
        $response->assertOk();
    }
}
