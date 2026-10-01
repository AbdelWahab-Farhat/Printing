<?php

declare(strict_types=1);

namespace Tests\Feature\Carrier;

use App\Domain\Carrier\CarrierService;
use App\Domain\Carrier\Exceptions\NawrisRejectedRequest;
use App\Domain\Carrier\Exceptions\OrderAlreadyHasAnOpenParcel;
use App\Domain\Carrier\Exceptions\OrderCannotBeDispatchedToNawris;
use App\Domain\Carrier\Exceptions\OrdersCannotShareAParcel;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * Several orders in one Nawris parcel.
 *
 * **The money assertions are the point of this file.** A shared parcel collects every order's
 * money as one sum, and each place that splits it back — the delivery webhook, an edit after a
 * payment, a re-send — used to assume the parcel was one order. Getting any of them wrong either
 * credits every order with the whole parcel, or rewrites the parcel as if its siblings were gone.
 *
 * The arithmetic throughout: two orders of the same customer to the same door, one owing 100 and
 * one owing 60, so the parcel collects 160.
 *
 * Arrange - Act - Assert throughout.
 */
class NawrisSharedParcelTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'shared-secret';

    private City $city;

    private Region $region;

    private Customer $customer;

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

        $this->city = City::factory()->create([
            'fulfilment_type' => FulfilmentType::Delivery,
            'nawris_government_id' => '5',
        ]);
        $this->region = Region::factory()->create(['city_id' => $this->city->id, 'nawris_area_id' => '204']);
        $this->customer = Customer::factory()->create();
    }

    private function accepted(string $code = '3702994'): void
    {
        Http::fake(['*' => Http::response([
            'success' => 1,
            'result' => ['code' => $code, 'bar_code' => 'B-1'],
        ], 200)]);
    }

    /**
     * A ready order of the shared customer, to the shared door.
     *
     * @param  array<string, mixed>  $overrides
     */
    private function order(string $total = '100.00', array $overrides = []): Order
    {
        return Order::factory()->create(array_merge([
            'customer_id' => $this->customer->id,
            'city_id' => $this->city->id,
            'region_id' => $this->region->id,
            'city_name' => $this->city->name,
            'status' => OrderStatus::Ready,
            'fulfilment_type' => FulfilmentType::Delivery,
            'recipient_phone' => '0912345678',
            'items_total' => $total,
            'delivery_price' => '0.00',
            'grand_total' => $total,
        ], $overrides));
    }

    private function carrier(): CarrierService
    {
        return app(CarrierService::class);
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

    /**
     * Two orders already out together in one parcel, as the webhook and the edit find them.
     *
     * @return array{Order, Order, NawrisParcel}
     */
    private function sharedParcel(OrderStatus $status = OrderStatus::OutForDelivery): array
    {
        $first = $this->order('100.00', ['status' => $status]);
        $second = $this->order('60.00', ['status' => $status]);

        $parcel = NawrisParcel::factory()->create([
            'reference' => 'ref-1',
            'code' => 'CODE-1',
            'government' => '5',
            'area' => '204',
            'amount_to_collect' => '160.00',
            'delivery_price_deducted' => '0.00',
        ]);

        foreach ([[$first, '100.00'], [$second, '60.00']] as [$order, $share]) {
            NawrisParcelOrder::factory()->create([
                'nawris_parcel_id' => $parcel->id,
                'order_id' => $order->id,
                'amount_to_collect' => $share,
            ]);
        }

        return [$first, $second, $parcel];
    }

    // ── sending ──────────────────────────────────────────────────────────────────────────

    public function test_two_orders_go_out_as_one_parcel_with_a_link_each(): void
    {
        // Arrange
        $this->accepted();
        $first = $this->order('100.00');
        $second = $this->order('60.00');

        // Act
        $parcel = $this->carrier()->dispatchGroup([$first, $second]);

        // Assert — one parcel, one call, each order holding its own share of the sum.
        $this->assertSame(1, NawrisParcel::query()->count());
        $this->assertSame('160.00', (string) $parcel->amount_to_collect);
        $this->assertSame('100.00', (string) NawrisParcelOrder::query()->where('order_id', $first->id)->value('amount_to_collect'));
        $this->assertSame('60.00', (string) NawrisParcelOrder::query()->where('order_id', $second->id)->value('amount_to_collect'));
        Http::assertSentCount(1);
    }

    public function test_the_payload_names_every_order_and_counts_them(): void
    {
        // Arrange — passed in reverse, to show the label does not depend on the order of the
        // request: create, edit and resend all rebuild it by id.
        $this->accepted();
        $first = $this->order('100.00');
        $second = $this->order('60.00');

        // Act
        $this->carrier()->dispatchGroup([$second, $first]);

        // Assert
        Http::assertSent(function ($request) use ($first, $second): bool {
            $body = $request->data();

            return $body['receiver'] === $first->code.'+'.$second->code
                && (float) $body['amount_to_be_collected'] === 160.0
                && (int) $body['pieces_count'] === 2
                && $body['order_summary'] === '2 طلبيات أكياس';
        });
    }

    public function test_an_overpaid_order_adds_nothing_rather_than_discounting_its_sibling(): void
    {
        // Arrange — the overpaid customer is owed a refund, and the courier cannot hand it over
        // at another order's door.
        $this->accepted();
        $first = $this->order('100.00');
        $overpaid = $this->order('60.00', ['paid_amount' => '80.00']);

        // Act
        $parcel = $this->carrier()->dispatchGroup([$first, $overpaid]);

        // Assert
        $this->assertSame('100.00', (string) $parcel->amount_to_collect);
    }

    public function test_sending_moves_no_order(): void
    {
        // Arrange — lodging is not the goods leaving. The courier's pick-up arrives by webhook
        // and moves them then.
        $this->accepted();
        $first = $this->order();
        $second = $this->order();

        // Act
        $this->carrier()->dispatchGroup([$first, $second]);

        // Assert
        $this->assertSame(OrderStatus::Ready, $first->fresh()->status);
        $this->assertSame(OrderStatus::Ready, $second->fresh()->status);
    }

    public function test_one_order_is_not_a_shared_parcel(): void
    {
        // Arrange
        $this->accepted();

        // Assert
        $this->expectException(OrdersCannotShareAParcel::class);

        // Act
        $this->carrier()->dispatchGroup([$this->order()]);
    }

    // ── who may share ────────────────────────────────────────────────────────────────────

    public function test_orders_of_two_customers_are_refused_before_any_call(): void
    {
        // Arrange — a refusal at the door would send the other customer's goods back with it.
        $this->accepted();
        $mine = $this->order();
        $theirs = $this->order(overrides: ['customer_id' => Customer::factory()->create()->id]);

        // Act
        $this->assertThrows(
            fn () => $this->carrier()->dispatchGroup([$mine, $theirs]),
            OrdersCannotShareAParcel::class,
        );

        // Assert
        Http::assertNothingSent();
        $this->assertSame(0, NawrisParcel::query()->count());
    }

    public function test_orders_to_two_regions_are_refused(): void
    {
        // Arrange — one parcel, one door.
        $this->accepted();
        $here = $this->order();
        $elsewhere = $this->order(overrides: [
            'region_id' => Region::factory()->create(['city_id' => $this->city->id])->id,
        ]);

        // Assert
        $this->expectException(OrdersCannotShareAParcel::class);

        // Act
        $this->carrier()->dispatchGroup([$here, $elsewhere]);
    }

    public function test_orders_to_two_phones_are_refused(): void
    {
        // Arrange
        $this->accepted();
        $first = $this->order();
        $second = $this->order(overrides: ['recipient_phone' => '0923456789']);

        // Assert
        $this->expectException(OrdersCannotShareAParcel::class);

        // Act
        $this->carrier()->dispatchGroup([$first, $second]);
    }

    public function test_the_same_phone_typed_two_ways_is_one_recipient(): void
    {
        // Arrange — compared as it would be sent, not as it was typed.
        $this->accepted();
        $first = $this->order();
        $second = $this->order(overrides: ['recipient_phone' => '+218 91 234 5678']);

        // Act
        $parcel = $this->carrier()->dispatchGroup([$first, $second]);

        // Assert
        $this->assertSame(2, $parcel->links()->count());
    }

    public function test_one_order_not_ready_refuses_the_whole_group(): void
    {
        // Arrange — the group was chosen as a group; shipping the ones that pass is a parcel
        // nobody asked for.
        $this->accepted();
        $ready = $this->order();
        $printing = $this->order(overrides: ['status' => OrderStatus::Printing]);

        // Act
        $this->assertThrows(
            fn () => $this->carrier()->dispatchGroup([$ready, $printing]),
            OrderCannotBeDispatchedToNawris::class,
        );

        // Assert
        Http::assertNothingSent();
    }

    public function test_an_order_already_out_refuses_the_whole_group(): void
    {
        // Arrange
        $this->accepted();
        [$out] = $this->sharedParcel(OrderStatus::Ready);
        $fresh = $this->order();

        // Assert
        $this->expectException(OrderAlreadyHasAnOpenParcel::class);

        // Act
        $this->carrier()->dispatchGroup([$out, $fresh]);
    }

    public function test_a_carrier_that_is_down_leaves_nothing_behind(): void
    {
        // Arrange — the orders are exactly where they were, so sending again is the retry.
        Http::fake(['*' => Http::response(['success' => 0, 'error_msg' => 'لا'], 200)]);
        $first = $this->order();
        $second = $this->order();

        // Act
        try {
            $this->carrier()->dispatchGroup([$first, $second]);
        } catch (NawrisRejectedRequest) {
            // what matters here is what was left behind
        }

        // Assert
        $this->assertSame(0, NawrisParcel::query()->count());
        $this->assertSame(0, NawrisParcelOrder::query()->count());
        $this->assertSame(OrderStatus::Ready, $first->fresh()->status);
    }

    // ── over http ────────────────────────────────────────────────────────────────────────

    public function test_the_endpoint_sends_them_and_answers_with_the_orders_in_it(): void
    {
        // Arrange
        $this->accepted();
        $first = $this->order('100.00');
        $second = $this->order('60.00');

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ManageCarrierParcels))
            ->postJson('/api/v1/carrier/parcels', ['order_ids' => [$first->id, $second->id]]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.code', '3702994')
            ->assertJsonPath('data.amount_to_collect', '160.00')
            ->assertJsonCount(2, 'data.orders')
            ->assertJsonPath('data.orders.0.id', $first->id)
            ->assertJsonPath('data.orders.1.amount_to_collect', '60.00');
    }

    public function test_the_endpoint_names_the_order_that_does_not_fit(): void
    {
        // Arrange
        $this->accepted();
        $mine = $this->order();
        $theirs = $this->order(overrides: ['customer_id' => Customer::factory()->create()->id]);

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ManageCarrierParcels))
            ->postJson('/api/v1/carrier/parcels', ['order_ids' => [$mine->id, $theirs->id]]);

        // Assert
        $response->assertUnprocessable();
        $this->assertStringContainsString((string) $theirs->code, (string) $response->json('message'));
    }

    public function test_the_endpoint_wants_two_distinct_orders(): void
    {
        // Arrange
        $order = $this->order();
        $headers = $this->auth(PermissionName::ManageCarrierParcels);

        // Act
        $one = $this->withHeaders($headers)->postJson('/api/v1/carrier/parcels', ['order_ids' => [$order->id]]);
        $twice = $this->withHeaders($headers)->postJson('/api/v1/carrier/parcels', ['order_ids' => [$order->id, $order->id]]);

        // Assert
        $one->assertUnprocessable();
        $twice->assertUnprocessable();
    }

    public function test_the_endpoint_needs_more_than_the_view_permission(): void
    {
        // Arrange
        Http::fake();
        $first = $this->order();
        $second = $this->order();

        // Act
        $response = $this->withHeaders($this->auth(PermissionName::ViewCarrierParcels))
            ->postJson('/api/v1/carrier/parcels', ['order_ids' => [$first->id, $second->id]]);

        // Assert
        $response->assertForbidden();
        Http::assertNothingSent();
    }

    // ── the money coming back ────────────────────────────────────────────────────────────

    public function test_a_delivery_pays_each_order_its_own_share(): void
    {
        // Arrange — the parcel's 160 paid to each would credit both orders with the whole parcel.
        [$first, $second, $parcel] = $this->sharedParcel();

        // Act
        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])->postJson('/api/v1/webhooks/nawris', [
            'remote_order_id' => 'ref-1',
            'order_code' => 'CODE-1',
            'to_status_code' => 7,
            'to_status_text' => 'تم التسليم',
            'order_price' => '175.00',
        ]);

        // Assert — both delivered, each settled at exactly what it owed, and the parcel closed.
        $first->refresh();
        $second->refresh();
        $this->assertSame(OrderStatus::Delivered, $first->status);
        $this->assertSame(OrderStatus::Delivered, $second->status);
        $this->assertSame('100.00', (string) $first->paid_amount);
        $this->assertSame('60.00', (string) $second->paid_amount);
        $this->assertSame('0.00', $first->remainingAmount());
        $this->assertSame('0.00', $second->remainingAmount());
        $this->assertNotNull($parcel->fresh()->closed_at);
    }

    public function test_the_courier_s_pick_up_moves_every_order_in_the_parcel(): void
    {
        // Arrange — code 4, «مع المندوب»: the moment a ready order goes out for delivery.
        [$first, $second] = $this->sharedParcel(OrderStatus::Ready);

        // Act
        $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])->postJson('/api/v1/webhooks/nawris', [
            'remote_order_id' => 'ref-1',
            'order_code' => 'CODE-1',
            'to_status_code' => 4,
            'to_status_text' => 'مع المندوب',
        ]);

        // Assert
        $this->assertSame(OrderStatus::OutForDelivery, $first->fresh()->status);
        $this->assertSame(OrderStatus::OutForDelivery, $second->fresh()->status);
    }

    // ── editing, re-sending, letting go ──────────────────────────────────────────────────

    public function test_a_payment_on_one_order_edits_the_parcel_with_both(): void
    {
        // Arrange — the bug this whole change exists to prevent: an edit built from the paying
        // order alone would tell Nawris to collect 40 for two orders' goods.
        Http::fake(['*' => Http::response(['success' => 1, 'result' => []], 200)]);
        [$first, $second, $parcel] = $this->sharedParcel();
        $second->forceFill(['paid_amount' => '20.00'])->save();

        // Act
        $this->carrier()->syncMoneyFor($second);

        // Assert — 100 + (60 − 20), and each share rewritten on its own row.
        Http::assertSent(fn ($request) => (float) $request->data()['amount_to_be_collected'] === 140.0
            && $request->data()['receiver'] === $first->code.'+'.$second->code);
        $this->assertSame('140.00', (string) $parcel->fresh()->amount_to_collect);
        $this->assertSame('100.00', (string) NawrisParcelOrder::query()->where('order_id', $first->id)->value('amount_to_collect'));
        $this->assertSame('40.00', (string) NawrisParcelOrder::query()->where('order_id', $second->id)->value('amount_to_collect'));
    }

    public function test_a_resend_takes_every_order_out_again(): void
    {
        // Arrange — a shared parcel came back as a whole, so it goes out as a whole.
        Http::fake(['*' => Http::response(['success' => 1, 'result' => ['code' => 'CODE-2']], 200)]);
        [$first, $second, $parcel] = $this->sharedParcel();

        // Act
        $fresh = $this->carrier()->resendFor($second);

        // Assert
        $this->assertNotNull($fresh);
        $this->assertNotNull($parcel->fresh()->closed_at);
        $this->assertSame('160.00', (string) $fresh->amount_to_collect);
        $this->assertEqualsCanonicalizing(
            [$first->id, $second->id],
            $fresh->links()->pluck('order_id')->map(fn ($id) => (int) $id)->all(),
        );
    }

    public function test_unlinking_from_one_order_lets_every_order_go(): void
    {
        // Arrange — the parcel is gone at their end for all of them alike.
        Http::fake();
        [$first, $second, $parcel] = $this->sharedParcel();

        // Act
        $this->carrier()->detachParcelFrom($first);

        // Assert
        $this->assertNull($this->carrier()->openParcelFor($first->fresh()));
        $this->assertNull($this->carrier()->openParcelFor($second->fresh()));
        $this->assertSame(0, $parcel->links()->count());
        Http::assertNothingSent();
    }

    // ── what the order screen reads ──────────────────────────────────────────────────────

    public function test_each_order_names_the_orders_it_shares_a_parcel_with(): void
    {
        // Arrange
        [$first, $second] = $this->sharedParcel();

        // Act
        $codes = $this->carrier()->parcelCodesFor([(int) $first->id, (int) $second->id]);

        // Assert
        $this->assertSame([['id' => (int) $second->id, 'code' => (string) $second->code]], $codes[$first->id]['shared_with']);
        $this->assertSame([['id' => (int) $first->id, 'code' => (string) $first->code]], $codes[$second->id]['shared_with']);
    }

    public function test_a_parcel_of_one_shares_with_nobody(): void
    {
        // Arrange
        $this->accepted();
        $order = $this->order();
        $this->carrier()->dispatchOrder($order);

        // Act
        $codes = $this->carrier()->parcelCodesFor([(int) $order->id]);

        // Assert
        $this->assertSame([], $codes[$order->id]['shared_with']);
    }
}
