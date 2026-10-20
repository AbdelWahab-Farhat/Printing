<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\UndeliveredDisposition;
use App\Domain\Order\Exceptions\OutsourcedLinesNeedACost;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Support\TransitionFields;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «تكلفة المورد» typed for an order — OUTSOURCED-PRODUCTS.md §6.1.
 *
 * `OutsourcedOrderTest` pins the catalogue's cost being copied onto a وسيط line and recognised at
 * «جاهزة». This file pins the two places the figure can now be named for one order instead: beside
 * the price when the order is taken or edited, and on the move into «جاهزة», where the vendor's
 * bill is in somebody's hand.
 *
 * The worked example is a «حسب الطلب» job — 100 ستيكر priced at 2 a piece, which the vendor makes
 * at 0.8 — because that is the job the catalogue could never cost: it has no fixed vendor price.
 *
 * Arrange - Act - Assert throughout.
 */
class OutsourcingCostEntryTest extends TestCase
{
    use RefreshDatabase;

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
    private function auth(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** May take, edit and walk a وسيط order — and read what the vendor charges. */
    private function coordinator(): array
    {
        return $this->auth(...[...$this->walker(), PermissionName::ViewProductCost]);
    }

    /** The same, without `products.view_cost`. */
    private function clerk(): array
    {
        return $this->auth(...$this->walker());
    }

    /**
     * @return list<PermissionName>
     */
    private function walker(): array
    {
        return [
            PermissionName::ViewOrders,
            PermissionName::ManageOrders,
            PermissionName::MoveOrderToManufacturing,
            PermissionName::MoveOrderToReady,
        ];
    }

    /** A sticker job priced «حسب الطلب», whose size carries no vendor cost. */
    private function stickers(): ProductVariant
    {
        $product = Product::factory()->create([
            'name' => 'ستيكر',
            'product_category_id' => ProductCategory::factory()->outsourced()->create()->id,
            'pricing_unit' => PricingUnit::Piece,
            'pricing_mode' => PricingMode::QuoteOnRequest,
            'min_order_quantity' => '1',
        ]);

        return ProductVariant::factory()->for($product)->create([
            'label' => '5*5',
            'cost_price' => null,
            'stock_item_id' => null,
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $line
     */
    private function take(array $headers, ProductVariant $size, array $line = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson('/api/v1/orders', [
            'customer_id' => Customer::factory()->create()->getKey(),
            'city_id' => City::factory()->create()->getKey(),
            'address_details' => 'شارع الجمهورية',
            'vendor_id' => Vendor::factory()->create()->getKey(),
            'items' => [array_merge([
                'product_id' => $size->product_id,
                'product_variant_id' => $size->getKey(),
                'quantity' => '100',
                'unit_price' => '2',
            ], $line)],
        ]);
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $fields
     */
    private function move(array $headers, Order $order, OrderStatus $to, array $fields = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/status",
            array_filter(['status' => $to->value, 'fields' => $fields ?: null]),
        );
    }

    /**
     * @param  array<string, string>  $headers
     * @return list<array<string, mixed>>
     */
    private function readyFields(array $headers, Order $order): array
    {
        $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}")->assertOk();

        return collect($response->json('data.available_transitions'))->firstWhere('status', 'ready')['fields'] ?? [];
    }

    // ─────────────────────────── when the order is taken ───────────────────────────

    public function test_a_cost_typed_with_the_order_is_kept_on_the_line(): void
    {
        // Act — the job the catalogue cannot cost, with the vendor's quote typed beside the price.
        $response = $this->take($this->coordinator(), $this->stickers(), ['unit_cost' => '0.8']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.items.0.unit_cost', '0.800');
    }

    public function test_a_typed_cost_wins_over_the_catalogues(): void
    {
        // Arrange — a size that does carry a vendor price.
        $size = $this->stickers();
        $size->update(['cost_price' => '1.000']);

        // Act — this job was quoted cheaper.
        $response = $this->take($this->coordinator(), $size, ['unit_cost' => '0.75']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.items.0.unit_cost', '0.750');
    }

    public function test_the_catalogues_cost_still_stands_when_nothing_is_typed(): void
    {
        // Arrange
        $size = $this->stickers();
        $size->update(['cost_price' => '1.000']);

        // Act
        $response = $this->take($this->coordinator(), $size);

        // Assert — the old behaviour, untouched.
        $response->assertCreated()->assertJsonPath('data.items.0.unit_cost', '1.000');
    }

    public function test_a_typed_cost_is_ignored_on_a_line_we_make_ourselves(): void
    {
        // Arrange — a printed bag, costed from the shelf and the rate table.
        $printed = Product::factory()->create([
            'product_category_id' => ProductCategory::factory()->create()->id,
            'pricing_unit' => PricingUnit::Piece,
            'pricing_mode' => PricingMode::Tiered,
            'min_order_quantity' => '50',
        ]);
        $size = ProductVariant::factory()->for($printed)->create();
        ProductPriceTier::factory()->create([
            'product_variant_id' => $size->getKey(),
            'min_quantity' => '50',
            'unit_price' => '1.000',
        ]);

        // Act
        $response = $this->withHeaders($this->coordinator())->postJson('/api/v1/orders', [
            'customer_id' => Customer::factory()->create()->getKey(),
            'city_id' => City::factory()->create()->getKey(),
            'address_details' => 'شارع الجمهورية',
            'items' => [[
                'product_id' => $size->product_id,
                'product_variant_id' => $size->getKey(),
                'quantity' => '100',
                'unit_cost' => '0.5',
            ]],
        ]);

        // Assert — a typed number beside the shelf's would be a second answer to one question.
        $response->assertCreated()->assertJsonPath('data.items.0.unit_cost', null);
    }

    public function test_a_clerk_who_may_not_see_the_cost_may_not_type_one(): void
    {
        // Act
        $response = $this->take($this->clerk(), $this->stickers(), ['unit_cost' => '0.8']);

        // Assert — refused rather than dropped, so the app is never told it was kept.
        $response->assertStatus(422)->assertJsonValidationErrors('items.0.unit_cost');
        $this->assertSame(0, Order::query()->count());
    }

    // ─────────────────────────── when the order is edited ───────────────────────────

    public function test_editing_the_cost_alone_leaves_the_price_alone(): void
    {
        // Arrange
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers(), ['unit_cost' => '0.8'])->assertCreated();
        $order = Order::query()->sole();
        $item = $order->items()->sole();

        // Act — the vendor came back with a different quote; nothing else changed.
        $response = $this->withHeaders($headers)->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $order->city_id,
            'vendor_id' => $order->vendor_id,
            'items' => [[
                'id' => $item->id,
                'product_id' => $item->product_id,
                'product_variant_id' => $item->product_variant_id,
                'quantity' => '100',
                'unit_cost' => '0.9',
            ]],
        ]);

        // Assert
        $response->assertOk();
        $item->refresh();
        $this->assertSame('0.900', (string) $item->unit_cost);
        $this->assertSame('2.000', (string) $item->unit_price);
        $this->assertSame('200.00', (string) $item->line_total);
    }

    public function test_editing_the_quantity_keeps_the_cost_unless_a_new_one_is_sent(): void
    {
        // Arrange
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers(), ['unit_cost' => '0.8'])->assertCreated();
        $order = Order::query()->sole();
        $item = $order->items()->sole();

        // Act — more stickers, and the clerk said nothing about the cost.
        $this->withHeaders($headers)->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $order->city_id,
            'vendor_id' => $order->vendor_id,
            'items' => [[
                'id' => $item->id,
                'product_id' => $item->product_id,
                'product_variant_id' => $item->product_variant_id,
                'quantity' => '150',
            ]],
        ])->assertOk();

        // Assert
        $this->assertSame('0.800', (string) $item->fresh()->unit_cost);
    }

    // ─────────────────────────── when the vendor hands it over ───────────────────────────

    public function test_ready_asks_for_the_cost_of_a_line_that_has_none(): void
    {
        // Arrange — taken with no cost anywhere, and sent out.
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $this->move($headers, $order, OrderStatus::Manufacturing)->assertOk();
        $item = $order->items()->sole();

        // Act
        $box = collect($this->readyFields($headers, $order))->firstWhere('key', "unit_cost_{$item->id}");

        // Assert — required, empty, and named for the line it is about.
        $this->assertNotNull($box);
        $this->assertTrue($box['required']);
        $this->assertNull($box['value'] ?? null);
        $this->assertStringContainsString('ستيكر', $box['label']);
    }

    public function test_ready_is_refused_without_the_cost(): void
    {
        // Arrange
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $this->move($headers, $order, OrderStatus::Manufacturing)->assertOk();
        $item = $order->items()->sole();

        // Act
        $response = $this->move($headers, $order, OrderStatus::Ready);

        // Assert — on the box it is about, and the order has not moved.
        $response->assertStatus(422)->assertJsonValidationErrors("fields.unit_cost_{$item->id}");
        $this->assertSame(OrderStatus::Manufacturing, $order->fresh()->status);
    }

    public function test_the_cost_given_at_ready_becomes_the_orders_cogs_and_profit(): void
    {
        // Arrange — 100 stickers at 2.
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $this->move($headers, $order, OrderStatus::Manufacturing)->assertOk();
        $item = $order->items()->sole();

        // Act — the vendor's bill says 0.8 a piece.
        $this->move($headers, $order, OrderStatus::Ready, ["unit_cost_{$item->id}" => '0.8'])->assertOk();

        // Assert — 80 of cost against 200 of sales: the profit this whole change exists for.
        $item->refresh();
        $this->assertSame('0.800', (string) $item->unit_cost);
        $this->assertSame('80.00', (string) $item->outsourcing_cost);
        $this->assertSame('80.00', (string) $order->fresh()->total_cogs);
        $this->assertSame('120.00', $order->fresh()->grossProfit());
    }

    public function test_ready_opens_on_the_agreed_cost_and_takes_a_correction(): void
    {
        // Arrange — agreed at 0.8 when the order was taken.
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers(), ['unit_cost' => '0.8'])->assertCreated();
        $order = Order::query()->sole();
        $this->move($headers, $order, OrderStatus::Manufacturing)->assertOk();
        $item = $order->items()->sole();

        // Act — the box opens holding it; the bill came in at 0.9.
        $box = collect($this->readyFields($headers, $order))->firstWhere('key', "unit_cost_{$item->id}");
        $this->move($headers, $order, OrderStatus::Ready, ["unit_cost_{$item->id}" => '0.9'])->assertOk();

        // Assert
        $this->assertFalse($box['required']);
        $this->assertSame('0.8', $box['value']);
        $this->assertSame('90.00', (string) $item->fresh()->outsourcing_cost);
    }

    public function test_leaving_the_agreed_cost_alone_costs_the_line_at_it(): void
    {
        // Arrange
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers(), ['unit_cost' => '0.8'])->assertCreated();
        $order = Order::query()->sole();
        $this->move($headers, $order, OrderStatus::Manufacturing)->assertOk();

        // Act — no field sent: «as agreed».
        $this->move($headers, $order, OrderStatus::Ready)->assertOk();

        // Assert
        $this->assertSame('80.00', (string) $order->items()->sole()->outsourcing_cost);
    }

    public function test_somebody_without_the_grant_is_not_shown_an_agreed_cost(): void
    {
        // Arrange — agreed at 0.8 by a coordinator; received by a clerk.
        $this->take($this->coordinator(), $this->stickers(), ['unit_cost' => '0.8'])->assertCreated();
        $order = Order::query()->sole();
        $clerk = $this->clerk();
        $this->move($clerk, $order, OrderStatus::Manufacturing)->assertOk();

        // Act
        $keys = array_column($this->readyFields($clerk, $order), 'key');

        // Assert — a pre-filled box would be sending the vendor's figure to a reader the order
        // resource withholds it from.
        $this->assertNotContains("unit_cost_{$order->items()->sole()->id}", $keys);
    }

    public function test_somebody_without_the_grant_is_still_asked_for_a_missing_cost(): void
    {
        // Arrange
        $this->take($this->coordinator(), $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $clerk = $this->clerk();
        $this->move($clerk, $order, OrderStatus::Manufacturing)->assertOk();
        $item = $order->items()->sole();

        // Act — whoever holds the vendor's bill knows the number.
        $this->move($clerk, $order, OrderStatus::Ready, ["unit_cost_{$item->id}" => '0.8'])->assertOk();

        // Assert
        $this->assertSame('80.00', (string) $item->fresh()->outsourcing_cost);
    }

    public function test_the_domain_refuses_a_ready_move_that_skipped_the_form(): void
    {
        // Arrange — a caller that never went through the request: a console command, an importer.
        $this->take($this->coordinator(), $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $order->forceFill(['status' => OrderStatus::Manufacturing])->save();

        // Assert
        $this->expectException(OutsourcedLinesNeedACost::class);

        // Act
        app(ChangeOrderStatus::class)($order->fresh(), OrderStatus::Ready, actor: User::factory()->create());
    }

    public function test_an_order_of_goods_we_make_is_never_asked(): void
    {
        // Arrange — a plain line with no vendor anywhere near it, standing ready to be shelved.
        $order = Order::factory()->create(['status' => OrderStatus::New]);
        OrderItem::factory()->for($order)->create();

        // Act
        $fields = TransitionFields::for(
            $order->fresh(),
            OrderStatus::Ready,
            User::factory()->create()->givePermissionTo(PermissionName::ViewProductCost->value),
        );

        // Assert
        $this->assertEmpty(array_filter(
            $fields,
            fn ($field): bool => str_starts_with($field->key, 'unit_cost_'),
        ));
    }

    // ─────────────────── orders that went past «جاهزة» without one (§6.2) ───────────────────

    /**
     * An order taken before «جاهزة» asked for the cost: walked there with nothing, the way order
     * 1261 was. Written by hand, because the move itself now refuses to produce this state.
     */
    private function pastReadyWithoutACost(): Order
    {
        $this->take($this->coordinator(), $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $order->forceFill(['status' => OrderStatus::Ready, 'ready_at' => now()])->save();

        return $order->fresh();
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function recordCost(array $headers, Order $order, OrderItem $item, string $cost): TestResponse
    {
        return $this->withHeaders($headers)->postJson(
            "/api/v1/orders/{$order->id}/items/{$item->id}/vendor-cost",
            ['unit_cost' => $cost],
        );
    }

    public function test_the_order_names_the_lines_still_waiting_for_a_cost(): void
    {
        // Arrange
        $order = $this->pastReadyWithoutACost();
        $item = $order->items()->sole();

        // Act
        $response = $this->withHeaders($this->coordinator())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.lines_awaiting_vendor_cost', [$item->id]);
    }

    public function test_the_list_is_withheld_from_a_reader_without_the_grant(): void
    {
        // Arrange
        $order = $this->pastReadyWithoutACost();

        // Act
        $response = $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonMissingPath('data.lines_awaiting_vendor_cost');
    }

    public function test_a_late_cost_is_costed_as_ready_would_have_and_shows_the_profit(): void
    {
        // Arrange — 100 stickers at 2, never costed.
        $order = $this->pastReadyWithoutACost();
        $item = $order->items()->sole();

        // Act
        $response = $this->recordCost($this->coordinator(), $order, $item, '0.8');

        // Assert — the order comes back with its cost and its profit, and nothing left waiting.
        $response->assertOk()
            ->assertJsonPath('data.total_cogs', '80.00')
            ->assertJsonPath('data.gross_profit', '120.00')
            ->assertJsonPath('data.lines_awaiting_vendor_cost', []);
        $this->assertSame('80.00', (string) $item->fresh()->outsourcing_cost);
    }

    public function test_a_late_cost_is_recorded_once(): void
    {
        // Arrange
        $headers = $this->coordinator();
        $order = $this->pastReadyWithoutACost();
        $item = $order->items()->sole();
        $this->recordCost($headers, $order, $item, '0.8')->assertOk();

        // Act — a second figure: a correction, which is not this endpoint's to make.
        $response = $this->recordCost($headers, $order, $item, '0.9');

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('unit_cost');
        $this->assertSame('80.00', (string) $item->fresh()->outsourcing_cost);
    }

    public function test_a_late_cost_is_refused_before_ready(): void
    {
        // Arrange — still with the vendor; «جاهزة» will ask.
        $headers = $this->coordinator();
        $this->take($headers, $this->stickers())->assertCreated();
        $order = Order::query()->sole();
        $this->move($headers, $order, OrderStatus::Manufacturing)->assertOk();

        // Act
        $response = $this->recordCost($headers, $order, $order->items()->sole(), '0.8');

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('unit_cost');
    }

    public function test_a_late_cost_needs_the_cost_grant(): void
    {
        // Arrange
        $order = $this->pastReadyWithoutACost();

        // Act
        $response = $this->recordCost($this->clerk(), $order, $order->items()->sole(), '0.8');

        // Assert
        $response->assertForbidden();
        $this->assertNull($order->items()->sole()->outsourcing_cost);
    }

    public function test_a_late_cost_counts_what_the_vendor_made_not_what_the_customer_took(): void
    {
        // Arrange — the customer left 40 of the 100 on the counter; the vendor still made 100.
        $order = $this->pastReadyWithoutACost();
        $item = $order->items()->sole();
        $item->forceFill([
            'undelivered_quantity' => '40',
            'undelivered_disposition' => UndeliveredDisposition::WrittenOff,
        ])->save();

        // Act
        $this->recordCost($this->coordinator(), $order, $item, '0.8')->assertOk();

        // Assert — the quantity «جاهزة» would have multiplied out, before any delivery.
        $this->assertSame('80.00', (string) $item->fresh()->outsourcing_cost);
    }

    public function test_a_late_cost_is_refused_on_a_line_we_make_ourselves(): void
    {
        // Arrange — a printed line on an order past «جاهزة».
        $order = Order::factory()->create(['status' => OrderStatus::Ready, 'ready_at' => now()]);
        $item = OrderItem::factory()->for($order)->create();

        // Act
        $response = $this->recordCost($this->coordinator(), $order, $item, '0.8');

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('unit_cost');
    }
}
