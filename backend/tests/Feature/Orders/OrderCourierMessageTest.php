<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\CustomerMessage;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Settings\Models\CompanySetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * «رسالة المندوب» — the courier's number and the parcel code, copied to the customer so they can
 * ring the courier themselves. Copy only: no switch, no queue.
 *
 * See Docs/nawris/NAWRIS-INTEGRATION.md §5.5.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderCourierMessageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /** @return array<string, string> */
    private function viewer(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(PermissionName::ViewOrders->value);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /** @param  array<string, mixed>  $attributes */
    private function order(array $attributes = []): Order
    {
        return Order::factory()->create(array_merge([
            'status' => OrderStatus::OutForDelivery,
            'dispatched_at' => now()->subHour(),
            'courier_phone' => '0944112145',
        ], $attributes));
    }

    private function inParcel(Order $order, string $code): void
    {
        $parcel = NawrisParcel::factory()->create(['code' => $code]);

        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $order->id,
        ]);
    }

    public function test_the_text_carries_the_invoice_the_courier_and_the_parcel_code(): void
    {
        // Arrange
        $order = $this->order();
        $this->inParcel($order, '4600741');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $text = $response->assertOk()->json('data.courier_message_text');
        $this->assertIsString($text);
        $this->assertStringContainsString("[ {$order->code} ]", $text);
        $this->assertStringContainsString('رقم المندوب : 0944112145', $text);
        $this->assertStringContainsString('كود الشحنة : 4600741', $text);
        $this->assertStringNotContainsString('{', $text);
    }

    public function test_the_list_carries_it_too(): void
    {
        // Arrange — the card copies it, so the page of orders must carry it with the parcel code.
        $order = $this->order();
        $this->inParcel($order, '4600741');

        // Act
        $response = $this->withHeaders($this->viewer())->getJson('/api/v1/orders');

        // Assert
        $row = collect($response->assertOk()->json('data'))->firstWhere('id', $order->id);
        $this->assertNotNull($row);
        $this->assertStringContainsString('كود الشحنة : 4600741', (string) $row['courier_message_text']);
    }

    public function test_without_a_parcel_the_typed_tracking_number_is_the_code(): void
    {
        // Arrange — dispatched by hand with another company.
        $order = $this->order(['tracking_number' => 'TRK-55']);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $this->assertStringContainsString('كود الشحنة : TRK-55', (string) $response->json('data.courier_message_text'));
    }

    public function test_there_is_no_text_without_a_courier(): void
    {
        // Arrange
        $order = $this->order(['courier_phone' => null]);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.courier_message_text', null);
    }

    public function test_there_is_no_text_once_the_customer_has_the_bags(): void
    {
        // Arrange
        $order = $this->order(['status' => OrderStatus::Delivered]);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson("/api/v1/orders/{$order->id}");

        // Assert — the number stays on the order; only the message goes.
        $response->assertOk()
            ->assertJsonPath('data.courier_phone', '0944112145')
            ->assertJsonPath('data.courier_message_text', null);
    }

    public function test_the_admin_wording_is_used(): void
    {
        // Arrange
        CompanySetting::query()->findOrFail(CompanySetting::SINGLETON_ID)
            ->forceFill(['courier_contact_message' => 'طلبية {رقم_الفاتورة} — المندوب {رقم_المندوب} — {كود_الشحنة}'])
            ->save();
        $order = $this->order(['tracking_number' => 'TRK-55']);

        // Act
        $response = $this->withHeaders($this->viewer())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath(
            'data.courier_message_text',
            "طلبية {$order->code} — المندوب 0944112145 — TRK-55",
        );
    }

    public function test_the_default_names_all_three_placeholders(): void
    {
        // Act
        $body = CustomerMessage::CourierContact->defaultBody();

        // Assert
        foreach (CustomerMessage::CourierContact->placeholders() as $placeholder) {
            $this->assertStringContainsString($placeholder, $body);
        }
    }
}
