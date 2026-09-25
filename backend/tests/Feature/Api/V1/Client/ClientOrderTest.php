<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\ProductImage;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\CustomerOrderStage;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The customer's own orders, as the app reads them.
 *
 * **Two things are being asserted here, and the second is the interesting one.**
 *
 * That a customer sees only their own orders — with no customer id anywhere in the path, so the
 * confinement is the controller resolving through the token and nothing else.
 *
 * And that the workshop's nineteen statuses reach the app as eight stages. «قيد التصنيع»
 * announces that we did not make it ourselves; «نواقص» is our shelf being short; «انتظار
 * العربون» is the shop arguing about money through a status label. None of those belong on a
 * customer's phone, and `test_every_workshop_status_reaches_the_app_as_a_stage` is the sweep
 * that stops the next one added from getting there.
 *
 * Arrange - Act - Assert throughout.
 */
class ClientOrderTest extends TestCase
{
    use RefreshDatabase;

    private function customer(string $phone = '0911111111'): Customer
    {
        return Customer::factory()->registered()->create(['phone' => $phone]);
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    // ─────────────────────────── my orders ───────────────────────────

    public function test_the_list_shows_only_my_own_orders(): void
    {
        // Arrange
        $me = $this->customer();
        $mine = Order::factory()->create(['customer_id' => $me->id]);
        $theirs = Order::factory()->create(['customer_id' => $this->customer('0922222222')->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $mine->id);

        $ids = array_column((array) $response->json('data'), 'id');
        $this->assertNotContains($theirs->id, $ids);
    }

    public function test_the_list_is_newest_first_and_paginated(): void
    {
        // Arrange
        $me = $this->customer();
        $older = Order::factory()->create(['customer_id' => $me->id]);
        $newer = Order::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.id', $newer->id)
            ->assertJsonPath('data.1.id', $older->id)
            ->assertJsonStructure(['data', 'meta' => ['current_page', 'per_page', 'total']]);
    }

    public function test_the_list_can_be_narrowed_to_the_orders_still_moving(): void
    {
        // Arrange
        $me = $this->customer();
        $open = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Printing]);
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Settled]);
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Cancelled]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders?open=1');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $open->id);
    }

    public function test_a_ready_order_is_not_under_the_in_progress_chip(): void
    {
        // Arrange — «جاهزة» has its own chip, and a chip that contains its neighbour is two
        // chips answering one question. A ready order is still `is_open`; it is just not one we
        // are still working on.
        $me = $this->customer();
        $working = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Printing]);
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Ready]);
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::OfficePickup]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders?open=1');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $working->id);
    }

    public function test_a_ready_order_still_says_it_is_open(): void
    {
        // Arrange — the exclusion above is a chip's business, not the vocabulary's. Nobody has
        // taken delivery of a ready order and nobody wrote it off, and the badge, the card's
        // accent and `PagedCubit.belongs` all read `is_open`.
        $me = $this->customer();
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Ready]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()->assertJsonPath('data.0.is_open', true);
    }

    public function test_the_list_can_be_narrowed_to_one_stage(): void
    {
        // Arrange — «جاهزة» is two workshop statuses, and «استلام مكتب» is the one a hand-kept
        // list of statuses in the controller would have missed.
        $me = $this->customer();
        $ready = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Ready]);
        $pickup = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::OfficePickup]);
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Printing]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders?stage=ready');

        // Assert
        $response->assertOk()->assertJsonCount(2, 'data');
        $this->assertEqualsCanonicalizing(
            [$ready->id, $pickup->id],
            array_column($response->json('data'), 'id'),
        );
    }

    public function test_every_stage_can_be_asked_for_and_returns_only_its_own(): void
    {
        // Arrange — the sweep that matters: a stage whose `statuses()` came back empty would
        // silently return every order, because an empty filter is no filter.
        $me = $this->customer();

        foreach (OrderStatus::cases() as $status) {
            Order::factory()->create(['customer_id' => $me->id, 'status' => $status]);
        }

        foreach (CustomerOrderStage::cases() as $stage) {
            // Act
            $response = $this->withHeaders($this->bearerFor($me))
                ->getJson('/api/v1/client/orders?stage='.$stage->value.'&per_page=50');

            // Assert
            $response->assertOk();

            $stages = array_column($response->json('data'), 'stage');

            $this->assertNotEmpty($stages, "«{$stage->label()}» returned nothing");
            $this->assertSame(
                [$stage->value],
                array_values(array_unique($stages)),
                "«{$stage->label()}» let another stage through",
            );
        }
    }

    public function test_a_stage_nobody_has_heard_of_is_no_filter_rather_than_an_empty_list(): void
    {
        // Arrange — a newer app talking to an older server. Showing the customer their whole
        // list is better than an empty one they read as «طلبياتي اختفت».
        $me = $this->customer();
        Order::factory()->count(3)->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson('/api/v1/client/orders?stage=teleported');

        // Assert
        $response->assertOk()->assertJsonCount(3, 'data');
    }

    public function test_stage_wins_over_open_because_it_is_the_narrower_question(): void
    {
        // Arrange
        $me = $this->customer();
        $delivered = Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Delivered]);
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Printing]);

        // Act — «مكتملة» and «قيد التنفيذ» at once; the narrower answer is the only one that is
        // not arbitrary.
        $response = $this->withHeaders($this->bearerFor($me))
            ->getJson('/api/v1/client/orders?open=1&stage=delivered');

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $delivered->id);
    }

    public function test_the_stage_carries_the_sentence_that_goes_under_it(): void
    {
        // Arrange — the line «طلباتي» draws under every card. It is the server's, so a stage
        // added to the business gets its sentence without an app release.
        $me = $this->customer();
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Requested]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()->assertJsonPath(
            'data.0.stage_hint',
            CustomerOrderStage::UnderReview->hint(),
        );
    }

    public function test_a_finished_order_is_sent_no_reassuring_sentence(): void
    {
        // Arrange — «تم الاستلام» is over, and a line of comfort under a delivered order is
        // filler. The design draws none either.
        $me = $this->customer();
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Delivered]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()->assertJsonPath('data.0.stage_hint', null);
    }

    public function test_every_stage_that_is_still_moving_has_a_sentence(): void
    {
        // Arrange - Act - Assert — the sweep. A stage added to the business without a `hint()`
        // arm would fail the build in `hint()` itself; this catches one given `null` by mistake.
        foreach (CustomerOrderStage::cases() as $stage) {
            if (! $stage->isOpen()) {
                continue;
            }

            $this->assertNotNull($stage->hint(), "«{$stage->label()}» has nothing to say");
        }
    }

    // ─────────────────────── the words the app is sent ───────────────────────

    /**
     * @param  OrderStatus  $status  what the workshop calls it
     * @param  CustomerOrderStage  $stage  what the customer is told
     */
    #[DataProvider('statusesAndTheStagesTheyRead')]
    public function test_a_workshop_status_reaches_the_app_as_its_stage(
        OrderStatus $status,
        CustomerOrderStage $stage,
    ): void {
        // Arrange
        $me = $this->customer();
        Order::factory()->create(['customer_id' => $me->id, 'status' => $status]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.stage', $stage->value)
            ->assertJsonPath('data.0.stage_label', $stage->label());
    }

    /**
     * @return array<string, array{OrderStatus, CustomerOrderStage}>
     */
    public static function statusesAndTheStagesTheyRead(): array
    {
        return [
            'a request nobody has read' => [OrderStatus::Requested, CustomerOrderStage::UnderReview],
            'taken by a clerk' => [OrderStatus::New, CustomerOrderStage::Preparing],
            'our shelf came up short' => [OrderStatus::Shortage, CustomerOrderStage::Preparing],
            'we are waiting on a deposit' => [OrderStatus::AwaitingDeposit, CustomerOrderStage::Preparing],
            'handed to the press' => [OrderStatus::ReadyToPrint, CustomerOrderStage::Preparing],
            'artwork being agreed' => [OrderStatus::Designing, CustomerOrderStage::Designing],
            'our own press' => [OrderStatus::Printing, CustomerOrderStage::Producing],
            'somebody else made it' => [OrderStatus::Manufacturing, CustomerOrderStage::Producing],
            'on the shelf' => [OrderStatus::Ready, CustomerOrderStage::Ready],
            'waiting at the counter' => [OrderStatus::OfficePickup, CustomerOrderStage::Ready],
            'with the courier' => [OrderStatus::OutForDelivery, CustomerOrderStage::OnTheWay],
            'in their hands' => [OrderStatus::Delivered, CustomerOrderStage::Delivered],
            'and our books agree' => [OrderStatus::Settled, CustomerOrderStage::Delivered],
            'came back from the courier' => [OrderStatus::ReturnedCourier, CustomerOrderStage::Returned],
            'written off' => [OrderStatus::Cancelled, CustomerOrderStage::Cancelled],
        ];
    }

    /**
     * **The sweep.** Every status must have been given a stage deliberately — the day a new one
     * is added, this fails rather than the raw English key appearing on somebody's phone.
     */
    public function test_every_workshop_status_reaches_the_app_as_a_stage(): void
    {
        // Act
        $unmapped = array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => trim(CustomerOrderStage::forStatus($s)->label()) === '',
        );

        // Assert
        $this->assertSame([], array_values($unmapped));
    }

    /**
     * The workshop's own words must not travel, in any field, at any depth. «قيد التصنيع» tells
     * the customer we outsourced their job; «نواقص» tells them our shelf was empty.
     */
    public function test_the_workshop_vocabulary_never_reaches_the_app(): void
    {
        // Arrange
        $me = $this->customer();
        Order::factory()->create(['customer_id' => $me->id, 'status' => OrderStatus::Manufacturing]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()
            ->assertDontSee('manufacturing')
            ->assertDontSee('قيد التصنيع')
            ->assertDontSee('ready_to_print');
    }

    // ─────────────────────────── the card ───────────────────────────

    /**
     * صفّ «طلباتي» يُرسم ببطاقة تطبيق الموظفين: المال في ثلاث خانات، ومكان الاستلام ورقمه، وبنود
     * الطلبية في ذيلها (طلب المستخدم، 2026-09-25). **ولا شيء منها جديدٌ على العميل**: كلها تصله
     * أصلاً حين يفتح طلبيته. القائمة تحملها كي لا يُفتح كل صفٍّ ليُرسم.
     */
    public function test_a_row_carries_what_its_card_draws(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create([
            'customer_id' => $me->id,
            'city_name' => 'بنغازي',
            'recipient_phone' => '0913333333',
        ]);
        OrderItem::factory()->create([
            'order_id' => $order->id,
            'product_name' => 'أكياس شحن - مطبوعة',
            'variant_label' => '30*40',
            'quantity' => '500.000',
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.city_name', 'بنغازي')
            ->assertJsonPath('data.0.recipient_phone', '0913333333')
            ->assertJsonPath('data.0.fulfilment_type', $order->fulfilment_type->value)
            ->assertJsonPath('data.0.fulfilment_type_label', $order->fulfilment_type->label())
            ->assertJsonPath('data.0.items.0.product_name', 'أكياس شحن - مطبوعة')
            ->assertJsonPath('data.0.items.0.variant_label', '30*40')
            ->assertJsonPath('data.0.items.0.quantity', '500.000')
            ->assertJsonStructure(['data' => [['paid_amount', 'balance']]]);
    }

    /**
     * «300» وحدها لا تقول 300 ماذا: كيسٌ يُباع بالقطعة وآخر بالكيلو. الوحدة تُرسل بكلمتها
     * العربية مع كل بند، في القائمة وفي الطلبية معاً.
     */
    public function test_a_line_says_what_its_quantity_is_counted_in(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id]);
        OrderItem::factory()->create(['order_id' => $order->id, 'pricing_unit' => PricingUnit::Piece]);

        // Act
        $list = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');
        $one = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $list->assertOk()->assertJsonPath('data.0.items.0.pricing_unit_label', PricingUnit::Piece->label());
        $one->assertOk()->assertJsonPath('data.items.0.pricing_unit_label', PricingUnit::Piece->label());
    }

    /**
     * طلبيةٌ فيها بندٌ لم يُسعَّر: مجموعها المخزَّن أصغر مما ستبلغه، فلا يُرسل من مالها شيء — في
     * القائمة كما في الطلبية نفسها. البطاقة تكتب «يُحدَّد بعد المراجعة».
     */
    public function test_a_row_awaiting_a_quote_sends_no_money_at_all(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->status(OrderStatus::Requested)->create(['customer_id' => $me->id]);
        OrderItem::factory()->create([
            'order_id' => $order->id,
            'unit_price' => null,
            'line_total' => null,
        ]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.0.is_awaiting_quote', true)
            ->assertJsonPath('data.0.total', null)
            ->assertJsonPath('data.0.paid_amount', null)
            ->assertJsonPath('data.0.balance', null);
    }

    /** القائمة صارت تحمل البنود، فتُمسك هنا بما تُمسك به الطلبية الواحدة. */
    public function test_a_row_never_carries_the_cost_or_the_profit(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id]);
        OrderItem::factory()->create(['order_id' => $order->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/orders');

        // Assert
        $response->assertOk()
            ->assertDontSee('unit_cost')
            ->assertDontSee('profit')
            ->assertDontSee('cost_price');
    }

    // ─────────────────────────── one order ───────────────────────────

    public function test_one_order_carries_its_lines_and_what_is_owed(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.id', $order->id)
            ->assertJsonPath('data.code', $order->code)
            ->assertJsonStructure(['data' => ['total', 'paid_amount', 'balance', 'items', 'timeline']]);
    }

    /**
     * كل بندٍ في الطلبية المفتوحة يُرسم بصورة منتجه: الصورة الأولى في الكتالوج اليوم، كما يرسمها
     * سطر الطلبية في تطبيق الموظفين — لا جزءاً من لقطة البند، فالفاتورة تبقى تقول ما بيع.
     */
    public function test_an_opened_order_draws_each_line_with_its_product_photo(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id]);
        $item = OrderItem::factory()->create(['order_id' => $order->id]);
        $photo = ProductImage::factory()->primary()->create(['product_id' => $item->product_id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.items.0.product_image_url', $photo->url());
    }

    /** منتجٌ بلا صورة يُرسل null، فيرسم التطبيق مكانها شكل الكيس بدل صورةٍ مكسورة. */
    public function test_a_line_whose_product_has_no_photo_sends_null(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id]);
        OrderItem::factory()->create(['order_id' => $order->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.items.0.product_image_url', null);
    }

    /**
     * **What stands in for `scoped()`.** No customer id is in the path, so the controller's own
     * lookup is the only thing between one customer and another's order.
     */
    public function test_another_customers_order_is_a_404(): void
    {
        // Arrange
        $me = $this->customer();
        $theirs = Order::factory()->create(['customer_id' => $this->customer('0922222222')->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$theirs->id}");

        // Assert
        $response->assertNotFound();
    }

    /**
     * The shop's profit on this order, what the goods cost it, and what staff wrote to each
     * other about it are all a `$request->user()->can()` away on the staff resource — and a
     * customer has no `can()` at all.
     */
    public function test_one_order_never_carries_the_cost_or_the_profit(): void
    {
        // Arrange
        $me = $this->customer();
        $order = Order::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/orders/{$order->id}");

        // Assert
        $response->assertOk()
            ->assertDontSee('unit_cost')
            ->assertDontSee('profit')
            ->assertDontSee('cost_price');
    }

    // ─────────────────────────── the guard ───────────────────────────

    public function test_my_orders_need_a_customer_token(): void
    {
        // Act
        $response = $this->getJson('/api/v1/client/orders');

        // Assert
        $response->assertUnauthorized();
    }

    public function test_a_staff_token_cannot_read_the_customer_order_list(): void
    {
        // Arrange
        $staff = ['Authorization' => 'Bearer '.User::factory()->create()->createToken('s')->plainTextToken];

        // Act
        $response = $this->withHeaders($staff)->getJson('/api/v1/client/orders');

        // Assert
        $response->assertUnauthorized();
    }
}
