<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Carrier\Actions\ReadNawrisParcelTerms;
use App\Domain\Carrier\CarrierService;
use App\Domain\Carrier\Exceptions\OrdersCannotShareAParcel;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\DeliveryPayer;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\Support\GivesPrintableArtwork;
use Tests\TestCase;

/**
 * «التوصيل على: المستلم / علينا» — Docs/orders/DELIVERY-PAYER.md.
 *
 * The arithmetic throughout: an order of 100 whose goods cost 60, to a city whose delivery rate is
 * 20. Recipient pays → profit 40. We pay → the 20 is the order's cost and profit is 20 (option B).
 *
 * `Http::fake()` wherever Nawris could be reached — no test reaches the carrier.
 *
 * Arrange - Act - Assert throughout.
 */
class DeliveryPayerTest extends TestCase
{
    use GivesPrintableArtwork;
    use RefreshDatabase;

    private const SECRET = 'shared-secret';

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        config()->set('services.nawris.authentication_key', 'key');
        config()->set('services.nawris.main_client_code', 'client');
        config()->set('services.nawris.base_url', 'https://carrier.test/external-api/');
        config()->set('services.nawris.log_channel', 'null');
        config()->set('services.nawris.webhook_secret', self::SECRET);
        config()->set('services.nawris.webhook_ips', []);
    }

    // ── helpers ──────────────────────────────────────────────────────────────────────────

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
    private function clerk(): array
    {
        return $this->auth(PermissionName::ViewOrders, PermissionName::ManageOrders);
    }

    /** @return array<string, string> */
    private function settler(): array
    {
        return $this->auth(
            PermissionName::ViewOrders,
            PermissionName::ManageOrders,
            PermissionName::SettleOrders,
            PermissionName::UnsettleOrders,
            PermissionName::ViewOrderPayments,
        );
    }

    private function nawrisCity(): City
    {
        return City::factory()->create([
            'fulfilment_type' => FulfilmentType::Delivery,
            'nawris_government_id' => '5',
            'delivery_price' => '20.00',
        ]);
    }

    /**
     * An order of 100, goods costing 60, to a Nawris city at a rate of 20.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function order(OrderStatus $status = OrderStatus::OutForDelivery, array $overrides = []): Order
    {
        $city = $this->nawrisCity();

        return Order::factory()->create(array_merge([
            'status' => $status,
            'city_id' => $city->id,
            'city_name' => $city->name,
            'fulfilment_type' => FulfilmentType::Delivery,
            'items_total' => '100.00',
            'delivery_price' => '20.00',
            'grand_total' => '100.00',
            'total_cogs' => '60.00',
        ], $overrides))->refresh();
    }

    /**
     * An open parcel holding these orders, asking 100 each.
     *
     * @param  list<Order>  $orders
     */
    private function parcel(array $orders, int $payer = 1, string $code = 'CODE-1'): NawrisParcel
    {
        $parcel = NawrisParcel::factory()->create([
            'reference' => 'ref-'.$code,
            'code' => $code,
            'amount_to_collect' => (string) (100 * count($orders)).'.00',
            'delivery_price_deducted' => '0.00',
            'government' => '5',
            'area' => '204',
            'shipment_on_sender' => $payer,
            'payer_at_dispatch' => $payer,
        ]);

        foreach ($orders as $order) {
            NawrisParcelOrder::factory()->create([
                'nawris_parcel_id' => $parcel->id,
                'order_id' => $order->id,
                'amount_to_collect' => '100.00',
            ]);
        }

        return $parcel;
    }

    private function change(array $headers, Order $order, DeliveryPayer $payer): TestResponse
    {
        return $this->withHeaders($headers)->patchJson("/api/v1/orders/{$order->id}/delivery-payer", [
            'delivery_paid_by' => $payer->value,
        ]);
    }

    /**
     * @param  array<string, mixed>  $body
     */
    private function webhook(string $code, array $body): void
    {
        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])
            ->postJson('/api/v1/webhooks/nawris', array_merge(['remote_order_id' => 'ref-'.$code, 'order_code' => $code], $body))
            ->assertOk();
    }

    private function nawrisAccepts(): void
    {
        Http::fake(['*' => Http::response(['success' => 1, 'result' => ['code' => 'CODE-1', 'bar_code' => 'B-1']], 200)]);
    }

    private function nawrisRefuses(): void
    {
        Http::fake(['*' => Http::response(['success' => 0, 'error_msg' => 'لا يمكن تعديل شحنة مع المندوب'], 200)]);
    }

    // ── taking an order ──────────────────────────────────────────────────────────────────

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function payload(array $overrides = []): array
    {
        $product = Product::factory()->create(['pricing_mode' => PricingMode::Tiered, 'min_order_quantity' => '100']);
        $variant = ProductVariant::factory()->create(['product_id' => $product->getKey(), 'label' => '25*35']);
        ProductPriceTier::factory()->create(['product_variant_id' => $variant->getKey(), 'min_quantity' => '100', 'unit_price' => '1.100']);
        $customer = Customer::factory()->create();

        return array_merge([
            'customer_id' => $customer->getKey(),
            'city_id' => City::factory()->create(['delivery_price' => '20.00'])->getKey(),
            'address_details' => 'شارع الجمهورية',
            'items' => [[
                'product_id' => $variant->product_id,
                'product_variant_id' => $variant->getKey(),
                'quantity' => '300',
            ]],
            'design_ids' => [$this->printableDesignId((int) $customer->getKey())],
        ], $overrides);
    }

    public function test_a_new_order_leaves_delivery_on_the_recipient(): void
    {
        // Act
        $response = $this->withHeaders($this->clerk())->postJson('/api/v1/orders', $this->payload());

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.delivery_paid_by', 'recipient')
            ->assertJsonPath('data.delivery_cost', '0.00');
    }

    public function test_an_order_taken_with_delivery_on_us_costs_us_the_city_rate(): void
    {
        // Act
        $response = $this->withHeaders($this->clerk())
            ->postJson('/api/v1/orders', $this->payload(['delivery_paid_by' => 'us']));

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.delivery_paid_by', 'us')
            ->assertJsonPath('data.delivery_cost', '20.00');
    }

    // ── changing it ──────────────────────────────────────────────────────────────────────

    public function test_delivery_on_us_comes_out_of_the_order_s_profit(): void
    {
        // Arrange — no parcel: a delivery by our own courier
        $order = $this->order(OrderStatus::Ready);

        // Act
        $response = $this->change($this->clerk(), $order, DeliveryPayer::Us);

        // Assert — 100 − 60 − 20
        $response->assertOk()
            ->assertJsonPath('data.order.delivery_paid_by', 'us')
            ->assertJsonPath('data.order.delivery_cost', '20.00')
            ->assertJsonPath('data.order.gross_profit', '20.00')
            ->assertJsonPath('data.carrier', null);
    }

    public function test_back_on_the_recipient_the_cost_leaves_the_order(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::Ready, ['delivery_paid_by' => 'us', 'delivery_cost' => '20.00']);

        // Act
        $response = $this->change($this->clerk(), $order, DeliveryPayer::Recipient);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.order.delivery_cost', '0.00')
            ->assertJsonPath('data.order.gross_profit', '40.00');
    }

    public function test_it_may_still_change_while_the_courier_has_it(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::OutForDelivery);

        // Act
        $response = $this->change($this->clerk(), $order, DeliveryPayer::Us);

        // Assert
        $response->assertOk();
        $this->assertSame(DeliveryPayer::Us, $order->fresh()->delivery_paid_by);
    }

    public function test_once_delivered_it_is_refused(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::Delivered);

        // Act
        $response = $this->change($this->clerk(), $order, DeliveryPayer::Us);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors('delivery_paid_by');
        $this->assertSame(DeliveryPayer::Recipient, $order->fresh()->delivery_paid_by);
    }

    public function test_it_needs_the_grant_to_change_an_order(): void
    {
        // Arrange
        $order = $this->order();

        // Act
        $response = $this->change($this->auth(PermissionName::ViewOrders), $order, DeliveryPayer::Us);

        // Assert
        $response->assertForbidden();
    }

    public function test_the_order_warns_before_the_switch_what_it_will_do(): void
    {
        // Arrange — out with the courier, no Nawris parcel
        $order = $this->order(OrderStatus::OutForDelivery);

        // Act
        $response = $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.can_change_delivery_payer', true);
        $warnings = implode(' ', $response->json('data.delivery_payer_warnings'));
        $this->assertStringContainsString('ويتحمّل المستثمرون حصتهم', $warnings);
        $this->assertStringContainsString('20.00', $warnings);
        $this->assertStringContainsString('النظام لا يبلغ المندوب', $warnings);
    }

    public function test_a_city_without_a_rate_warns_the_cost_is_not_known(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::Ready, ['delivery_price' => '0.00']);

        // Act
        $response = $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $this->assertStringContainsString('لا سعر توصيل لهذه المدينة', implode(' ', $response->json('data.delivery_payer_warnings')));
    }

    public function test_a_delivered_order_offers_no_switch(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::Delivered);

        // Act
        $response = $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertJsonPath('data.can_change_delivery_payer', false)
            ->assertJsonPath('data.delivery_payer_warnings', []);
    }

    // ── Nawris ───────────────────────────────────────────────────────────────────────────

    public function test_dispatch_tells_nawris_we_pay_when_the_order_says_so(): void
    {
        // Arrange
        $this->nawrisAccepts();
        $city = $this->nawrisCity();
        $region = Region::factory()->create(['city_id' => $city->id, 'nawris_area_id' => '204']);
        $order = Order::factory()->create([
            'status' => OrderStatus::Ready,
            'city_id' => $city->id,
            'region_id' => $region->id,
            'city_name' => $city->name,
            'fulfilment_type' => FulfilmentType::Delivery,
            'items_total' => '100.00',
            'delivery_price' => '20.00',
            'grand_total' => '100.00',
            'delivery_paid_by' => 'us',
            'delivery_cost' => '20.00',
        ]);

        // Act
        $parcel = app(CarrierService::class)->dispatchOrder($order->refresh());

        // Assert — their API's 1; their webhooks' 2
        Http::assertSent(fn ($request) => (int) $request->data()['shipment_on_sender'] === 1);
        $this->assertSame(2, $parcel->payer_at_dispatch);
        $this->assertSame(2, $parcel->shipment_on_sender);
    }

    public function test_orders_with_different_payers_cannot_share_a_parcel(): void
    {
        // Arrange
        $this->nawrisAccepts();
        $first = $this->order(OrderStatus::Ready);
        $second = Order::factory()->create([
            'status' => OrderStatus::Ready,
            'customer_id' => $first->customer_id,
            'city_id' => $first->city_id,
            'region_id' => $first->region_id,
            'city_name' => $first->city_name,
            'recipient_phone' => $first->recipient_phone,
            'fulfilment_type' => FulfilmentType::Delivery,
            'items_total' => '100.00',
            'grand_total' => '100.00',
            'delivery_paid_by' => 'us',
        ])->refresh();

        // Assert
        $this->expectException(OrdersCannotShareAParcel::class);

        // Act
        app(CarrierService::class)->dispatchGroup([$first, $second]);
    }

    public function test_changing_it_on_a_parcel_out_tells_nawris(): void
    {
        // Arrange
        $this->nawrisAccepts();
        $order = $this->order();
        $parcel = $this->parcel([$order]);

        // Act
        $response = $this->change($this->clerk(), $order, DeliveryPayer::Us);

        // Assert
        $response->assertOk()->assertJsonPath('data.carrier.told', true);
        Http::assertSent(fn ($request) => (int) $request->data()['shipment_on_sender'] === 1);
        $this->assertSame(2, $parcel->fresh()->payer_sent);
        $this->assertSame(2, $parcel->fresh()->shipment_on_sender);
    }

    public function test_a_refusal_keeps_the_choice_and_warns_that_the_courier_will_still_charge(): void
    {
        // Arrange
        $this->nawrisRefuses();
        $order = $this->order();
        $parcel = $this->parcel([$order]);

        // Act
        $response = $this->change($this->clerk(), $order, DeliveryPayer::Us);

        // Assert
        $response->assertOk()->assertJsonPath('data.carrier.told', false);
        $this->assertStringContainsString('المندوب سيطلب أجرته من المستلم', (string) $response->json('data.carrier.warning'));
        $this->assertSame(DeliveryPayer::Us, $order->fresh()->delivery_paid_by);
        $this->assertNotNull($parcel->fresh()->sync_failed_at);
        // Nawris still has the customer paying, and the order screen can see they differ.
        $response->assertJsonPath('data.order.nawris_parcel.nawris_payer', 'recipient');
    }

    public function test_a_shared_parcel_changes_every_order_in_it(): void
    {
        // Arrange
        $this->nawrisAccepts();
        $first = $this->order();
        $second = $this->order();
        $this->parcel([$first, $second]);

        // Act
        $response = $this->change($this->clerk(), $first, DeliveryPayer::Us);

        // Assert
        $response->assertOk()->assertJsonPath('data.also_changed', [(string) $second->code]);
        $this->assertSame(DeliveryPayer::Us, $second->fresh()->delivery_paid_by);
        $this->assertSame('20.00', (string) $second->fresh()->delivery_cost);
    }

    public function test_the_shared_parcel_is_named_in_the_warnings(): void
    {
        // Arrange
        $first = $this->order();
        $second = $this->order();
        $this->parcel([$first, $second]);

        // Act
        $response = $this->withHeaders($this->clerk())->getJson("/api/v1/orders/{$first->id}");

        // Assert
        $warnings = implode(' ', $response->json('data.delivery_payer_warnings'));
        $this->assertStringContainsString('فقد ترفض', $warnings);
        $this->assertStringContainsString((string) $second->code, $warnings);
    }

    public function test_a_payment_after_dispatch_keeps_nawris_on_our_side(): void
    {
        // Arrange — the bug this fixed: an edit used to replay what the history said, and a
        // parcel dispatched as "we pay" read as the customer paying.
        $this->nawrisAccepts();
        $order = $this->order(OrderStatus::OutForDelivery, ['delivery_paid_by' => 'us', 'delivery_cost' => '20.00']);
        $this->parcel([$order], payer: 2);
        $headers = $this->auth(PermissionName::ViewOrders, PermissionName::ViewOrderPayments, PermissionName::RecordOrderPayments);

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments", [
            'amount' => '40.00',
            'method' => PaymentMethod::Cash->value,
        ])->assertCreated();

        // Assert
        Http::assertSent(fn ($request) => (int) $request->data()['shipment_on_sender'] === 1
            && (float) $request->data()['amount_to_be_collected'] === 60.0);
    }

    public function test_a_parcel_dispatched_as_ours_reads_as_ours_from_its_first_event(): void
    {
        // Arrange
        $order = $this->order();
        $parcel = $this->parcel([$order], payer: 2);
        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => ['to_status_code' => 4, 'order_price' => 100],
            'status_code' => 4,
            'received_at' => now(),
        ]);

        // Act
        $terms = app(ReadNawrisParcelTerms::class)($parcel->fresh());

        // Assert — no fee read off a door amount that holds none
        $this->assertTrue($terms->senderPays());
        $this->assertNull($terms->fee);
    }

    public function test_our_accepted_change_outlives_an_event_that_does_not_mention_it(): void
    {
        // Arrange — dispatched with the customer paying, switched to us yesterday, then an
        // ordinary status event today
        $order = $this->order();
        $parcel = $this->parcel([$order], payer: 1);
        $parcel->forceFill(['payer_sent' => 2, 'payer_sent_at' => now()->subDay()])->save();
        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => ['to_status_code' => 4, 'order_price' => 120],
            'status_code' => 4,
            'received_at' => now()->subDays(2),
        ]);
        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => ['to_status_code' => 4, 'order_price' => 100],
            'status_code' => 4,
            'received_at' => now(),
        ]);

        // Act
        $terms = app(ReadNawrisParcelTerms::class)($parcel->fresh());

        // Assert — the fee came from before the switch, and we pay it now
        $this->assertTrue($terms->senderPays());
        $this->assertSame('20.00', $terms->fee);
    }

    public function test_a_flip_at_nawris_moves_the_order_with_it(): void
    {
        // Arrange
        $order = $this->order();
        $this->parcel([$order]);

        // Act — someone at Nawris put the fee on us
        $this->webhook('CODE-1', [
            'event' => 'shipment.updated',
            'from_status_code' => 4,
            'to_status_code' => 4,
            'order_price' => 100,
            'changes' => ['shipment_on_sender' => ['old' => 1, 'new' => 2]],
        ]);

        // Assert
        $fresh = $order->fresh();
        $this->assertSame(DeliveryPayer::Us, $fresh->delivery_paid_by);
        $this->assertSame('20.00', (string) $fresh->delivery_cost);
        $this->assertStringContainsString(
            'تبعتها الطلبية',
            (string) NawrisWebhookEvent::query()->latest('id')->value('error'),
        );
    }

    public function test_delivery_on_a_parcel_we_pay_for_pays_the_order_in_full(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::OutForDelivery, ['delivery_paid_by' => 'us', 'delivery_cost' => '20.00']);
        $this->parcel([$order], payer: 2);

        // Act — the courier took 100 at the door, no fee on top
        $this->webhook('CODE-1', ['to_status_code' => 7, 'to_status_text' => 'تم التسليم', 'order_price' => 100]);

        // Assert
        $fresh = $order->fresh();
        $this->assertSame(OrderStatus::Delivered, $fresh->status);
        $this->assertSame('100.00', (string) $fresh->paid_amount);
    }

    // ── settlement ───────────────────────────────────────────────────────────────────────

    /** Out on a "we pay" parcel, then delivered: 100 sits in Nawris's custody. */
    private function deliveredOnOurParcel(): Order
    {
        $order = $this->order(OrderStatus::OutForDelivery, ['delivery_paid_by' => 'us', 'delivery_cost' => '20.00']);
        $this->parcel([$order], payer: 2);
        $this->webhook('CODE-1', ['to_status_code' => 7, 'to_status_text' => 'تم التسليم', 'order_price' => 100]);

        return $order->fresh();
    }

    private function settle(array $headers, Order $order, array $fields = []): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/status", [
            'status' => OrderStatus::Settled->value,
            'fields' => $fields,
        ]);
    }

    public function test_settlement_opens_on_the_fee_we_expect_to_lose(): void
    {
        // Arrange
        $order = $this->deliveredOnOurParcel();

        // Act
        $response = $this->withHeaders($this->settler())->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $fields = collect($response->json('data.available_transitions'))
            ->firstWhere('status', OrderStatus::Settled->value)['fields'] ?? [];
        $fee = collect($fields)->firstWhere('key', 'settlement_fee');
        $this->assertNotNull($fee);
        $this->assertSame('20', $fee['value']);
        $this->assertStringContainsString('يصير هو تكلفة التوصيل', (string) $fee['hint']);
    }

    public function test_what_the_carrier_really_kept_becomes_the_cost(): void
    {
        // Arrange
        $order = $this->deliveredOnOurParcel();

        // Act — Nawris kept 25, not the 20 the city's rate said
        $this->settle($this->settler(), $order, ['settlement_fee' => '25'])->assertOk();

        // Assert — 100 − 60 − 25
        $fresh = $order->fresh();
        $this->assertSame('25.00', (string) $fresh->delivery_cost);
        $this->assertSame('15.00', $fresh->grossProfit());
    }

    public function test_undoing_the_settlement_puts_the_city_rate_back(): void
    {
        // Arrange
        $headers = $this->settler();
        $order = $this->deliveredOnOurParcel();
        $this->settle($headers, $order, ['settlement_fee' => '25'])->assertOk();

        // Act
        $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/unsettle", [
            'reason' => 'سُوّيت بالمبلغ الخطأ',
        ])->assertOk();

        // Assert
        $this->assertSame('20.00', (string) $order->fresh()->delivery_cost);
    }

    // ── who shares it ────────────────────────────────────────────────────────────────────

    public function test_the_deals_that_sold_the_goods_share_the_fee(): void
    {
        // Arrange — one line of 100, all of it drawn from deal 7 at a cost of 60
        $order = [
            'grand_total' => '100.00',
            'items_total' => '100.00',
            'delivery_cost' => '20.00',
            'lines' => [[
                'movement_id' => 1,
                'stock_purchased' => false,
                'line_total' => '100.00',
                'conversion_cost' => '0.00',
            ]],
        ];
        $breakdown = [1 => [[
            'investor_deal_id' => 7,
            'printing_sale_price' => null,
            'quantity' => '10',
            'total_cost' => '60.00',
        ]]];

        // Act
        $slices = OrderDealSlices::forOrder($order, $breakdown);

        // Assert — 100 − 20 − 60
        $this->assertSame('80.00', $slices[7]['revenue']);
        $this->assertSame('20.00', $slices[7]['profit']);
    }

    public function test_the_profit_and_loss_report_takes_the_fee_off_gross_profit(): void
    {
        // Arrange
        $order = $this->order(OrderStatus::Delivered, [
            'delivery_paid_by' => 'us',
            'delivery_cost' => '20.00',
            'delivered_at' => '2026-03-15 10:00:00',
        ]);
        OrderItem::factory()->for($order)->create([
            'material_cost' => '60.00', 'labor_cost' => '0.00', 'overhead_cost' => '0.00', 'cogs' => '60.00',
        ]);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewProfitAndLossReport))
            ->getJson('/api/v1/reports/profit-loss?from=2026-03-01&to=2026-03-31');

        // Assert — 100 − 60 − 20
        $response->assertOk()
            ->assertJsonPath('data.delivery_costs', '20.00')
            ->assertJsonPath('data.gross_profit', '20.00');
    }

    public function test_a_payment_while_the_order_is_ours_moves_the_cod_only(): void
    {
        // Arrange — RecordOrderPayment directly: the money moves, the payer does not
        $order = $this->order(OrderStatus::Ready, ['delivery_paid_by' => 'us', 'delivery_cost' => '20.00']);

        // Act
        app(RecordOrderPayment::class)($order, OrderPaymentData::fromArray([
            'amount' => '40.00',
            'method' => PaymentMethod::Cash->value,
        ]), User::factory()->create());

        // Assert
        $fresh = $order->fresh();
        $this->assertSame(DeliveryPayer::Us, $fresh->delivery_paid_by);
        $this->assertSame('20.00', (string) $fresh->delivery_cost);
    }
}
