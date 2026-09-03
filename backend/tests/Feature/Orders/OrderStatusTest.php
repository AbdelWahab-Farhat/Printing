<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Enums\OrderFlow;
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
            'a new order is prepped for the press, or found short at intake — and nothing else' => [
                OrderStatus::New,
                [OrderStatus::ReadyToPrint, OrderStatus::Shortage],
            ],
            'the handover leads into the press, either door — or is written off' => [
                OrderStatus::ReadyToPrint,
                [OrderStatus::Designing, OrderStatus::Printing, OrderStatus::Cancelled],
            ],
            'a design must pass through printing — never straight to ready' => [
                OrderStatus::Designing,
                [OrderStatus::Printing, OrderStatus::Cancelled],
            ],
            'printing ends ready, and may go back to the drawing board' => [
                OrderStatus::Printing,
                [OrderStatus::Ready, OrderStatus::Designing, OrderStatus::Cancelled],
            ],
            'a shortage rejoins the route at the handover it was taken off before' => [
                OrderStatus::Shortage,
                [OrderStatus::ReadyToPrint, OrderStatus::Cancelled],
            ],
            'ready leaves for the customer or is written off — the bags exist, so it never goes back' => [
                OrderStatus::Ready,
                [
                    OrderStatus::OfficePickup, OrderStatus::OutForDelivery,
                    OrderStatus::Cancelled,
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
            'from the company, back to our office — or straight out for a second attempt' => [
                OrderStatus::ReturnedCarrier,
                [OrderStatus::ReturnedOffice, OrderStatus::Resend],
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

    // ──────────────────────── the second road, for goods already made ────────────────────────

    /**
     * Every legal move for an order that has nothing to design and nothing to print.
     *
     * **Two arms differ and eleven do not**, which is the claim this provider exists to pin. A
     * parcel comes back from a courier the same way whether it was printed or not; what changes
     * is only the part of the road that *is* the work. See {@see OrderFlow}.
     *
     * @return array<string, array{0: OrderStatus, 1: list<OrderStatus>}>
     */
    public static function unprintedTransitions(): array
    {
        $shared = self::transitions();

        return [
            'goods that are already made go straight to the shelf' => [
                OrderStatus::New,
                [OrderStatus::Ready, OrderStatus::Shortage],
            ],
            'a plain order parked short rejoins at the shelf, not at a design queue' => [
                OrderStatus::Shortage,
                [OrderStatus::Ready, OrderStatus::Cancelled],
            ],
            // The rest, asserted to be *identical* rather than restated: a copy would be a second
            // place to edit, and the point of the flow is that it changes as little as it can.
            'printing is unreachable, but its own arm is untouched' => $shared['printing ends ready, and may go back to the drawing board'],
            'the shelf leaves the same two ways' => $shared['ready leaves for the customer or is written off — the bags exist, so it never goes back'],
            'the road is the same' => $shared['an order on the road either arrives or comes back to the courier who carried it'],
            'the return chain is the same' => $shared['a parcel the courier still holds goes back to the company that sent him'],
            'the depot is the same' => $shared['from the company, back to our office — or straight out for a second attempt'],
            'our shelf is the same' => $shared['back on our shelf: collected here, sent out again, or written off'],
            'a re-send is the same' => $shared['a re-send leaves the same two ways any order leaves'],
            'the money is still owed' => $shared['the customer has it — all that is left is the money'],
            'settled is still the end' => $shared['a settled order is finished'],
            'cancelled is still the end' => $shared['a cancelled order is finished'],
        ];
    }

    /**
     * @param  list<OrderStatus>  $expected
     */
    #[DataProvider('unprintedTransitions')]
    public function test_the_map_for_goods_already_made_is_the_same_road_minus_the_work(
        OrderStatus $from,
        array $expected,
    ): void {
        // Act
        $allowed = $from->allowedNext(OrderFlow::NoProduction);

        // Assert
        $this->assertEqualsCanonicalizing($expected, $allowed);
    }

    /**
     * Every status an order on [$flow] can actually end up in, walked from «جديدة».
     *
     * **Not the union of every status's arms.** `Printing->allowedNext()` still answers on the
     * short road — the arm is simply never consulted, because nothing on that road leads to
     * «قيد الطباعة» in the first place — so unioning the arms would report the press as reachable
     * by reading the map from a status the order can never be standing in.
     *
     * @return list<OrderStatus>
     */
    private static function reachableOn(OrderFlow $flow): array
    {
        $seen = [OrderStatus::New->value => OrderStatus::New];
        $queue = [OrderStatus::New];

        while ($queue !== []) {
            foreach (array_shift($queue)->allowedNext($flow) as $next) {
                if (! isset($seen[$next->value])) {
                    $seen[$next->value] = $next;
                    $queue[] = $next;
                }
            }
        }

        return array_values($seen);
    }

    public function test_the_press_and_the_design_queue_are_unreachable_for_goods_already_made(): void
    {
        // Act
        $reachable = self::reachableOn(OrderFlow::NoProduction);

        // Assert — not merely absent from «جديدة»: absent from the whole road, by walking it. An
        // order of ready-made goods that could reach the press from anywhere would be an order
        // that could be sent to print bags that are already printed.
        $this->assertNotContains(OrderStatus::Designing, $reachable);
        $this->assertNotContains(OrderStatus::Printing, $reachable);

        // And the long road still reaches both, so this is a statement about the short one
        // rather than about a walk that quietly stopped early.
        $this->assertContains(OrderStatus::Designing, self::reachableOn(OrderFlow::Standard));
        $this->assertContains(OrderStatus::Printing, self::reachableOn(OrderFlow::Standard));
    }

    public function test_the_short_road_reaches_every_ending_the_long_one_does(): void
    {
        // Act
        $shortRoad = self::reachableOn(OrderFlow::NoProduction);

        // Assert — dropping two steps must not have stranded anything an order still needs to be
        // able to become: it can still be shelved, sent out, delivered, settled, returned through
        // all three links, re-sent and written off.
        foreach (OrderStatus::cases() as $status) {
            if ($status->isProduction()) {
                continue;
            }

            $this->assertContains(
                $status,
                $shortRoad,
                "«{$status->label()}» cannot be reached by an order of ready-made goods.",
            );
        }
    }

    public function test_the_two_roads_differ_in_exactly_two_places(): void
    {
        // Act
        $differing = array_values(array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => $s->allowedNext() !== $s->allowedNext(OrderFlow::NoProduction),
        ));

        // Assert — the whole cost of the feature, stated as a number. «جديدة» is where the work
        // is dispatched from and «نواقص» is where it is rejoined; nothing else about an order's
        // life depends on whether the press ran. A third entry appearing here is a change worth
        // arguing about rather than one worth discovering later.
        $this->assertEqualsCanonicalizing([OrderStatus::New, OrderStatus::Shortage], $differing);
    }

    public function test_a_shorter_road_is_still_a_road(): void
    {
        // Act
        $line = OrderStatus::mainLine(FulfilmentType::Delivery, OrderFlow::NoProduction);

        // Assert — five steps, in the order they happen, and the two that name work are the two
        // that are gone. A bar drawing «قيد الطباعة» for an order that will never enter it would
        // claim the order is two sevenths of the way through while it sits ready on the shelf.
        $this->assertSame([
            OrderStatus::New,
            OrderStatus::Ready,
            OrderStatus::OutForDelivery,
            OrderStatus::Delivered,
            OrderStatus::Settled,
        ], $line);

        // And the destination still decides the fourth step, exactly as it does on the long road.
        $this->assertContains(
            OrderStatus::OfficePickup,
            OrderStatus::mainLine(FulfilmentType::OfficePickup, OrderFlow::NoProduction),
        );
    }

    public function test_the_shorter_road_introduces_no_new_detour(): void
    {
        // Arrange — what each road can reach, and of that, what its own progress bar cannot place.
        $detoursOn = fn (OrderFlow $flow): array => array_values(array_filter(
            self::reachableOn($flow),
            fn (OrderStatus $s) => $s->mainLinePosition(FulfilmentType::Delivery, $flow) === null,
        ));

        // Act
        $shortRoad = $detoursOn(OrderFlow::NoProduction);
        $longRoad = $detoursOn(OrderFlow::Standard);

        // Assert — a detour is somewhere an order genuinely is but is not a step on the way to
        // anywhere, and both roads have the same ones. **The failure this guards against is
        // specific**: drop a step an order still passes through and that step becomes a detour,
        // so an entirely ordinary order starts drawing an empty bar with nothing marked current.
        // «قيد التصميم» and «قيد الطباعة» may leave the line only because nothing reaches them.
        $this->assertEqualsCanonicalizing($longRoad, $shortRoad);

        // Stated outright too, so the comparison above cannot pass by both roads being wrong.
        $this->assertEqualsCanonicalizing([
            OrderStatus::Shortage,
            OrderStatus::OfficePickup,
            OrderStatus::ReturnedCourier,
            OrderStatus::ReturnedCarrier,
            OrderStatus::ReturnedOffice,
            OrderStatus::Resend,
            OrderStatus::Cancelled,
        ], $shortRoad);
    }

    // ─────────────────────────── the rules behind the map ───────────────────────────

    public function test_the_press_is_entered_through_one_door(): void
    {
        // Arrange — the two statuses the printing department owns.
        $press = [OrderStatus::Designing, OrderStatus::Printing];

        // Act — every status inventory owns, and what it can reach.
        $fromIntake = OrderStatus::New->allowedNext();
        $fromShortage = OrderStatus::Shortage->allowedNext();

        // Assert — **the whole point of «جاهزة للطباعة».** An order used to cross from the
        // warehouse to the press invisibly, so the moment inventory finished was recorded
        // nowhere and the press found out by somebody noticing. Neither of the two statuses
        // inventory owns may reach a production status directly any more.
        foreach ($press as $status) {
            $this->assertNotContains($status, $fromIntake);
            $this->assertNotContains($status, $fromShortage);
        }

        $this->assertContains(OrderStatus::ReadyToPrint, $fromIntake);
        $this->assertContains(OrderStatus::ReadyToPrint, $fromShortage);
    }

    public function test_the_handover_is_reached_from_intake_and_from_a_resolved_shortage(): void
    {
        // Act
        $waysIn = array_values(array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => in_array(OrderStatus::ReadyToPrint, $s->allowedNext(), true),
        ));

        // Assert — the two places an order can be while inventory still has it. Nothing comes
        // *back* to the handover: once the press has the order, finishing it is the press's
        // business and re-handing it over would describe a second delivery that never happened.
        $this->assertEqualsCanonicalizing([OrderStatus::New, OrderStatus::Shortage], $waysIn);
    }

    public function test_a_design_can_never_skip_printing(): void
    {
        // Act
        $allowed = OrderStatus::Designing->allowedNext();

        // Assert — the one rule stated outright when the flow was described.
        $this->assertNotContains(OrderStatus::Ready, $allowed);
        $this->assertNotContains(OrderStatus::Delivered, $allowed);
    }

    public function test_a_finished_run_only_leaves_or_is_written_off(): void
    {
        // Act
        $allowed = OrderStatus::Ready->allowedNext();

        // Assert — «جاهزة» means the bags are made, counted and on the shelf. Two things can
        // happen to them: they go to the customer, or the order is written off. Sending the
        // order back to «قيد الطباعة» used to be offered for a reprint, and it described the
        // wrong event — a run that has to be printed again is a new run, not the finished one
        // rewinding, and the status the parcel is in would have said the bags do not exist.
        $this->assertEqualsCanonicalizing([
            OrderStatus::OfficePickup,
            OrderStatus::OutForDelivery,
            OrderStatus::Cancelled,
        ], $allowed);

        $this->assertNotContains(OrderStatus::Printing, $allowed);
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
        // Act & Assert — the gap in the flow as first described: a way in and no way out. Asked
        // of both roads, because the short one has its own «نواقص» arm: an order of ready-made
        // goods can still find the shelf empty, and writing that arm as a filter over the long
        // road rather than as its own would have produced exactly this bug.
        foreach (OrderFlow::cases() as $flow) {
            $allowed = OrderStatus::Shortage->allowedNext($flow);

            $this->assertNotEmpty(
                array_filter($allowed, fn (OrderStatus $s) => ! $s->isFinal()),
                "«نواقص» is a dead end on the {$flow->value} road.",
            );
        }
    }

    public function test_a_shortage_is_declared_at_intake_and_nowhere_else(): void
    {
        // Act
        $waysIn = array_values(array_filter(
            OrderStatus::cases(),
            fn (OrderStatus $s) => in_array(OrderStatus::Shortage, $s->allowedNext(), true),
        ));

        // Assert — «نواقص» is what the shop finds when it goes to start the job: the stock is not
        // there, and the order is parked before any work is done on it. Offering it from «قيد
        // الطباعة» and «جاهزة» too made it a second name for «the run came up short», which is a
        // different event and one the press already answers by going back a step.
        $this->assertSame([OrderStatus::New], $waysIn);
    }

    public function test_a_parcel_comes_back_the_way_it_went_out(): void
    {
        // Act
        $fromCourier = OrderStatus::ReturnedCourier->allowedNext();
        $fromCarrier = OrderStatus::ReturnedCarrier->allowedNext();

        // Assert — a return is a chain of custody, and coming *home* is walked one link at a
        // time: the courier hands the parcel back to the company that sent him, and the company
        // hands it back to us. Skipping a link would record a hand-over that never happened —
        // a parcel still in somebody's van marked as being on our shelf, or in the customer's
        // hands without anybody having taken it there.
        $this->assertSame([OrderStatus::ReturnedCarrier], $fromCourier);
        $this->assertContains(OrderStatus::ReturnedOffice, $fromCarrier);
        $this->assertNotContains(OrderStatus::Delivered, $fromCarrier);
        $this->assertNotContains(OrderStatus::ReturnedCourier, $fromCarrier);
    }

    public function test_the_carrier_may_try_again_without_the_parcel_coming_home(): void
    {
        // Act
        $allowed = OrderStatus::ReturnedCarrier->allowedNext();

        // Assert — the parcel is sitting at the delivery company's depot, and the commonest
        // thing that happens next is not a van bringing it back: it is the customer being
        // reached and the company going out again. Forcing that through «راجع مكتب» would have
        // staff record the parcel onto a shelf it never reached to describe a second attempt
        // that was never interrupted.
        $this->assertContains(OrderStatus::Resend, $allowed);
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

    // ─────────────────────────── the order the board reads ───────────────────────────

    public function test_the_board_opens_on_the_six_statuses_the_workshop_lives_in(): void
    {
        // Act — `cases()` is what the home screen draws, in the order it draws them: the app
        // holds no list of its own, so this sequence *is* the board.
        $opening = array_map(
            fn (OrderStatus $s) => $s->value,
            array_slice(OrderStatus::cases(), 0, 6),
        );

        // Assert — two cards to a row on the phone, and each row pairs the work with the thing
        // that stands beside it: جديدة/نواقص is what came in and what could not be started,
        // قيد التصميم/جاهزة للطباعة is the artwork and the queue it feeds, قيد الطباعة/جاهزة is
        // the press and its shelf. This is the shop's own reading order, not the machine's —
        // «جاهزة للطباعة» comes after «قيد التصميم» here and before it in allowedNext(), and
        // both are right about different questions.
        $this->assertSame([
            'new', 'shortage',
            'designing', 'ready_to_print',
            'printing', 'ready',
        ], $opening);
    }

    public function test_the_two_that_are_over_sit_at_the_bottom_of_the_board(): void
    {
        // Act
        $last = array_map(
            fn (OrderStatus $s) => $s->value,
            array_slice(OrderStatus::cases(), -2),
        );

        // Assert — a full board is skimmed past the finished work, not through it.
        $this->assertSame(['delivered', 'settled'], $last);
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
        // Act — on every road, so a new one cannot introduce a loop the old one refused.
        $selfLooping = [];

        foreach (OrderFlow::cases() as $flow) {
            foreach (OrderStatus::cases() as $status) {
                if (in_array($status, $status->allowedNext($flow), true)) {
                    $selfLooping[] = "{$flow->value}: {$status->value}";
                }
            }
        }

        // Assert — re-saving an order is not a transition, and treating it as one would write
        // a meaningless row into the history every time somebody pressed save twice.
        $this->assertSame([], $selfLooping);
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

        // Act — all 144 pairs on *each* road, so the convenience method can never drift from the
        // map it reads, and a road added later cannot quietly be enforced against the wrong one.
        foreach (OrderFlow::cases() as $flow) {
            foreach (OrderStatus::cases() as $from) {
                foreach (OrderStatus::cases() as $to) {
                    $expected = in_array($to, $from->allowedNext($flow), true);

                    if ($from->canMoveTo($to, $flow) !== $expected) {
                        $disagreements[] = "{$flow->value}: {$from->value} → {$to->value}";
                    }
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
        $leaking = [];

        foreach (OrderFlow::cases() as $flow) {
            foreach ($final as $status) {
                if ($status->allowedNext($flow) !== []) {
                    $leaking[] = "{$flow->value}: {$status->value}";
                }
            }
        }

        // Assert — an ending is an ending on every road.
        $this->assertNotEmpty($final, 'A machine with no final state never finishes an order.');
        $this->assertSame([], $leaking);
    }
}
