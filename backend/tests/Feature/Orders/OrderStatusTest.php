<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Enums\OrderStatus;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * The state machine, asserted as a whole rather than one path at a time.
 *
 * **This file is the specification.** The transition map lives in one `match` on the enum, and
 * everything else — the API, the permission each move needs, the buttons the app draws — reads
 * it from there. So the map is worth pinning exhaustively: the tests below state every legal
 * move for every status, which means adding a status or loosening a rule shows up here as a
 * failing assertion naming exactly what changed, instead of as a surprise in production three
 * screens away.
 *
 * The structural tests at the bottom are the ones that earn their keep when somebody adds a
 * thirteenth status: they fail if it has no label, no permission, no way in, or a way out that
 * names something that does not exist.
 *
 * Arrange - Act - Assert throughout.
 */
class OrderStatusTest extends TestCase
{
    /**
     * Every legal move in the business, written out.
     *
     * @return array<string, array{0: OrderStatus, 1: list<OrderStatus>}>
     */
    public static function transitions(): array
    {
        return [
            'a new order is designed, or goes straight to print — and nothing else' => [
                OrderStatus::New,
                [OrderStatus::Designing, OrderStatus::Printing],
            ],
            'a design must pass through printing — never straight to ready' => [
                OrderStatus::Designing,
                [OrderStatus::Printing, OrderStatus::Cancelled],
            ],
            'printing ends ready or short, and may go back to the drawing board' => [
                OrderStatus::Printing,
                [OrderStatus::Ready, OrderStatus::Shortage, OrderStatus::Designing, OrderStatus::Cancelled],
            ],
            'a shortage is printed again, or resolved into ready' => [
                OrderStatus::Shortage,
                [OrderStatus::Printing, OrderStatus::Ready, OrderStatus::Cancelled],
            ],
            'ready leaves for the customer, or falls back' => [
                OrderStatus::Ready,
                [
                    OrderStatus::OfficePickup, OrderStatus::OutForDelivery,
                    OrderStatus::Shortage, OrderStatus::Printing, OrderStatus::Cancelled,
                ],
            ],
            'an order waiting at the counter is collected or cancelled — never returned' => [
                OrderStatus::OfficePickup,
                [OrderStatus::Delivered, OrderStatus::Cancelled],
            ],
            'an order on the road either arrives or comes back to the courier who carried it' => [
                OrderStatus::OutForDelivery,
                [OrderStatus::Delivered, OrderStatus::ReturnedCourier],
            ],
            'a parcel the courier still holds goes back to the company that sent him' => [
                OrderStatus::ReturnedCourier,
                [OrderStatus::ReturnedCarrier],
            ],
            'and from the company, back to our own office' => [
                OrderStatus::ReturnedCarrier,
                [OrderStatus::ReturnedOffice],
            ],
            'back on our shelf: collected here, sent out again, or written off' => [
                OrderStatus::ReturnedOffice,
                [OrderStatus::Delivered, OrderStatus::Resend, OrderStatus::Cancelled],
            ],
            'a re-send leaves the same two ways any order leaves' => [
                OrderStatus::Resend,
                [OrderStatus::OfficePickup, OrderStatus::OutForDelivery, OrderStatus::Cancelled],
            ],
            'the customer has it — all that is left is the money' => [
                OrderStatus::Delivered,
                [OrderStatus::Settled],
            ],
            'a settled order is finished' => [OrderStatus::Settled, []],
            'a cancelled order is finished' => [OrderStatus::Cancelled, []],
        ];
    }

    /**
     * @param  list<OrderStatus>  $expected
     */
    #[DataProvider('transitions')]
    public function test_the_transition_map_is_exactly_what_the_business_agreed(
        OrderStatus $from,
        array $expected,
    ): void {
        // Act
        $allowed = $from->allowedNext();

        // Assert — order-insensitive, because the map is a set and rearranging it is not a
        // behaviour change.
        $this->assertEqualsCanonicalizing($expected, $allowed);
    }

    // ─────────────────────────── the rules behind the map ───────────────────────────

    public function test_a_design_can_never_skip_printing(): void
    {
        // Act
        $allowed = OrderStatus::Designing->allowedNext();

        // Assert — the one rule stated outright when the flow was described.
        $this->assertNotContains(OrderStatus::Ready, $allowed);
        $this->assertNotContains(OrderStatus::Delivered, $allowed);
    }

    public function test_an_office_pickup_order_has_no_return_route(): void
    {
        // Arrange
        $returns = [
            OrderStatus::ReturnedCourier,
            OrderStatus::ReturnedCarrier,
            OrderStatus::ReturnedOffice,
        ];

        // Act
        $allowed = OrderStatus::OfficePickup->allowedNext();

        // Assert — it never left the building: there is no courier and no carrier, and the
        // customer who has not come yet is simply still waiting.
        foreach ($returns as $return) {
            $this->assertNotContains($return, $allowed);
        }
    }

    public function test_a_shortage_is_never_a_dead_end(): void
    {
        // Act
        $allowed = OrderStatus::Shortage->allowedNext();

        // Assert — the gap in the flow as first described: a way in and no way out.
        $this->assertNotEmpty(array_filter($allowed, fn (OrderStatus $s) => ! $s->isFinal()));
    }

    public function test_a_parcel_comes_back_the_way_it_went_out(): void
    {
        // Act
        $chain = [
            OrderStatus::ReturnedCourier->allowedNext(),
            OrderStatus::ReturnedCarrier->allowedNext(),
        ];

        // Assert — one way out of each link, and it is the next link. A return is a chain of
        // custody: the courier hands the parcel back to the company that sent him, and the
        // company hands it back to us. Letting a status skip a link would let the system record
        // a hand-over that never happened.
        $this->assertSame([OrderStatus::ReturnedCarrier], $chain[0]);
        $this->assertSame([OrderStatus::ReturnedOffice], $chain[1]);
    }

    public function test_a_returned_order_can_be_sent_out_again(): void
    {
        // Act
        $allowed = OrderStatus::ReturnedOffice->allowedNext();

        // Assert — the common case, and the one the original flow left out. It is a status of
        // its own rather than a jump straight back onto the road, because «أعيد إرساله» is a
        // question staff ask of a shelf full of returns.
        $this->assertContains(OrderStatus::Resend, $allowed);
        $this->assertEqualsCanonicalizing(
            [OrderStatus::OfficePickup, OrderStatus::OutForDelivery, OrderStatus::Cancelled],
            OrderStatus::Resend->allowedNext(),
        );
    }

    public function test_a_delivered_order_still_owes_its_money(): void
    {
        // Act & Assert — the customer having the bags is not the end of the job: what the
        // courier collected still has to come back and be agreed. «تم الاستلام» is therefore no
        // longer where an order stops — «تم التسوية» is.
        $this->assertFalse(OrderStatus::Delivered->isFinal());
        $this->assertSame([OrderStatus::Settled], OrderStatus::Delivered->allowedNext());

        $this->assertTrue(OrderStatus::Settled->isFinal());
        $this->assertSame([], OrderStatus::Settled->allowedNext());
    }

    public function test_an_order_out_of_our_hands_is_brought_back_before_it_is_written_off(): void
    {
        // Arrange
        $open = array_filter(OrderStatus::cases(), fn (OrderStatus $s) => ! $s->isFinal());

        // Act
        $withoutCancel = array_values(array_map(
            fn (OrderStatus $s) => $s->value,
            array_filter(
                $open,
                fn (OrderStatus $s) => ! in_array(OrderStatus::Cancelled, $s->allowedNext(), true),
            ),
        ));

        // Assert — four exceptions, and each is the same rule seen from a different place:
        // nothing is written off while it is somebody else's problem. «جديدة» has cost nothing
        // yet and is two taps from being started; the parcel on the road and the two returns in
        // transit are physically outside the building, so they come back to «راجع مكتب» first
        // and are cancelled from there; «تم الاستلام» is past the point of being written off —
        // it is settled or it is disputed, not cancelled.
        $this->assertEqualsCanonicalizing([
            OrderStatus::New->value,
            OrderStatus::OutForDelivery->value,
            OrderStatus::ReturnedCourier->value,
            OrderStatus::ReturnedCarrier->value,
            OrderStatus::Delivered->value,
        ], $withoutCancel);
    }

    public function test_only_an_order_the_customer_can_reach_can_be_delivered(): void
    {
        // Act
        $canDeliver = array_values(array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => in_array(OrderStatus::Delivered, $s->allowedNext(), true),
        ));

        // Assert — nothing jumps from the shelf to the customer's hands. «راجع مكتب» is on the
        // list for a real reason: a parcel that came back is sitting at the counter, and the
        // customer coming in for it is the happiest ending it has left.
        $this->assertEqualsCanonicalizing(
            [OrderStatus::OfficePickup, OrderStatus::OutForDelivery, OrderStatus::ReturnedOffice],
            $canDeliver,
        );
    }

    // ──────────────────────── who the server picks, not the clerk ────────────────────────

    public function test_where_an_order_goes_when_it_leaves_is_decided_by_the_city(): void
    {
        // Act
        $pickup = OrderStatus::dispatchFor(FulfilmentType::OfficePickup);
        $delivery = OrderStatus::dispatchFor(FulfilmentType::Delivery);

        // Assert
        $this->assertSame(OrderStatus::OfficePickup, $pickup);
        $this->assertSame(OrderStatus::OutForDelivery, $delivery);
    }

    public function test_both_ways_of_leaving_the_workshop_are_marked_as_such(): void
    {
        // Act & Assert
        $this->assertTrue(OrderStatus::OfficePickup->isDispatch());
        $this->assertTrue(OrderStatus::OutForDelivery->isDispatch());
        $this->assertFalse(OrderStatus::Ready->isDispatch());
    }

    /**
     * The clerk presses one button and the server decides which of the two it meant, so the two
     * must cost the same permission — otherwise the same button works for طرابلس and fails for
     * قرجي with nothing on screen to explain it.
     */
    public function test_leaving_the_workshop_costs_one_permission_whichever_way_it_goes(): void
    {
        // Act
        $pickup = OrderStatus::OfficePickup->permission();
        $delivery = OrderStatus::OutForDelivery->permission();

        // Assert
        $this->assertSame($pickup, $delivery);
        $this->assertSame(PermissionName::DispatchOrders, $pickup);
    }

    public function test_each_return_is_recorded_by_whoever_actually_sees_it(): void
    {
        // Act
        $permissions = [
            OrderStatus::ReturnedCourier->permission(),
            OrderStatus::ReturnedCarrier->permission(),
            OrderStatus::ReturnedOffice->permission(),
        ];

        // Assert — unlike dispatch, a clerk *chooses* which of these happened, so they are
        // three separate grants: the office desk is not the delivery coordinator.
        $this->assertCount(3, array_unique(array_map(fn (PermissionName $p) => $p->value, $permissions)));
    }

    // ─────────────────────────────── what a move records ───────────────────────────────

    public function test_only_writing_an_order_off_demands_an_explanation(): void
    {
        // Act
        $demanding = array_values(array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => $s->requiresReason(),
        ));

        // Assert
        $this->assertSame([OrderStatus::Cancelled], $demanding);
    }

    public function test_each_milestone_stamps_its_own_column(): void
    {
        // Act & Assert — the columns reports are built from, so a typo here is a silently
        // empty chart rather than an error.
        $this->assertSame('placed_at', OrderStatus::New->timestampColumn());
        $this->assertSame('printing_started_at', OrderStatus::Printing->timestampColumn());
        $this->assertSame('dispatched_at', OrderStatus::OfficePickup->timestampColumn());
        $this->assertSame('dispatched_at', OrderStatus::OutForDelivery->timestampColumn());
        $this->assertSame('returned_at', OrderStatus::ReturnedOffice->timestampColumn());
        $this->assertSame('settled_at', OrderStatus::Settled->timestampColumn());
        $this->assertSame('cancelled_at', OrderStatus::Cancelled->timestampColumn());

        // A shortage is bounced in and out of; stamping it would mean the last one wins and
        // the first is lost. The transitions table already holds every visit. A re-send is the
        // same shape of thing: an order can come back and go out more than once.
        $this->assertNull(OrderStatus::Shortage->timestampColumn());
        $this->assertNull(OrderStatus::Resend->timestampColumn());
    }

    public function test_settling_and_re_sending_each_cost_their_own_permission(): void
    {
        // Act
        $settle = OrderStatus::Settled->permission();
        $resend = OrderStatus::Resend->permission();

        // Assert — money is not the shop floor's job, and putting a returned parcel back on the
        // road is not the accountant's. Neither shares a grant with anything else.
        $this->assertSame(PermissionName::SettleOrders, $settle);
        $this->assertSame(PermissionName::ResendOrders, $resend);

        $shared = array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => $s !== OrderStatus::Settled && $s->permission() === $settle,
        );

        $this->assertSame([], array_values($shared));
    }

    // ─────────────────────── structural: the next status added ───────────────────────

    public function test_every_status_has_an_arabic_label(): void
    {
        // Act
        $missing = array_filter(OrderStatus::cases(), fn (OrderStatus $s) => trim($s->label()) === '');

        // Assert
        $this->assertSame([], array_values($missing));
    }

    public function test_every_status_names_a_permission_that_exists(): void
    {
        // Act
        $unknown = array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => PermissionName::tryFrom($s->permission()->value) === null,
        );

        // Assert
        $this->assertSame([], array_values($unknown));
    }

    public function test_no_status_lists_itself_as_a_next_step(): void
    {
        // Act
        $selfLooping = array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => in_array($s, $s->allowedNext(), true),
        );

        // Assert — re-saving an order is not a transition, and treating it as one would write
        // a meaningless row into the history every time somebody pressed save twice.
        $this->assertSame([], array_values($selfLooping));
    }

    public function test_every_status_except_the_first_can_be_reached(): void
    {
        // Arrange
        $reachable = [];

        foreach (OrderStatus::cases() as $status) {
            foreach ($status->allowedNext() as $next) {
                $reachable[$next->value] = true;
            }
        }

        // Act
        $orphans = array_values(array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => $s !== OrderStatus::New && ! isset($reachable[$s->value]),
        ));

        // Assert — a status nothing leads to is dead code wearing a business name.
        $this->assertSame([], array_map(fn (OrderStatus $s) => $s->value, $orphans));
    }

    public function test_an_order_is_never_created_into_a_status_something_else_leads_to(): void
    {
        // Arrange
        $reachable = [];

        foreach (OrderStatus::cases() as $status) {
            foreach ($status->allowedNext() as $next) {
                $reachable[$next->value] = true;
            }
        }

        // Assert — `new` is the entry point and nothing may return to it, so "has this order
        // been started?" stays answerable.
        $this->assertArrayNotHasKey(OrderStatus::New->value, $reachable);
    }

    public function test_can_move_to_agrees_with_the_map_for_every_pair(): void
    {
        // Arrange
        $disagreements = [];

        // Act — all 144 pairs, so the convenience method can never drift from the map it reads.
        foreach (OrderStatus::cases() as $from) {
            foreach (OrderStatus::cases() as $to) {
                $expected = in_array($to, $from->allowedNext(), true);

                if ($from->canMoveTo($to) !== $expected) {
                    $disagreements[] = "{$from->value} → {$to->value}";
                }
            }
        }

        // Assert
        $this->assertSame([], $disagreements);
    }

    public function test_being_finished_and_being_closed_for_editing_are_two_different_questions(): void
    {
        // Act
        $closed = array_values(array_filter(OrderStatus::cases(), fn (OrderStatus $s) => $s->isClosed()));
        $final = array_values(array_filter(OrderStatus::cases(), fn (OrderStatus $s) => $s->isFinal()));

        // Assert — «تم الاستلام» is the case that forced the two apart: the bags are with the
        // customer, so nothing about the order may be edited any more, but the money has not
        // been agreed yet, so the order is not finished. One flag could not say both.
        $this->assertEqualsCanonicalizing(
            [OrderStatus::Delivered, OrderStatus::Settled, OrderStatus::Cancelled],
            $closed,
        );
        $this->assertEqualsCanonicalizing([OrderStatus::Settled, OrderStatus::Cancelled], $final);

        // Every finished order is closed; the reverse is what is no longer true.
        foreach ($final as $status) {
            $this->assertTrue($status->isClosed(), "{$status->value} is final but not closed");
        }
    }

    public function test_a_final_status_goes_nowhere(): void
    {
        // Act
        $final = array_filter(OrderStatus::cases(), fn (OrderStatus $s) => $s->isFinal());
        $leaking = array_filter($final, fn (OrderStatus $s) => $s->allowedNext() !== []);

        // Assert
        $this->assertNotEmpty($final, 'A machine with no final state never finishes an order.');
        $this->assertSame([], array_values($leaking));
    }
}
