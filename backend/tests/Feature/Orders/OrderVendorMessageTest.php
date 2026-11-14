<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Enums\CustomerMessage;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Settings\Models\CompanySetting;
use App\Domain\Vendor\Models\Vendor;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «رسالة المورد» — the text staff copy to the vendor of an outsourced order, and the switch that
 * records it was sent.
 *
 * See Docs/outsourced-products/OUTSOURCED-PRODUCTS.md §10.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderVendorMessageTest extends TestCase
{
    use RefreshDatabase;

    private const LRI = "\u{2066}";

    private const PDI = "\u{2069}";

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

    /** @return array<string, string> */
    private function sender(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::MoveOrderToManufacturing);
    }

    private function outsourcedOrder(OrderStatus $status = OrderStatus::Manufacturing): Order
    {
        return Order::factory()->create([
            'status' => $status,
            'production_flow' => OrderFlow::Outsourced,
            'vendor_id' => Vendor::factory()->create()->getKey(),
            'manufacturing_started_at' => $status === OrderStatus::Manufacturing ? now() : null,
        ]);
    }

    private function vendorText(Order $order): ?string
    {
        return $this->withHeaders($this->sender())
            ->getJson("/api/v1/orders/{$order->id}")
            ->assertOk()
            ->json('data.vendor_message_text');
    }

    // ── marking it ───────────────────────────────────────────────────────────────────────────

    public function test_it_records_who_sent_the_job_to_the_vendor_and_when(): void
    {
        // Arrange
        $order = $this->outsourcedOrder();

        // Act
        $response = $this->withHeaders($this->sender())
            ->patchJson("/api/v1/orders/{$order->id}/vendor-message", ['sent' => true]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.vendor_message_applies', true)
            ->assertJsonPath('data.is_vendor_message_sent', true);

        $order->refresh();
        $this->assertNotNull($order->vendor_message_sent_at);
        $this->assertSame($order->vendor_message_sent_by, $response->json('data.vendor_message_sent_by.id'));
    }

    public function test_it_takes_the_mark_back(): void
    {
        // Arrange
        $order = $this->outsourcedOrder(OrderStatus::New);
        $headers = $this->sender();
        $this->withHeaders($headers)->patchJson("/api/v1/orders/{$order->id}/vendor-message", ['sent' => true]);

        // Act
        $response = $this->withHeaders($headers)
            ->patchJson("/api/v1/orders/{$order->id}/vendor-message", ['sent' => false]);

        // Assert
        $response->assertOk()->assertJsonPath('data.is_vendor_message_sent', false);
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'vendor_message_sent_at' => null,
            'vendor_message_sent_by' => null,
        ]);
    }

    public function test_it_refuses_an_order_made_in_house(): void
    {
        // Arrange
        $order = Order::factory()->create(['status' => OrderStatus::Designing, 'production_flow' => OrderFlow::Standard]);

        // Act
        $response = $this->withHeaders($this->sender())
            ->patchJson("/api/v1/orders/{$order->id}/vendor-message", ['sent' => true]);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('status', false);
        $this->assertDatabaseHas('orders', ['id' => $order->id, 'vendor_message_sent_at' => null]);
    }

    public function test_it_refuses_an_outsourced_order_that_is_already_ready(): void
    {
        // Arrange — the goods are back; there is nothing left to tell the vendor.
        $order = $this->outsourcedOrder(OrderStatus::Ready);

        // Act
        $response = $this->withHeaders($this->sender())
            ->patchJson("/api/v1/orders/{$order->id}/vendor-message", ['sent' => true]);

        // Assert
        $response->assertUnprocessable();
        $this->assertDatabaseHas('orders', ['id' => $order->id, 'vendor_message_sent_at' => null]);
    }

    public function test_it_requires_the_manufacturing_grant(): void
    {
        // Arrange — the customer-messages grant is not this one.
        $order = $this->outsourcedOrder();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewOrders, PermissionName::ConfirmReadyMessage))
            ->patchJson("/api/v1/orders/{$order->id}/vendor-message", ['sent' => true]);

        // Assert
        $response->assertForbidden();
    }

    public function test_it_requires_the_sent_field(): void
    {
        // Arrange
        $order = $this->outsourcedOrder();

        // Act
        $response = $this->withHeaders($this->sender())
            ->patchJson("/api/v1/orders/{$order->id}/vendor-message", []);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('sent');
    }

    /** Moved by the real status action: a design correction means the job goes out again. */
    public function test_going_back_to_design_asks_for_a_new_message(): void
    {
        // Arrange
        $order = $this->outsourcedOrder(OrderStatus::Manufacturing);
        $order->forceFill(['vendor_message_sent_at' => now(), 'vendor_message_sent_by' => User::factory()->create()->id])->save();

        // Act
        $moved = app(ChangeOrderStatus::class)($order->refresh(), OrderStatus::Designing);

        // Assert
        $moved->refresh();
        $this->assertSame(OrderStatus::Designing, $moved->status);
        $this->assertNull($moved->vendor_message_sent_at);
        $this->assertNull($moved->vendor_message_sent_by);
    }

    public function test_moving_on_to_ready_keeps_the_mark(): void
    {
        // Arrange
        $order = $this->outsourcedOrder(OrderStatus::Manufacturing);
        $order->forceFill(['vendor_message_sent_at' => now()])->save();

        // Act
        $moved = app(ChangeOrderStatus::class)($order->refresh(), OrderStatus::Ready, actor: User::factory()->create());

        // Assert
        $this->assertNotNull($moved->refresh()->vendor_message_sent_at);
    }

    // ── the text ─────────────────────────────────────────────────────────────────────────────

    public function test_the_text_lists_every_line_and_the_inks(): void
    {
        // Arrange
        $order = $this->outsourcedOrder();
        OrderItem::factory()->for($order)->create([
            'product_name' => 'شنطة كرافت',
            'variant_label' => '25×35',
            'quantity' => '500.000',
            'pricing_unit' => PricingUnit::Piece,
            'notes' => 'يد مبرومة',
            'sort_order' => 0,
        ]);
        OrderItem::factory()->for($order)->create([
            'product_name' => 'كيس نايلون',
            'variant_label' => 'كبير',
            'quantity' => '12.500',
            'pricing_unit' => PricingUnit::Kilogram,
            'sort_order' => 1,
        ]);
        OrderDesign::factory()->approved()->for($order)->create([
            'print_colors' => [
                ['name' => 'أسود', 'code' => 'PANTONE Black C', 'hex' => '#000000'],
                ['name' => 'ذهبي', 'code' => null, 'hex' => null],
            ],
        ]);

        // Act
        $text = $this->vendorText($order);

        // Assert
        $this->assertNotNull($text);
        $this->assertStringContainsString("طلبية جديدة من دعاية رقم : [ {$order->code} ]", $text);
        $this->assertStringContainsString(
            '• شنطة كرافت — '.self::LRI.'25×35'.self::PDI.' — '.self::LRI.'500'.self::PDI.' قطعة',
            $text,
        );
        $this->assertStringContainsString('  ملاحظة : يد مبرومة', $text);
        $this->assertStringContainsString('• كيس نايلون — كبير — '.self::LRI.'12.5'.self::PDI.' كجم', $text);
        $this->assertStringContainsString('الألوان : أسود (PANTONE Black C)، ذهبي', $text);
        $this->assertStringNotContainsString(CustomerMessage::ITEMS_PLACEHOLDER, $text);
    }

    /** The vendor makes the goods; who buys them and at what price is ours. */
    public function test_the_text_carries_nothing_about_the_customer_or_money(): void
    {
        // Arrange
        $order = $this->outsourcedOrder();
        $order->forceFill(['recipient_name' => 'زبون سري', 'recipient_phone' => '0910000000'])->save();
        OrderItem::factory()->for($order)->create([
            'unit_price' => '7.250',
            'line_total' => '2175.00',
            'quantity' => '300.000',
        ]);

        // Act
        $text = (string) $this->vendorText($order);

        // Assert
        $this->assertStringNotContainsString('زبون سري', $text);
        $this->assertStringNotContainsString('0910000000', $text);
        $this->assertStringNotContainsString('7.25', $text);
        $this->assertStringNotContainsString('2175', $text);
    }

    public function test_an_order_outside_the_window_has_no_text(): void
    {
        // Arrange
        $ready = $this->outsourcedOrder(OrderStatus::Ready);
        $inHouse = Order::factory()->create(['status' => OrderStatus::New, 'production_flow' => OrderFlow::Standard]);

        // Act + Assert
        $this->assertNull($this->vendorText($ready));
        $this->assertNull($this->vendorText($inHouse));
    }

    public function test_every_status_in_the_window_has_the_text(): void
    {
        foreach (Order::vendorMessageStatuses() as $status) {
            // Arrange
            $order = $this->outsourcedOrder($status);

            // Act
            $text = $this->vendorText($order);

            // Assert
            $this->assertNotNull($text, $status->value);
        }
    }

    public function test_the_admins_wording_frames_the_server_list(): void
    {
        // Arrange
        CompanySetting::query()->findOrFail(CompanySetting::SINGLETON_ID)
            ->forceFill(['vendor_request_message' => "طلب {رقم_الفاتورة}\n{الأصناف}\nشكراً"])
            ->save();
        $order = $this->outsourcedOrder();
        OrderItem::factory()->for($order)->create(['product_name' => 'علبة', 'variant_label' => '', 'quantity' => '200.000']);

        // Act
        $text = $this->vendorText($order);

        // Assert
        $this->assertSame("طلب {$order->code}\n• علبة — ".self::LRI.'200'.self::PDI." قطعة\nشكراً", $text);
    }

    public function test_the_admin_saves_the_vendor_text_from_settings(): void
    {
        // Arrange
        $headers = $this->auth(PermissionName::ViewCompanySettings, PermissionName::ManageCompanySettings);

        // Act
        $response = $this->withHeaders($headers)->putJson('/api/v1/settings/customer-messages', [
            'messages' => ['vendor_request' => 'طلب {رقم_الفاتورة} {الأصناف}'],
        ]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('message', 'تم حفظ نصوص الرسائل')
            ->assertJsonPath('data.messages.4.is_customised', true);
        $this->assertDatabaseHas('company_settings', [
            'id' => CompanySetting::SINGLETON_ID,
            'vendor_request_message' => 'طلب {رقم_الفاتورة} {الأصناف}',
        ]);
    }
}
