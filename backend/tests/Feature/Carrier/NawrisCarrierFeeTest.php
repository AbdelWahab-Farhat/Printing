<?php

declare(strict_types=1);

namespace Tests\Feature\Carrier;

use App\Domain\Carrier\Actions\EditNawrisParcel;
use App\Domain\Carrier\Actions\ReadNawrisParcelTerms;
use App\Domain\Carrier\DTOs\NawrisParcelTerms;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

/**
 * Nawris's own fee, who pays it, and what that makes the payment on delivery.
 *
 * **The bodies are theirs**, taken from production events with names and phones removed — the
 * parcel each one came from is named against its test. Two shapes arrive: their status events, and
 * `shipment.updated`, their edit, which carries `changes` and the parcel's *current* status code.
 *
 * The rule under test, in one line each:
 *
 *     shipment_on_sender 1   the customer pays the fee   ours = door − fee
 *     shipment_on_sender 2   we pay the fee               ours = door
 *
 * Arrange - Act - Assert throughout.
 */
class NawrisCarrierFeeTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'shared-secret';

    private const REFERENCE = '1363_1790848706_96qh';

    private const CODE = '4522613';

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('services.nawris.webhook_secret', self::SECRET);
        config()->set('services.nawris.webhook_ips', []);
        config()->set('services.nawris.log_channel', 'null');
    }

    /**
     * @param  array<string, mixed>  $body
     */
    private function send(array $body): TestResponse
    {
        return $this->withHeaders(['Authorization' => 'Bearer '.self::SECRET])
            ->postJson('/api/v1/webhooks/nawris', $body);
    }

    /**
     * One of their status events.
     *
     * @return array<string, mixed>
     */
    private function statusEvent(int $code, float|int|null $doorAmount): array
    {
        return [
            'order_code' => self::CODE,
            'from_status_code' => 4,
            'to_status_code' => $code,
            'to_status_text' => $code === 7 ? 'تم التسليم' : 'مع المندوب',
            'order_price' => $doorAmount,
            'order_type' => 0,
            'remote_order_id' => self::REFERENCE,
            'invoice_number' => self::REFERENCE,
        ];
    }

    /**
     * One of their edits — `shipment.updated` — under the status the parcel is in.
     *
     * @param  array<string, mixed>  $changes
     * @return array<string, mixed>
     */
    private function edit(float|int $doorAmount, array $changes, int $statusCode = 4): array
    {
        return [
            'event' => 'shipment.updated',
            'order_code' => self::CODE,
            'new_order_code' => self::CODE,
            'from_status_code' => $statusCode,
            'to_status_code' => $statusCode,
            'to_status_text' => 'مع المندوب',
            'order_price' => $doorAmount,
            'order_type' => 1,
            'is_order' => '0',
            'remote_order_id' => self::REFERENCE,
            'invoice_number' => self::REFERENCE,
            'changes' => $changes,
        ];
    }

    /**
     * An order out for delivery in a parcel of its own, asking Nawris for `$asked`.
     *
     * @return array{Order, NawrisParcel}
     */
    private function parcelAsking(string $asked): array
    {
        $order = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'items_total' => $asked,
            'delivery_price' => '0.00',
            'grand_total' => $asked,
        ]);

        $parcel = NawrisParcel::factory()->create([
            'reference' => self::REFERENCE,
            'code' => self::CODE,
            'amount_to_collect' => $asked,
            'delivery_price_deducted' => '0.00',
        ]);

        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $order->id,
            'amount_to_collect' => $asked,
        ]);

        return [$order, $parcel];
    }

    private function lastEvent(): NawrisWebhookEvent
    {
        return NawrisWebhookEvent::query()->latest('id')->firstOrFail();
    }

    // ── the fee, and the payment it makes ────────────────────────────────────────────────

    public function test_the_fee_is_read_from_the_first_event_and_taken_off_the_door_amount(): void
    {
        // Arrange — we ask 141, they say 156 at the door from the start: their fee is 15.
        [$order, $parcel] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(4, 156));

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert
        $this->assertSame('15.00', (string) $parcel->fresh()->carrier_fee);
        $this->assertSame(NawrisParcelTerms::CUSTOMER_PAYS, $parcel->fresh()->shipment_on_sender);
        $this->assertSame('141.00', (string) $order->fresh()->paid_amount);
        $this->assertNull($this->lastEvent()->error);
    }

    public function test_a_shortfall_smaller_than_the_fee_is_paid_short_and_noted(): void
    {
        // Arrange — the gap the old floor could not see: 150 is above our 141, and still 6 short
        // of the 156 the customer owed at the door.
        [$order] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(4, 156));

        // Act
        $this->send($this->statusEvent(7, 150));

        // Assert — 135 is ours, 6 stays owed, and the note names what is still owed.
        $order->refresh();
        $this->assertSame('135.00', (string) $order->paid_amount);
        $this->assertSame('6.00', $order->remainingAmount());
        $this->assertStringContainsString('نقص في التحصيل: بقي على الطلبية 6.00 (الواصل لنا 135.00)', (string) $this->lastEvent()->error);
    }

    public function test_their_own_edit_upwards_is_capped_at_what_the_order_owes(): void
    {
        // Arrange — parcel 4522613: asked 141, fee 15, then they raised the door amount to 161
        // (event 378) and delivered at it. 146 is ours by the rule; the order only owes 141.
        [$order] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(3, 156));
        $this->send($this->edit(161, ['amount_to_be_collected' => ['old' => 156, 'new' => 161]]));

        // Act
        $this->send($this->statusEvent(7, 161));

        // Assert
        $this->assertSame('141.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString('تحصيل زائد', (string) $this->lastEvent()->error);
    }

    public function test_an_amount_cut_to_the_fee_before_delivery_pays_nothing(): void
    {
        // Arrange — parcel 4541005: asked 2,035, door 2,050, then cut to 15 (event 400) and
        // delivered at 15 (event 401). The old code paid 2,035 on it.
        [$order] = $this->parcelAsking('2035.00');
        $this->send($this->statusEvent(4, 2050));
        $this->send($this->edit(15, ['amount_to_be_collected' => ['old' => 2050, 'new' => 15]]));

        // Act
        $this->send($this->statusEvent(7, 15));

        // Assert
        $order->refresh();
        $this->assertSame(OrderStatus::Delivered, $order->status);
        $this->assertSame('0.00', (string) $order->paid_amount);
        $this->assertSame('2035.00', $order->remainingAmount());
        $this->assertStringContainsString('نقص في التحصيل', (string) $this->lastEvent()->error);
    }

    public function test_a_delivery_with_no_earlier_event_pays_nothing(): void
    {
        // Arrange — **the one source the fee may never come from.** Read off the delivery itself
        // it would make the payment our ask whatever was collected, which is what this replaced.
        [$order, $parcel] = $this->parcelAsking('141.00');

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert
        $this->assertSame(OrderStatus::Delivered, $order->fresh()->status);
        $this->assertSame('0.00', (string) $order->fresh()->paid_amount);
        $this->assertNull($parcel->fresh()->carrier_fee);
        $this->assertStringContainsString('أجرة نورس على هذا الطرد غير معروفة', (string) $this->lastEvent()->error);
        // What the courier took, so whoever enters it by hand starts from a figure.
        $this->assertStringContainsString('(حصّل المندوب 156.00)', (string) $this->lastEvent()->error);
    }

    public function test_a_parcel_whose_first_event_is_an_edit_reads_the_amount_from_before_it(): void
    {
        // Arrange — event 378 alone: 156 → 161. The fee is 156 − 141, not 161 − 141.
        [, $parcel] = $this->parcelAsking('141.00');

        // Act
        $this->send($this->edit(161, ['amount_to_be_collected' => ['old' => 156, 'new' => 161]]));

        // Assert
        $this->assertSame('15.00', (string) $parcel->fresh()->carrier_fee);
    }

    public function test_our_own_edit_after_their_first_event_does_not_move_the_fee(): void
    {
        // Arrange — 200 asked, 215 at the door. Then a payment at the counter took our ask down to
        // 141, and the door amount followed to 156. Reading 215 against today's 141 would make
        // their fee 74.
        [$order, $parcel] = $this->parcelAsking('200.00');
        $this->send($this->statusEvent(4, 215));

        $this->travel(5)->minutes();
        $parcel->forceFill(['amount_to_collect' => '141.00'])->save();
        $order->forceFill(['grand_total' => '141.00', 'items_total' => '141.00'])->save();
        $this->travel(5)->minutes();

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert
        $this->assertSame('15.00', (string) $parcel->fresh()->carrier_fee);
        $this->assertSame('141.00', (string) $order->fresh()->paid_amount);
    }

    public function test_the_fee_comes_from_the_earliest_stored_event_whatever_ran_first(): void
    {
        // Arrange — a job retried late must not decide the fee. Both rows exist; the reading
        // walks them in the order they arrived.
        [, $parcel] = $this->parcelAsking('141.00');

        NawrisWebhookEvent::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => $this->statusEvent(3, 156),
        ]);
        NawrisWebhookEvent::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => $this->edit(161, ['amount_to_be_collected' => ['old' => 170, 'new' => 161]]),
        ]);

        // Act
        $terms = app(ReadNawrisParcelTerms::class)($parcel);

        // Assert
        $this->assertSame('15.00', $terms->fee);
    }

    // ── who pays it ──────────────────────────────────────────────────────────────────────

    public function test_when_we_pay_the_fee_the_whole_door_amount_is_ours(): void
    {
        // Arrange — parcel 4494495, Misrata: 44 asked, 64 at the door, then flipped to 2 (event
        // 282 — under status 1, which is why it is read before the unmapped-code return).
        [$order, $parcel] = $this->parcelAsking('44.00');
        $this->send($this->statusEvent(1, 64));
        $this->send($this->edit(44, [
            'amount_to_be_collected' => ['old' => 64, 'new' => 44],
            'accept_50_dinar' => ['old' => 0, 'new' => 1],
            'shipment_on_sender' => ['old' => 1, 'new' => '2'],
        ], statusCode: 1));

        // Act
        $this->send($this->statusEvent(7, 44));

        // Assert — 44 is ours; their 20 is our cost, entered when the order is settled.
        $this->assertSame(NawrisParcelTerms::SENDER_PAYS, $parcel->fresh()->shipment_on_sender);
        $this->assertSame('20.00', (string) $parcel->fresh()->carrier_fee);
        $this->assertSame('44.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString('على حساب المرسل', (string) $this->lastEvent()->error);
        $this->assertStringContainsString('(20.00)', (string) $this->lastEvent()->error);
    }

    public function test_switched_to_us_with_nothing_at_the_door_pays_nothing(): void
    {
        // Arrange — parcels 4430795, 4448469, 4494496, 4564323: flipped to 2 with the door amount
        // set to 0. The customer handed over nothing; the old code paid the full 165.
        [$order] = $this->parcelAsking('165.00');
        $this->send($this->statusEvent(4, 180));
        $this->send($this->edit(0, [
            'amount_to_be_collected' => ['old' => 180, 'new' => 0],
            'shipment_on_sender' => ['old' => 1, 'new' => '2'],
        ]));

        // Act
        $this->send($this->statusEvent(7, 0));

        // Assert
        $order->refresh();
        $this->assertSame('0.00', (string) $order->paid_amount);
        $this->assertSame('165.00', $order->remainingAmount());
        $this->assertStringContainsString('نقص في التحصيل: بقي على الطلبية 165.00', (string) $this->lastEvent()->error);
    }

    public function test_flipped_back_to_the_customer_the_fee_comes_off_again(): void
    {
        // Arrange — parcel 4494495 again: to 2 (event 282), then back to 1 (event 325).
        [$order] = $this->parcelAsking('185.00');
        $this->send($this->statusEvent(1, 205));
        $this->send($this->edit(185, [
            'amount_to_be_collected' => ['old' => 205, 'new' => 185],
            'shipment_on_sender' => ['old' => 1, 'new' => '2'],
        ], statusCode: 1));
        $this->send($this->edit(205, [
            'amount_to_be_collected' => ['old' => 185, 'new' => 205],
            'shipment_on_sender' => ['old' => 2, 'new' => '1'],
        ]));

        // Act
        $this->send($this->statusEvent(7, 205));

        // Assert
        $this->assertSame('185.00', (string) $order->fresh()->paid_amount);
        $this->assertNull($this->lastEvent()->error);
    }

    public function test_a_value_we_cannot_read_pays_nothing(): void
    {
        // Arrange — anything but 1 or 2 is a meaning nobody has told us.
        [$order] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(4, 156));
        $this->send($this->edit(156, ['shipment_on_sender' => ['old' => 1, 'new' => '3']]));

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert
        $this->assertSame('0.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString('غير معروفة (3)', (string) $this->lastEvent()->error);
        $this->assertStringContainsString('حصّل المندوب 156.00؛ بعد أجرة نورس (15.00) يبقى لنا 141.00', (string) $this->lastEvent()->error);
    }

    // ── after delivery ───────────────────────────────────────────────────────────────────

    public function test_a_second_delivery_at_a_new_amount_moves_no_money_and_says_so(): void
    {
        // Arrange — parcel 4600741: asked 415, door 435, delivered at 435 (event 586), then cut to
        // 280 (event 587, parked) and delivered again at 280 (event 588).
        [$order] = $this->parcelAsking('415.00');
        $this->send($this->statusEvent(4, 435));
        $this->send($this->statusEvent(7, 435));
        $this->send($this->edit(280, ['amount_to_be_collected' => ['old' => 435, 'new' => 280]]));

        // Act
        $this->send($this->statusEvent(7, 280));

        // Assert
        $this->assertSame('415.00', (string) $order->fresh()->paid_amount);
        $this->assertSame(1, OrderPayment::query()->where('order_id', $order->id)->count());
        $this->assertStringContainsString('تغيّر المبلغ بعد التسليم: 435.00 ← 280.00', (string) $this->lastEvent()->error);
    }

    // ── a payment Nawris never heard of ──────────────────────────────────────────────────

    /**
     * 40 paid at the counter after dispatch, with the edit that should have told Nawris never
     * landed — so our parcel still says 200 while the order owes 160.
     */
    private function paidAtTheCounterAfterDispatch(Order $order): void
    {
        app(RecordOrderPayment::class)($order->refresh(), OrderPaymentData::fromArray([
            'amount' => '40.00',
            'method' => PaymentMethod::Cash->value,
        ]), User::factory()->create());
    }

    public function test_a_door_amount_corrected_by_hand_at_nawris_closes_the_order_without_an_alert(): void
    {
        // Arrange — payment 177's story: our edit failed, and hours later someone at Nawris took
        // the 40 off by hand, 220 → 180. Measured against our stale 200 this read as short.
        [$order] = $this->parcelAsking('200.00');
        $this->send($this->statusEvent(4, 220));
        $this->paidAtTheCounterAfterDispatch($order);
        $this->send($this->edit(180, ['amount_to_be_collected' => ['old' => 220, 'new' => 180]]));

        // Act
        $this->send($this->statusEvent(7, 180));

        // Assert — 160 is ours and exactly what was owed.
        $order->refresh();
        $this->assertSame('200.00', (string) $order->paid_amount);
        $this->assertSame('0.00', $order->remainingAmount());
        $this->assertNull($this->lastEvent()->error);
    }

    public function test_a_real_shortfall_on_a_stale_parcel_names_the_real_gap(): void
    {
        // Arrange — nobody corrected it, and the courier came back with 170 of the 220: 150 is
        // ours against 160 owed. The old note read 220 against 170, fifty missing; it is ten.
        [$order] = $this->parcelAsking('200.00');
        $this->send($this->statusEvent(4, 220));
        $this->paidAtTheCounterAfterDispatch($order);

        // Act
        $this->send($this->statusEvent(7, 170));

        // Assert
        $order->refresh();
        $this->assertSame('10.00', $order->remainingAmount());
        $this->assertStringContainsString('نقص في التحصيل: بقي على الطلبية 10.00 (الواصل لنا 150.00)', (string) $this->lastEvent()->error);
    }

    public function test_the_old_amount_collected_anyway_is_capped_and_called_out(): void
    {
        // Arrange — parcel 4600741's story: the customer paid first, Nawris never heard, and the
        // courier took the full door amount. The customer may have paid twice.
        [$order] = $this->parcelAsking('200.00');
        $this->send($this->statusEvent(4, 220));
        $this->paidAtTheCounterAfterDispatch($order);

        // Act
        $this->send($this->statusEvent(7, 220));

        // Assert
        $order->refresh();
        $this->assertSame('200.00', (string) $order->paid_amount);
        $this->assertStringContainsString('تحصيل زائد: الواصل لنا 200.00 والمتبقي على الطلبية 160.00', (string) $this->lastEvent()->error);
    }

    // ── a move to another city ───────────────────────────────────────────────────────────

    public function test_a_move_to_another_city_makes_the_fee_unknown(): void
    {
        // Arrange — their fee is the city's: Tripoli's 15 says nothing about Misrata.
        [$order, $parcel] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(4, 156));
        $this->send($this->edit(161, [
            'government_id' => ['old' => 4, 'new' => '9', 'old_name' => 'طرابلس', 'new_name' => 'مصراتة'],
            'amount_to_be_collected' => ['old' => 156, 'new' => 161],
        ]));

        // Act
        $this->send($this->statusEvent(7, 161));

        // Assert
        $this->assertNull($parcel->fresh()->carrier_fee);
        $this->assertSame('0.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString('نُقل الطرد لدى نورس إلى مدينة أخرى', (string) $this->lastEvent()->error);
        // The old city's fee is quoted, and said to be the old city's.
        $this->assertStringContainsString('حصّل المندوب 161.00؛ بأجرة المدينة السابقة (15.00) يبقى لنا 146.00', (string) $this->lastEvent()->error);
    }

    public function test_a_move_that_leaves_exactly_the_debt_by_the_old_fee_is_paid_and_flagged(): void
    {
        // Arrange — the city changed, the door amount did not: 156 less Tripoli's 15 is exactly
        // the 141 owed. Paid, and a person checks it.
        [$order, $parcel] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(4, 156));
        $this->send($this->edit(156, [
            'government_id' => ['old' => 4, 'new' => '9', 'old_name' => 'طرابلس', 'new_name' => 'مصراتة'],
        ]));

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert — the fee itself stays unknown; only the payment trusted the match.
        $this->assertNull($parcel->fresh()->carrier_fee);
        $this->assertSame('141.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString(
            'نُقل الطرد لدى نورس إلى مدينة أخرى، والمبلغ مطابق بأجرة المدينة السابقة (15.00) — سُجّلت الدفعة، راجِعها',
            (string) $this->lastEvent()->error,
        );
    }

    public function test_a_move_while_we_pay_the_fee_is_paid_and_flagged(): void
    {
        // Arrange — with the fee on us the door amount is ours whatever the city; the move is
        // still worth a look.
        [$order] = $this->parcelAsking('44.00');
        $this->send($this->statusEvent(1, 64));
        $this->send($this->edit(44, [
            'amount_to_be_collected' => ['old' => 64, 'new' => 44],
            'shipment_on_sender' => ['old' => 1, 'new' => '2'],
        ], statusCode: 1));
        $this->send($this->edit(44, [
            'government_id' => ['old' => 9, 'new' => '12', 'old_name' => 'مصراتة', 'new_name' => 'الخمس'],
        ]));

        // Act
        $this->send($this->statusEvent(7, 44));

        // Assert
        $this->assertSame('44.00', (string) $order->fresh()->paid_amount);
        $this->assertStringContainsString('سُجّلت الدفعة بما حصّله المندوب، راجِعها', (string) $this->lastEvent()->error);
    }

    public function test_a_new_id_for_the_same_city_keeps_the_fee(): void
    {
        // Arrange — event 378: their ids re-mapped, 4 → 232, «طرابلس» both sides.
        [$order, $parcel] = $this->parcelAsking('141.00');
        $this->send($this->statusEvent(4, 156));
        $this->send($this->edit(156, [
            'government_id' => ['old' => 4, 'new' => '232', 'old_name' => 'طرابلس', 'new_name' => 'طرابلس'],
            'area_id' => ['old' => 271, 'new' => '186', 'old_name' => 'غوط الشعال(s23)', 'new_name' => 'غوط الشعال(s23)'],
        ]));

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert
        $this->assertSame('15.00', (string) $parcel->fresh()->carrier_fee);
        $this->assertSame('141.00', (string) $order->fresh()->paid_amount);
    }

    // ── our edits ────────────────────────────────────────────────────────────────────────

    public function test_our_edit_keeps_a_switch_to_us_made_at_nawris(): void
    {
        // Arrange — every edit re-sends the whole payload. Sending 0 regardless would put the fee
        // back on a customer someone at Nawris had taken it off. Their API counts one lower than
        // their webhooks: webhook 2 is API 1.
        config()->set('services.nawris.authentication_key', 'key');
        config()->set('services.nawris.main_client_code', 'client');
        config()->set('services.nawris.base_url', 'https://carrier.test/external-api/');
        Http::fake(['*' => Http::response(['success' => 1, 'result' => []], 200)]);
        [, $parcel] = $this->parcelAsking('141.00');
        $parcel->forceFill(['shipment_on_sender' => NawrisParcelTerms::SENDER_PAYS])->save();

        // Act
        app(EditNawrisParcel::class)($parcel);

        // Assert
        Http::assertSent(fn ($request) => $request->data()['shipment_on_sender'] === 1);
    }

    public function test_our_edit_sends_the_customer_when_nothing_was_switched(): void
    {
        // Arrange
        config()->set('services.nawris.authentication_key', 'key');
        config()->set('services.nawris.main_client_code', 'client');
        config()->set('services.nawris.base_url', 'https://carrier.test/external-api/');
        Http::fake(['*' => Http::response(['success' => 1, 'result' => []], 200)]);
        [, $parcel] = $this->parcelAsking('141.00');

        // Act
        app(EditNawrisParcel::class)($parcel);

        // Assert
        Http::assertSent(fn ($request) => $request->data()['shipment_on_sender'] === 0);
    }

    // ── a shared parcel ──────────────────────────────────────────────────────────────────

    public function test_a_shared_parcel_that_came_back_short_is_left_to_a_person(): void
    {
        // Arrange — two orders, 100 and 41, in one parcel asking 141; fee 15. Short by 6, and no
        // rule says which order lost it.
        [$first, $parcel] = $this->parcelAsking('100.00');
        $parcel->forceFill(['amount_to_collect' => '141.00'])->save();

        $second = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'items_total' => '41.00',
            'delivery_price' => '0.00',
            'grand_total' => '41.00',
        ]);
        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $second->id,
            'amount_to_collect' => '41.00',
        ]);
        $this->send($this->statusEvent(4, 156));

        // Act
        $this->send($this->statusEvent(7, 150));

        // Assert
        $this->assertSame('0.00', (string) $first->fresh()->paid_amount);
        $this->assertSame('0.00', (string) $second->fresh()->paid_amount);
        $this->assertStringContainsString('طرد مشترك وصل ناقصاً', (string) $this->lastEvent()->error);
    }

    public function test_a_shared_parcel_that_came_back_whole_pays_each_its_share(): void
    {
        // Arrange
        [$first, $parcel] = $this->parcelAsking('100.00');
        $parcel->forceFill(['amount_to_collect' => '141.00'])->save();

        $second = Order::factory()->create([
            'status' => OrderStatus::OutForDelivery,
            'items_total' => '41.00',
            'delivery_price' => '0.00',
            'grand_total' => '41.00',
        ]);
        NawrisParcelOrder::factory()->create([
            'nawris_parcel_id' => $parcel->id,
            'order_id' => $second->id,
            'amount_to_collect' => '41.00',
        ]);
        $this->send($this->statusEvent(4, 156));

        // Act
        $this->send($this->statusEvent(7, 156));

        // Assert
        $this->assertSame('100.00', (string) $first->fresh()->paid_amount);
        $this->assertSame('41.00', (string) $second->fresh()->paid_amount);
    }

    // ── the record ───────────────────────────────────────────────────────────────────────

    public function test_an_edit_that_only_flips_who_pays_is_not_thrown_away_as_a_duplicate(): void
    {
        // Arrange — the same status, reference, code and door amount as an earlier event; only
        // `changes` differs. Without it in the fingerprint the flip would be dropped.
        [, $parcel] = $this->parcelAsking('141.00');
        $this->send($this->edit(156, ['area_id' => ['old' => 271, 'new' => '186']]));

        // Act
        $this->send($this->edit(156, ['shipment_on_sender' => ['old' => 1, 'new' => '2']]));

        // Assert
        $this->assertSame(2, NawrisWebhookEvent::query()->count());
        $this->assertSame(NawrisParcelTerms::SENDER_PAYS, $parcel->fresh()->shipment_on_sender);
    }

    public function test_the_command_reports_without_writing_and_writes_when_told(): void
    {
        // Arrange — a parcel whose history holds its fee, read before this column existed.
        [, $parcel] = $this->parcelAsking('141.00');
        NawrisWebhookEvent::factory()->processed()->create([
            'nawris_parcel_id' => $parcel->id,
            'payload' => $this->statusEvent(4, 156),
        ]);

        // Act & Assert — the report alone writes nothing.
        $this->artisan('nawris:read-carrier-terms')->assertSuccessful();
        $this->assertNull($parcel->fresh()->carrier_fee);

        $this->artisan('nawris:read-carrier-terms', ['--write' => true])->assertSuccessful();
        $this->assertSame('15.00', (string) $parcel->fresh()->carrier_fee);
        $this->assertSame(NawrisParcelTerms::CUSTOMER_PAYS, $parcel->fresh()->shipment_on_sender);
    }
}
