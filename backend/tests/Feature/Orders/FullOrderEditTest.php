<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Delivery\Models\ShippingCompany;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\DeliveryPayer;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * `orders.edit_fully`: every field, in any status.
 *
 * > The grant lifts the status locks and opens the fields nothing else edits once they are set.
 * > It does not lift the discount's own grant, and it reworks the money of a closed order.
 *
 * Owner's decision, 2026-11-24. See ORDER-EDIT-ANY-STATUS.md.
 *
 * Arrange - Act - Assert throughout.
 */
class FullOrderEditTest extends TestCase
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

    /** A clerk who may edit orders, but not fully. */
    private function clerk(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders);
    }

    /** Somebody holding the new grant on top of the ordinary edit. */
    private function fullEditor(PermissionName ...$extra): array
    {
        return $this->auth(
            PermissionName::ViewOrders,
            PermissionName::ManageOrders,
            PermissionName::EditOrdersFully,
            ...$extra,
        );
    }

    private function orderIn(OrderStatus $status): Order
    {
        $order = Order::factory()->status($status)->create([
            'items_total' => '330.00',
            'delivery_price' => '20.00',
            'grand_total' => '330.00',
        ]);

        OrderItem::factory()->create(['order_id' => $order->getKey()]);

        return $order->refresh();
    }

    /**
     * The whole order sent back as it stands, with [$changes] on top — what the app does.
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

    // ───────────────────────────── the locks it lifts ─────────────────────────────

    public function test_a_delivered_order_takes_new_notes_and_a_new_phone(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $response = $this->save($this->fullEditor(), $order, [
            'notes' => 'مصحّحة بعد الاستلام',
            'recipient_phone' => '0919999999',
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.notes', 'مصحّحة بعد الاستلام')
            ->assertJsonPath('data.recipient_phone', '0919999999')
            ->assertJsonPath('data.status', OrderStatus::Delivered->value);
    }

    public function test_a_cancelled_order_is_editable_too(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::Cancelled);

        // Act
        $response = $this->save($this->fullEditor(), $order, ['notes' => 'سبب الإلغاء موضّح']);

        // Assert
        $response->assertOk()->assertJsonPath('data.notes', 'سبب الإلغاء موضّح');
    }

    public function test_without_the_grant_a_delivered_order_still_takes_only_a_discount(): void
    {
        // Arrange — the clerk's rule is untouched.
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $response = $this->save($this->clerk(), $order, ['notes' => 'محاولة']);

        // Assert
        $response->assertStatus(422);
        $this->assertNotSame('محاولة', $order->refresh()->notes);
    }

    public function test_the_discount_still_asks_for_its_own_grant(): void
    {
        // Arrange — the full edit lifts locks, not the money grants.
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $response = $this->save($this->fullEditor(), $order, ['discount' => '30.00']);

        // Assert
        $response->assertForbidden();
        $this->assertSame('0.00', (string) $order->refresh()->discount);
    }

    // ───────────────────────────── the new fields ─────────────────────────────

    public function test_the_new_fields_are_written(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::OutForDelivery);
        $company = ShippingCompany::factory()->create(['name' => 'شركة الاختبار']);

        // Act
        $response = $this->save($this->fullEditor(), $order, [
            'delivery_price' => '35.00',
            'shipping_company_id' => $company->getKey(),
            'courier_name' => 'سالم',
            'courier_phone' => '0921234567',
            'deposit_expected_amount' => '100.00',
            'placed_at' => '2026-11-01 10:00:00',
        ]);

        // Assert — the company is snapshotted with its name.
        $response->assertOk()
            ->assertJsonPath('data.delivery_price', '35.00')
            ->assertJsonPath('data.shipping_company_id', $company->getKey())
            ->assertJsonPath('data.shipping_company', 'شركة الاختبار')
            ->assertJsonPath('data.courier_name', 'سالم')
            ->assertJsonPath('data.courier_phone', '0921234567');

        $order->refresh();
        $this->assertSame('100.00', (string) $order->deposit_expected_amount);
        $this->assertSame('2026-11-01', $order->placed_at?->toDateString());
    }

    public function test_without_the_grant_the_new_fields_are_refused_not_dropped(): void
    {
        // Arrange
        $order = $this->orderIn(OrderStatus::New);

        // Act
        $response = $this->save($this->clerk(), $order, ['delivery_price' => '99.00']);

        // Assert — a figure silently not saved would read as saved.
        $response->assertStatus(422)->assertJsonValidationErrors('delivery_price');
        $this->assertSame('20.00', (string) $order->refresh()->delivery_price);
    }

    public function test_a_typed_delivery_price_survives_the_next_ordinary_edit(): void
    {
        // Arrange — the city's rate used to be copied again on every save.
        $order = $this->orderIn(OrderStatus::New);
        $this->save($this->fullEditor(), $order, ['delivery_price' => '45.00'])->assertOk();

        // Act — a clerk corrects the notes without touching the city.
        $response = $this->save($this->clerk(), $order->refresh(), ['notes' => 'ملاحظة']);

        // Assert
        $response->assertOk()->assertJsonPath('data.delivery_price', '45.00');
    }

    public function test_a_typed_delivery_cost_is_kept_and_null_hands_it_back(): void
    {
        // Arrange — we pay the courier, so the cost is ours to record.
        $order = $this->orderIn(OrderStatus::New);
        $order->forceFill(['delivery_paid_by' => DeliveryPayer::Us])->save();

        // Act
        $typed = $this->save($this->fullEditor(), $order->refresh(), ['delivery_cost' => '12.00']);
        $cleared = $this->save($this->fullEditor(), $order->refresh(), ['delivery_cost' => null]);

        // Assert — typed wins, then null goes back to the price.
        $typed->assertOk()
            ->assertJsonPath('data.delivery_cost', '12.00')
            ->assertJsonPath('data.delivery_cost_override', '12.00');
        $cleared->assertOk()
            ->assertJsonPath('data.delivery_cost', '20.00')
            ->assertJsonPath('data.delivery_cost_override', null);
    }

    // ───────────────────────────── the money ─────────────────────────────

    public function test_a_full_edit_of_a_delivered_order_reworks_its_money(): void
    {
        // Arrange
        Event::fake([OrderProfitFinalised::class]);
        $order = $this->orderIn(OrderStatus::Delivered);

        // Act
        $this->save($this->fullEditor(), $order, ['notes' => 'تعديل'])->assertOk();

        // Assert
        Event::assertDispatched(OrderProfitFinalised::class);
    }

    public function test_a_full_edit_of_a_cancelled_order_shares_out_no_profit(): void
    {
        // Arrange
        Event::fake([OrderProfitFinalised::class]);
        $order = $this->orderIn(OrderStatus::Cancelled);

        // Act
        $this->save($this->fullEditor(), $order, ['notes' => 'تعديل'])->assertOk();

        // Assert
        Event::assertNotDispatched(OrderProfitFinalised::class);
    }
}
