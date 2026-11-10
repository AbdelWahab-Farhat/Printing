<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\RecalculateOrderPayments;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * A discount on an order that is already closed.
 *
 * > **«تم الاستلام» and «تم التسوية» accept a new discount and nothing else; «إلغاء تام» and
 * > «مرفوض» accept nothing.** The money already worked out from the old total is worked out
 * > again in the same save.
 *
 * Owner's decision, 2026-11-11. The end-to-end investor figure lives beside the rest of the
 * earnings arithmetic, in `InvestorDealEarningsTest`.
 *
 * Arrange - Act - Assert throughout.
 */
class ClosedOrderDiscountTest extends TestCase
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

    /** A clerk who may edit orders and discount them. */
    private function discounter(): array
    {
        return $this->auth(
            PermissionName::ViewOrders,
            PermissionName::ManageOrders,
            PermissionName::DiscountOrders,
        );
    }

    /** An order of 330.00 standing in [$status], with its one line. */
    private function orderIn(OrderStatus $status): Order
    {
        $order = Order::factory()->status($status)->create([
            'items_total' => '330.00',
            'delivery_price' => '0.00',
            'grand_total' => '330.00',
        ]);

        OrderItem::factory()->create(['order_id' => $order->getKey()]);

        return $order->refresh();
    }

    /**
     * The whole order sent back as it stands — what the app does on every save — with
     * [$changes] on top.
     *
     * @param  array<string, mixed>  $changes
     */
    private function save(array $headers, Order $order, array $changes = []): TestResponse
    {
        $echoed = array_filter([
            'city_id' => $order->city_id,
            'region_id' => $order->region_id,
            'customer_shop_id' => $order->customer_shop_id,
            'design_source' => $order->design_source->value,
            'recipient_name' => $order->recipient_name,
            'recipient_phone' => $order->recipient_phone,
            'address_details' => $order->address_details,
            'notes' => $order->notes,
            'design_fee' => (string) $order->design_fee,
            'discount' => (string) $order->discount,
            'additional_cost' => (string) $order->additional_cost,
            'tracking_number' => $order->tracking_number,
            'vendor_id' => $order->vendor_id,
            'is_urgent' => (bool) $order->is_urgent,
        ], fn (mixed $value) => $value !== null);

        return $this->withHeaders($headers)->putJson(
            "/api/v1/orders/{$order->id}",
            array_merge($echoed, $changes),
        );
    }

    // ───────────────────────────── what is accepted ─────────────────────────────

    public function test_a_delivered_order_takes_a_new_discount(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $response = $this->save($this->discounter(), $order, ['discount' => '30.00']);

        // Assert — 330.00 − 30.00, and the order stays where it was.
        $response->assertOk()
            ->assertJsonPath('data.discount', '30.00')
            ->assertJsonPath('data.grand_total', '300.00')
            ->assertJsonPath('data.status', OrderStatus::Delivered->value);
    }

    public function test_a_settled_order_takes_a_new_discount(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Settled);

        // Act
        $response = $this->save($this->discounter(), $order, ['discount' => '30.00']);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.grand_total', '300.00')
            ->assertJsonPath('data.status', OrderStatus::Settled->value);
    }

    public function test_a_discount_on_a_closed_order_still_needs_its_grant(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Delivered);
        $clerk = $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders);

        // Act
        $response = $this->save($clerk, $order, ['discount' => '30.00']);

        // Assert
        $response->assertForbidden();
        $this->assertSame('0.00', (string) $order->refresh()->discount);
    }

    // ───────────────────────────── what is refused ─────────────────────────────

    public function test_a_delivered_order_refuses_anything_beside_the_discount(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act — a discount and a note in the same save.
        $response = $this->save($this->discounter(), $order, [
            'discount' => '30.00',
            'notes' => 'ملاحظة متأخرة',
        ]);

        // Assert — refused whole, the discount with it, and the reason says what is allowed.
        $response->assertStatus(422);
        $this->assertStringContainsString('إلا الخصم', (string) $response->json('message'));
        $order->refresh();
        $this->assertSame('0.00', (string) $order->discount);
        $this->assertNull($order->notes);
    }

    public function test_a_delivered_order_refuses_its_lines(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Delivered);
        $line = $order->items()->sole();

        // Act
        $response = $this->save($this->discounter(), $order, [
            'items' => [[
                'id' => $line->getKey(),
                'product_id' => $line->product_id,
                'product_variant_id' => $line->product_variant_id,
                'quantity' => '100',
            ]],
        ]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame('300.000', (string) $line->refresh()->quantity);
    }

    public function test_a_cancelled_or_rejected_order_takes_no_discount(): void
    {
        foreach ([OrderStatus::Cancelled, OrderStatus::RequestRejected] as $status) {
            // Arrange
            $order = $this->orderIn($status);

            // Act
            $response = $this->save($this->discounter(), $order, ['discount' => '30.00']);

            // Assert
            $response->assertStatus(422);
            $this->assertSame('0.00', (string) $order->refresh()->discount, $status->value);
        }
    }

    // ───────────────────────────── the money behind it ─────────────────────────────

    public function test_a_late_discount_announces_the_profit_again(): void
    {
        // Arrange
        Event::fake([OrderProfitFinalised::class]);
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $this->save($this->discounter(), $order, ['discount' => '30.00'])->assertOk();

        // Assert
        Event::assertDispatched(
            OrderProfitFinalised::class,
            fn (OrderProfitFinalised $event) => $event->orderId === (int) $order->getKey(),
        );
    }

    public function test_an_unchanged_discount_announces_nothing(): void
    {
        // Arrange — the same save the app sends when somebody opens the screen and saves.
        Event::fake([OrderProfitFinalised::class]);
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $this->save($this->discounter(), $order)->assertOk();

        // Assert
        Event::assertNotDispatched(OrderProfitFinalised::class);
    }

    public function test_a_discount_on_an_open_order_announces_nothing(): void
    {
        // Arrange — nothing has been worked out from the total yet.
        Event::fake([OrderProfitFinalised::class]);
        $order = $this->orderIn(OrderStatus::Printing);

        // Act
        $this->save($this->discounter(), $order, ['discount' => '30.00'])->assertOk();

        // Assert
        Event::assertNotDispatched(OrderProfitFinalised::class);
    }

    public function test_a_discount_below_what_was_paid_leaves_the_order_overpaid(): void
    {
        // Arrange — paid in full, then 30 off.
        // A ledger row rather than a figure on the order: the save re-adds the ledger, and a
        // `paid_amount` with no row behind it would be added up to zero.
        $order = $this->orderIn(OrderStatus::Delivered);
        OrderPayment::factory()->create(['order_id' => $order->getKey(), 'amount' => '330.00']);
        app(RecalculateOrderPayments::class)($order);

        // Act
        $response = $this->save($this->discounter(), $order->refresh(), ['discount' => '30.00']);

        // Assert — the 30 is owed back, and the screen says so with the status it already has.
        $response->assertOk()->assertJsonPath('data.payment_status', 'overpaid');
    }

    // ───────────────────────────── what the app is told ─────────────────────────────

    public function test_the_payload_says_where_the_discount_is_open(): void
    {
        $expected = [
            OrderStatus::Printing->value => true,
            OrderStatus::OutForDelivery->value => true,
            OrderStatus::Delivered->value => true,
            OrderStatus::Settled->value => true,
            OrderStatus::Cancelled->value => false,
            OrderStatus::RequestRejected->value => false,
        ];

        $headers = $this->auth(PermissionName::ViewOrders);

        foreach ($expected as $status => $open) {
            // Arrange
            $order = $this->orderIn(OrderStatus::from($status));

            // Act
            $response = $this->withHeaders($headers)->getJson("/api/v1/orders/{$order->id}");

            // Assert
            $response->assertOk()->assertJsonPath('data.discount_is_editable', $open);
        }
    }
}
