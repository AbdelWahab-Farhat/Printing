<?php

declare(strict_types=1);

namespace Tests\Feature\Carrier;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Money that moves while a parcel is out, and whether Nawris heard.
 *
 * **The incident:** a customer paid 115 by transfer while their parcel was with the courier. The
 * edit telling Nawris was refused, the refusal was swallowed without a log line, and the courier
 * collected the full 435 an hour later. These are the tests that it can no longer happen quietly:
 * the refusal is kept, answered, shown before and after, retried, put right by a hand correction
 * at Nawris, and called out at delivery.
 *
 * The arithmetic throughout: an order of 100, out in a parcel asking 100, with Nawris's fee of 20
 * on top at the door.
 *
 * Arrange - Act - Assert throughout.
 */
class NawrisMoneySyncTest extends TestCase
{
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
    private function cashier(): array
    {
        return $this->auth(
            PermissionName::ViewOrders,
            PermissionName::ViewOrderPayments,
            PermissionName::RecordOrderPayments,
            PermissionName::ReverseOrderPayments,
        );
    }

    /**
     * An order of 100 out with the courier in a parcel of its own, its fee of 20 already read
     * from their first event.
     *
     * @return array{Order, NawrisParcel}
     */
    private function outWithTheCourier(): array
    {
        $city = City::factory()->create([
            'fulfilment_type' => FulfilmentType::Delivery,
            'nawris_government_id' => '5',
        ]);

        $order = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'city_id' => $city->id,
            'city_name' => $city->name,
            'fulfilment_type' => FulfilmentType::Delivery,
            'items_total' => '100.00',
            'delivery_price' => '0.00',
            'grand_total' => '100.00',
        ]);

        $parcel = NawrisParcel::factory()->create([
            'reference' => 'ref-1',
            'code' => 'CODE-1',
            'amount_to_collect' => '100.00',
            'delivery_price_deducted' => '0.00',
            'government' => '5',
            'area' => '204',
        ]);

        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $order->id,
            'amount_to_collect' => '100.00',
        ]);

        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => ['remote_order_id' => 'ref-1', 'order_code' => 'CODE-1', 'to_status_code' => 4, 'order_price' => 120],
            'status_code' => 4,
            'received_at' => now()->subDay(),
        ]);

        return [$order, $parcel];
    }

    private function nawrisRefuses(): void
    {
        Http::fake(['*' => Http::response(['success' => 0, 'error_msg' => 'لا يمكن تعديل شحنة مع المندوب'], 200)]);
    }

    private function nawrisAccepts(): void
    {
        Http::fake(['*' => Http::response(['success' => 1, 'result' => []], 200)]);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function pay(array $headers, Order $order, string $amount = '40.00'): TestResponse
    {
        return $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments", [
            'amount' => $amount,
            'method' => PaymentMethod::Cash->value,
        ]);
    }

    /**
     * @param  array<string, mixed>  $body
     */
    private function webhook(array $body): void
    {
        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])
            ->postJson('/api/v1/webhooks/nawris', array_merge(['remote_order_id' => 'ref-1', 'order_code' => 'CODE-1'], $body))
            ->assertOk();
    }

    /** 40 taken at the counter while Nawris would not listen. */
    private function paidWhileRefused(Order $order, NawrisParcel $parcel): void
    {
        app(RecordOrderPayment::class)($order->refresh(), OrderPaymentData::fromArray([
            'amount' => '40.00',
            'method' => PaymentMethod::Cash->value,
        ]), User::factory()->create());

        $parcel->forceFill(['sync_failed_at' => now(), 'sync_error' => 'مع المندوب'])->save();
    }

    // ── after the money is taken ─────────────────────────────────────────────────────────

    public function test_a_refused_edit_keeps_the_payment_and_says_so(): void
    {
        // Arrange
        $this->nawrisRefuses();
        [$order, $parcel] = $this->outWithTheCourier();

        // Act
        $response = $this->pay($this->cashier(), $order);

        // Assert — the money stands; the answer says the courier still holds the old amount.
        $response->assertCreated()
            ->assertJsonPath('data.summary.paid_amount', '40.00')
            ->assertJsonPath('data.carrier.told', false)
            ->assertJsonPath('data.carrier.nawris_asks', '100.00')
            ->assertJsonPath('data.carrier.should_ask', '60.00');
        $this->assertStringContainsString('لم تقبل نورس', (string) $response->json('data.carrier.warning'));
        $this->assertStringContainsString('مع المندوب', (string) $response->json('data.carrier.reason'));

        $parcel->refresh();
        $this->assertTrue($parcel->moneyOutOfSync());
        $this->assertSame('100.00', (string) $parcel->amount_to_collect);
    }

    public function test_an_accepted_edit_clears_an_older_refusal(): void
    {
        // Arrange
        $this->nawrisAccepts();
        [$order, $parcel] = $this->outWithTheCourier();
        $parcel->forceFill(['sync_failed_at' => now()->subHour(), 'sync_error' => 'مع المندوب'])->save();

        // Act
        $response = $this->pay($this->cashier(), $order);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.carrier.told', true)
            ->assertJsonPath('data.carrier.warning', null);
        $parcel->refresh();
        $this->assertFalse($parcel->moneyOutOfSync());
        $this->assertNull($parcel->sync_error);
        $this->assertSame('60.00', (string) $parcel->amount_to_collect);
    }

    public function test_no_parcel_out_means_no_carrier_answer(): void
    {
        // Arrange
        Http::fake();
        $order = Order::factory()->create(['items_total' => '100.00', 'delivery_price' => '0.00', 'grand_total' => '100.00']);

        // Act
        $response = $this->pay($this->cashier(), $order);

        // Assert
        $response->assertCreated()->assertJsonPath('data.carrier', null);
        Http::assertNothingSent();
    }

    public function test_a_refund_tells_nawris_the_higher_amount(): void
    {
        // Arrange — money handed back is money the courier should collect again.
        $this->nawrisAccepts();
        [$order] = $this->outWithTheCourier();
        $headers = $this->cashier();
        $this->pay($headers, $order);

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/refunds", [
            'amount' => '40.00',
            'method' => PaymentMethod::Cash->value,
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.carrier.told', true);
        Http::assertSent(fn ($request) => (float) $request->data()['amount_to_be_collected'] === 100.0);
    }

    public function test_a_cancelled_entry_tells_nawris_too(): void
    {
        // Arrange
        $this->nawrisAccepts();
        [$order] = $this->outWithTheCourier();
        $headers = $this->cashier();
        $paymentId = $this->pay($headers, $order)->json('data.payment.id');

        // Act
        $response = $this->withHeaders($headers)->postJson("/api/v1/orders/{$order->id}/payments/{$paymentId}/reverse", [
            'reason' => 'سُجّلت خطأً',
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.carrier.should_ask', '100.00');
    }

    // ── before the money is taken ────────────────────────────────────────────────────────

    public function test_the_ledger_warns_before_money_is_taken_while_a_parcel_is_out(): void
    {
        // Arrange
        [$order, $parcel] = $this->outWithTheCourier();
        $parcel->forceFill(['sync_failed_at' => now(), 'sync_error' => 'مع المندوب'])->save();

        // Act
        $response = $this->withHeaders($this->cashier())->getJson("/api/v1/orders/{$order->id}/payments");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.carrier.parcel_code', 'CODE-1')
            ->assertJsonPath('data.carrier.nawris_asks', '100.00')
            ->assertJsonPath('data.carrier.money_out_of_sync', true);
        $this->assertStringContainsString('الطلبية لدى نورس', (string) $response->json('data.carrier.notice'));
    }

    public function test_the_ledger_says_nothing_when_no_parcel_is_out(): void
    {
        // Arrange
        $order = Order::factory()->create(['items_total' => '100.00', 'delivery_price' => '0.00', 'grand_total' => '100.00']);

        // Act
        $response = $this->withHeaders($this->cashier())->getJson("/api/v1/orders/{$order->id}/payments");

        // Assert
        $response->assertOk()->assertJsonPath('data.carrier', null);
    }

    // ── on the order, and the retry ──────────────────────────────────────────────────────

    public function test_the_order_carries_the_red_line_until_it_is_put_right(): void
    {
        // Arrange
        [$order, $parcel] = $this->outWithTheCourier();
        $parcel->forceFill(['sync_failed_at' => now(), 'sync_error' => 'مع المندوب'])->save();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewOrders))->getJson("/api/v1/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.nawris_parcel.money_out_of_sync', true)
            ->assertJsonPath('data.nawris_parcel.nawris_asks', '100.00')
            ->assertJsonPath('data.nawris_parcel.sync_error', 'مع المندوب');
    }

    public function test_the_retry_needs_the_manage_grant(): void
    {
        // Arrange
        Http::fake();
        [$order] = $this->outWithTheCourier();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewCarrierParcels))
            ->postJson("/api/v1/carrier/orders/{$order->id}/sync-money");

        // Assert
        $response->assertForbidden();
        Http::assertNothingSent();
    }

    public function test_a_retry_nawris_accepts_clears_the_red_line(): void
    {
        // Arrange
        $this->nawrisAccepts();
        [$order, $parcel] = $this->outWithTheCourier();
        $this->paidWhileRefused($order, $parcel);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ManageCarrierParcels))
            ->postJson("/api/v1/carrier/orders/{$order->id}/sync-money");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.told', true)
            ->assertJsonPath('data.should_ask', '60.00');
        $this->assertFalse($parcel->fresh()->moneyOutOfSync());
    }

    public function test_a_retry_nawris_refuses_again_is_an_answer_not_an_error(): void
    {
        // Arrange
        $this->nawrisRefuses();
        [$order, $parcel] = $this->outWithTheCourier();
        $this->paidWhileRefused($order, $parcel);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ManageCarrierParcels))
            ->postJson("/api/v1/carrier/orders/{$order->id}/sync-money");

        // Assert
        $response->assertOk()->assertJsonPath('data.told', false);
        $this->assertTrue($parcel->fresh()->moneyOutOfSync());
    }

    public function test_the_parcels_list_finds_the_ones_nawris_was_not_told_about(): void
    {
        // Arrange
        [, $parcel] = $this->outWithTheCourier();
        $parcel->forceFill(['sync_failed_at' => now()])->save();
        NawrisParcel::factory()->create();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewCarrierParcels))
            ->getJson('/api/v1/carrier/parcels?unsynced=1');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data');
        $this->assertSame($parcel->id, $response->json('data.0.id'));
        $this->assertTrue($response->json('data.0.money_out_of_sync'));
    }

    // ── put right at Nawris, or called out at delivery ───────────────────────────────────

    public function test_a_hand_correction_at_nawris_to_the_right_amount_clears_the_red_line(): void
    {
        // Arrange — 40 paid, our edit refused; hours later someone at Nawris takes the 40 off by
        // hand: door 120 → 80, which leaves us 60, exactly what the order owes.
        [$order, $parcel] = $this->outWithTheCourier();
        $this->paidWhileRefused($order, $parcel);

        // Act
        $this->webhook([
            'event' => 'shipment.updated',
            'to_status_code' => 4,
            'order_price' => 80,
            'changes' => ['amount_to_be_collected' => ['old' => 120, 'new' => 80]],
        ]);

        // Assert
        $parcel->refresh();
        $this->assertFalse($parcel->moneyOutOfSync());
        $this->assertSame('60.00', (string) $parcel->amount_to_collect);
        $this->assertSame('80.00', (string) $parcel->door_amount);
    }

    public function test_a_hand_correction_to_the_wrong_amount_stays_flagged(): void
    {
        // Arrange
        [$order, $parcel] = $this->outWithTheCourier();
        $this->paidWhileRefused($order, $parcel);

        // Act — 90 at the door leaves 70, not the 60 owed.
        $this->webhook([
            'event' => 'shipment.updated',
            'to_status_code' => 4,
            'order_price' => 90,
            'changes' => ['amount_to_be_collected' => ['old' => 120, 'new' => 90]],
        ]);

        // Assert
        $parcel->refresh();
        $this->assertTrue($parcel->moneyOutOfSync());
        $this->assertSame('90.00', (string) $parcel->door_amount);
    }

    public function test_a_delivery_while_nawris_was_never_told_is_called_out(): void
    {
        // Arrange — parcel 4600741: the customer paid first, and the courier took the old 120.
        [$order, $parcel] = $this->outWithTheCourier();
        $this->paidWhileRefused($order, $parcel);

        // Act
        $this->webhook(['to_status_code' => 7, 'to_status_text' => 'تم التسليم', 'order_price' => 120]);

        // Assert — 60 is paid (capped), and the event says the customer may have paid twice.
        $error = (string) NawrisWebhookEvent::query()->latest('id')->firstOrFail()->error;
        $this->assertSame('100.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString('فقد يكون الزبون دفع مرتين', $error);
        $this->assertStringContainsString('تحصيل زائد', $error);
    }
}
