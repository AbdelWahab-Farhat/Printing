<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Delivery\Models\ShippingCompany;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Enums\DeliveryPayer;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\ResendFromPickupNeedsADeliveryCity;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * An order waiting at the counter whose customer asks for delivery instead.
 *
 * «استلام مكتب» → «إعادة إرسال» carries the new delivery city, and the order leaves from there
 * like any re-send: to Nawris, or with our courier. The edit form refuses to make the same change
 * on its own, so the order can never sit at the counter as a delivery. See ORDERS-DESIGN.md
 * «من استلام مكتب إلى توصيل».
 *
 * Arrange - Act - Assert throughout.
 */
class OrderPickupToDeliveryTest extends TestCase
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
    private function clerk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewOrders->value,
            PermissionName::ManageOrders->value,
            PermissionName::ResendOrders->value,
            PermissionName::DispatchOrders->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function atTheCounter(array $attributes = []): Order
    {
        return Order::factory()->officePickup()->status(OrderStatus::OfficePickup)->create([
            'address_details' => 'الفرع',
            ...$attributes,
        ]);
    }

    /**
     * @param  array<string, mixed>  $fields
     */
    private function sendOut(array $headers, Order $order, array $fields): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Resend->value,
            'fields' => $fields,
        ]);
    }

    /** @return array<string, mixed>|null */
    private function resendOffer(array $headers, Order $order): ?array
    {
        $transitions = $this->withHeaders($headers)
            ->getJson("/api/v1/orders/{$order->id}")
            ->json('data.available_transitions');

        foreach ($transitions as $transition) {
            if ($transition['status'] === OrderStatus::Resend->value) {
                return $transition;
            }
        }

        return null;
    }

    // ── what the move asks for ──────────────────────────────────────────────────────────

    public function test_the_counter_offers_a_resend_that_asks_where_to_deliver(): void
    {
        // Arrange
        $order = $this->atTheCounter();

        // Act
        $offer = $this->resendOffer($this->clerk(), $order);

        // Assert — the city is required; the street opens on what the order already says.
        $this->assertNotNull($offer);

        $fields = collect($offer['fields'])->keyBy('key');

        $this->assertSame('destination', $fields['destination']['type']);
        $this->assertTrue($fields['destination']['required']);
        $this->assertSame('الفرع', $fields['address_details']['value']);
    }

    public function test_a_resend_from_the_carriers_depot_asks_for_no_destination(): void
    {
        // Arrange — the old road into «إعادة إرسال» keeps the address it has.
        $order = Order::factory()->status(OrderStatus::ReturnedOffice)->create();

        // Act
        $offer = $this->resendOffer($this->clerk(), $order);

        // Assert
        $keys = array_column($offer['fields'], 'key');
        $this->assertNotContains('destination', $keys);
        $this->assertNotContains('address_details', $keys);
    }

    // ── the move ────────────────────────────────────────────────────────────────────────

    public function test_the_order_becomes_a_delivery_with_the_move(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $city = City::factory()->requiringRegion()->create(['name' => 'جنزور', 'delivery_price' => '15.00']);
        $region = Region::factory()->create(['city_id' => $city->id, 'name' => 'الغيران']);

        // Act
        $response = $this->sendOut($this->clerk(), $order, [
            'destination' => ['city_id' => $city->id, 'region_id' => $region->id],
            'address_details' => 'قرب الجامع',
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'resend');

        $moved = $order->fresh();
        $this->assertSame(OrderStatus::Resend, $moved->status);
        $this->assertSame($city->id, $moved->city_id);
        $this->assertSame($region->id, $moved->region_id);
        $this->assertSame('جنزور', $moved->city_name);
        $this->assertSame('الغيران', $moved->region_name);
        $this->assertSame(FulfilmentType::Delivery, $moved->fulfilment_type);
        $this->assertSame('15.00', (string) $moved->delivery_price);
        $this->assertSame('قرب الجامع', $moved->address_details);
    }

    public function test_from_resend_it_goes_out_for_delivery_not_back_to_the_counter(): void
    {
        // Arrange
        $headers = $this->clerk();
        $order = $this->atTheCounter();
        $city = City::factory()->create();
        $this->sendOut($headers, $order, ['destination' => ['city_id' => $city->id]])->assertOk();

        // Act — the clerk says «it is going out»; the new city decides which way that is.
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::OutForDelivery->value,
            'fields' => ['shipping_company_id' => ShippingCompany::factory()->create()->id],
        ]);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'out_for_delivery');
    }

    public function test_an_empty_street_clears_the_branch_address(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $city = City::factory()->create();

        // Act
        $this->sendOut($this->clerk(), $order, [
            'destination' => ['city_id' => $city->id],
            'address_details' => '',
        ])->assertOk();

        // Assert
        $this->assertNull($order->fresh()->address_details);
    }

    public function test_the_delivery_cost_follows_the_new_city_when_we_pay_the_courier(): void
    {
        // Arrange
        $order = $this->atTheCounter(['delivery_paid_by' => DeliveryPayer::Us]);
        $city = City::factory()->create(['delivery_price' => '25.00']);

        // Act
        $this->sendOut($this->clerk(), $order, ['destination' => ['city_id' => $city->id]])->assertOk();

        // Assert — the branch cost nothing to reach; the door costs the city's rate.
        $this->assertSame('25.00', (string) $order->fresh()->delivery_cost);
    }

    // ── what is refused ─────────────────────────────────────────────────────────────────

    public function test_the_move_is_refused_without_a_city(): void
    {
        // Arrange
        $order = $this->atTheCounter();

        // Act
        $response = $this->sendOut($this->clerk(), $order, []);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.destination');
        $this->assertSame(OrderStatus::OfficePickup, $order->fresh()->status);
    }

    public function test_a_branch_is_not_a_delivery_city(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $branch = City::factory()->officePickup()->create();

        // Act
        $response = $this->sendOut($this->clerk(), $order, ['destination' => ['city_id' => $branch->id]]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('fields.destination.city_id');
        $this->assertSame(OrderStatus::OfficePickup, $order->fresh()->status);
    }

    public function test_a_city_that_needs_a_region_refuses_the_move_and_leaves_the_order_at_the_counter(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $branchId = $order->city_id;
        $city = City::factory()->requiringRegion()->create();

        // Act
        $response = $this->sendOut($this->clerk(), $order, ['destination' => ['city_id' => $city->id]]);

        // Assert — nothing half-written: still at the counter, still the branch.
        $response->assertStatus(422);

        $unchanged = $order->fresh();
        $this->assertSame(OrderStatus::OfficePickup, $unchanged->status);
        $this->assertSame($branchId, $unchanged->city_id);
        $this->assertSame(FulfilmentType::OfficePickup, $unchanged->fulfilment_type);
    }

    public function test_a_region_of_another_city_is_refused(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $city = City::factory()->create();
        $elsewhere = Region::factory()->create(['city_id' => City::factory()->create()->id]);

        // Act
        $response = $this->sendOut($this->clerk(), $order, [
            'destination' => ['city_id' => $city->id, 'region_id' => $elsewhere->id],
        ]);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::OfficePickup, $order->fresh()->status);
    }

    public function test_the_domain_refuses_the_move_without_a_city_for_callers_that_skip_the_request(): void
    {
        // Arrange
        $order = $this->atTheCounter();

        // Assert
        $this->expectException(ResendFromPickupNeedsADeliveryCity::class);

        // Act
        app(ChangeOrderStatus::class)($order->fresh(), OrderStatus::Resend, actor: User::factory()->create());
    }

    // ── Nawris ──────────────────────────────────────────────────────────────────────────

    public function test_after_the_move_nawris_gets_a_new_parcel_and_its_pickup_moves_the_order(): void
    {
        // Arrange — a mapped city, a carrier that accepts, and 30 of 100 already paid at the
        // branch.
        config()->set('services.nawris.authentication_key', 'key');
        config()->set('services.nawris.main_client_code', 'client');
        config()->set('services.nawris.base_url', 'https://carrier.test/external-api/');
        config()->set('services.nawris.log_channel', 'null');
        config()->set('services.nawris.webhook_secret', 'shared-secret');
        config()->set('services.nawris.webhook_ips', []);
        Http::fake(['*' => Http::response([
            'success' => 1,
            'result' => ['code' => '4100', 'bar_code' => 'B-9'],
        ], 200)]);

        $headers = $this->clerk();
        User::query()->latest('id')->firstOrFail()->givePermissionTo(PermissionName::ManageCarrierParcels->value);

        $order = $this->atTheCounter([
            'items_total' => '100.00',
            'grand_total' => '100.00',
            'paid_amount' => '30.00',
        ]);
        $city = City::factory()->create(['nawris_government_id' => '5']);
        $region = Region::factory()->create(['city_id' => $city->id, 'nawris_area_id' => '204']);

        $this->sendOut($headers, $order, [
            'destination' => ['city_id' => $city->id, 'region_id' => $region->id],
        ])->assertOk();

        // Act — «إرسال للنورس» from the order screen: the endpoint the app's button calls.
        $lodged = $this->withHeaders($headers)->postJson("/api/v1/carrier/orders/{$order->id}/lodge");

        // Assert — a new parcel, linked to this order, sent to the new city for what is still owed.
        $lodged->assertCreated();

        $parcel = NawrisParcel::query()->sole();
        $this->assertSame('4100', $parcel->code);
        $this->assertTrue(
            NawrisParcelOrder::query()
                ->where('nawris_parcel_id', $parcel->id)
                ->where('order_id', $order->id)
                ->exists(),
        );

        Http::assertSent(fn ($request) => $request->data()['government'] === '5'
            && $request->data()['area'] === '204'
            && (float) $request->data()['amount_to_be_collected'] === 70.0);

        // Lodging moves no status: the order waits at «إعادة إرسال» for the courier.
        $this->assertSame(OrderStatus::Resend, $order->fresh()->status);

        // Act — Nawris reports their courier holding it (code 3).
        $this->withHeaders(['Authorization' => 'Bearer shared-secret'])
            ->postJson('/api/v1/webhooks/nawris', [
                'remote_order_id' => $parcel->reference,
                'order_code' => '4100',
                'to_status_code' => 3,
                'to_status_text' => 'في الشركة',
                'order_price' => null,
            ])
            ->assertOk();

        // Assert
        $this->assertSame(OrderStatus::OutForDelivery, $order->fresh()->status);
    }

    public function test_a_second_send_to_nawris_is_refused_while_the_first_parcel_is_open(): void
    {
        // Arrange
        config()->set('services.nawris.authentication_key', 'key');
        config()->set('services.nawris.main_client_code', 'client');
        config()->set('services.nawris.base_url', 'https://carrier.test/external-api/');
        config()->set('services.nawris.log_channel', 'null');
        Http::fake(['*' => Http::response([
            'success' => 1,
            'result' => ['code' => '4100', 'bar_code' => 'B-9'],
        ], 200)]);

        $headers = $this->clerk();
        User::query()->latest('id')->firstOrFail()->givePermissionTo(PermissionName::ManageCarrierParcels->value);

        $order = $this->atTheCounter();
        $city = City::factory()->create(['nawris_government_id' => '5']);
        $this->sendOut($headers, $order, ['destination' => ['city_id' => $city->id]])->assertOk();
        $this->withHeaders($headers)->postJson("/api/v1/carrier/orders/{$order->id}/lodge")->assertCreated();

        // Act — a double tap.
        $again = $this->withHeaders($headers)->postJson("/api/v1/carrier/orders/{$order->id}/lodge");

        // Assert — one parcel, not two.
        $again->assertStatus(422);
        $this->assertSame(1, NawrisParcel::query()->count());
    }

    // ── the edit form ───────────────────────────────────────────────────────────────────

    public function test_the_edit_form_refuses_a_delivery_city_while_the_order_waits_at_the_counter(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $city = City::factory()->create();

        // Act
        $response = $this->withHeaders($this->clerk())->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $city->id,
        ]);

        // Assert — the move is the way, and the refusal names it.
        $response->assertStatus(422)->assertJsonValidationErrors('city_id');
        $this->assertStringContainsString('إعادة إرسال', $response->json('errors.city_id.0'));
        $this->assertSame(FulfilmentType::OfficePickup, $order->fresh()->fulfilment_type);
    }

    public function test_the_edit_form_still_moves_the_order_to_another_branch(): void
    {
        // Arrange
        $order = $this->atTheCounter();
        $other = City::factory()->officePickup()->create();

        // Act
        $response = $this->withHeaders($this->clerk())->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $other->id,
        ]);

        // Assert
        $response->assertOk();
        $this->assertSame($other->id, $order->fresh()->city_id);
    }

    public function test_an_order_already_stuck_as_a_delivery_at_the_counter_can_still_be_edited(): void
    {
        // Arrange — made before the rule: a delivery city on an order still at the counter.
        $city = City::factory()->create();
        $order = $this->atTheCounter([
            'city_id' => $city->id,
            'fulfilment_type' => FulfilmentType::Delivery,
        ]);

        // Act — the city comes back unchanged, so this is not the change the rule refuses.
        $response = $this->withHeaders($this->clerk())->putJson("/api/v1/orders/{$order->id}", [
            'city_id' => $city->id,
            'notes' => 'يتصل قبل الوصول',
        ]);

        // Assert
        $response->assertOk();
        $this->assertSame('يتصل قبل الوصول', $order->fresh()->notes);
    }
}
