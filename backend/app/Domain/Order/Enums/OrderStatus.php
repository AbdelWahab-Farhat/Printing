<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Identity\Enums\PermissionName;

/**
 * Where an order is, and the only moves it may make from there.
 *
 * **This enum is the state machine.** The map in {@see allowedNext()} is the single definition
 * of what is legal; the API refuses anything else, the app draws its buttons from it, and the
 * permission each move costs is answered here too. Nothing else is allowed to hold an opinion
 * about what follows what — a second copy of these rules is a second thing to keep in step, and
 * the copy that drifts is always the one guarding the write.
 *
 * **Adding a status is a `case` and a few lines in the matches below.** That is deliberately a
 * code change rather than a row in a table: half of these statuses carry behaviour a row cannot
 * express — dispatch is chosen by the server from the city, cancelling demands a reason, the
 * final two are closed, and each one costs a different permission. A `order_statuses` table
 * would offer the *appearance* of runtime extensibility while leaving all of that in PHP
 * anyway. `OrderStatusTest` walks every case and every pair, so an addition that forgets a
 * label, a permission, or a way in fails the build naming exactly what is missing.
 *
 * Order depends on Delivery and Identity; neither knows this enum exists.
 */
enum OrderStatus: string
{
    /** Taken, not started. The only status nothing leads back to. */
    case New = 'new';

    /** Artwork is being agreed with the customer — see {@see OrderDesignStatus}. */
    case Designing = 'designing';

    case Printing = 'printing';

    /** Finished and on the shelf, waiting to leave. */
    case Ready = 'ready';

    /**
     * The stock to start the job is not there. Reachable from «جديدة» and nowhere else — it
     * describes an order that could not be begun, not a run that came out short.
     */
    case Shortage = 'shortage';

    /** Waiting at one of our branches for the customer to collect. */
    case OfficePickup = 'office_pickup';

    case OutForDelivery = 'out_for_delivery';

    case ReturnedCourier = 'returned_courier';

    case ReturnedCarrier = 'returned_carrier';

    /** Physically back on our shelf. */
    case ReturnedOffice = 'returned_office';

    /** Going out a second time — off our shelf, or from the carrier's depot without coming back. */
    case Resend = 'resend';

    case Cancelled = 'cancelled';

    // ── the two that are over ────────────────────────────────────────────────────────────────
    // **Last, and last on purpose.** This order is what the home screen draws: the app maps
    // `cases()` straight to its board, so the sequence here is the sequence a person reads down
    // the phone. The statuses that still need somebody to *do* something come first, and the
    // two that are already finished sit at the bottom where a full board can be skimmed past
    // them. It is no longer the order the state machine walks — {@see allowedNext()} is, and it
    // says so in one place.

    /**
     * The customer has it. Closed to editing, but not finished: the money it was sent out to
     * collect still has to come back — see {@see Settled}.
     */
    case Delivered = 'delivered';

    /** The money is agreed. The end of the road. */
    case Settled = 'settled';

    public function label(): string
    {
        return match ($this) {
            self::New => 'جديدة',
            self::Designing => 'قيد التصميم',
            self::Printing => 'قيد الطباعة',
            self::Ready => 'جاهزة',
            self::Shortage => 'نواقص',
            self::OfficePickup => 'استلام مكتب',
            self::OutForDelivery => 'جاري التوصيل',
            self::Delivered => 'تم الاستلام',
            self::Settled => 'تم التسوية',
            self::ReturnedCourier => 'راجع لدى المندوب',
            self::ReturnedCarrier => 'راجع لدى شركة التوصيل',
            self::ReturnedOffice => 'راجع مكتب',
            self::Resend => 'إعادة إرسال',
            // «إلغاء تام», not «ملغاة»: the workshop calls off an order in more than one way —
            // a return comes back and can go out again, a resend is a second attempt — and the
            // one word for the ending that is not coming back has to say so. This label is what
            // the app prints on a chip, in a filter and on a timeline. One status, one word,
            // wherever it is drawn.
            self::Cancelled => 'إلغاء تام',
        };
    }

    /**
     * Every move this status may make. The map, and the reason this file exists.
     *
     * Going *backwards* is legal and listed explicitly rather than allowed wholesale: printing
     * returns to designing because staff mistype things and because artwork gets corrected. What
     * is not listed cannot happen — an unrestricted "you may go anywhere" would make the machine
     * decorative.
     *
     * **The line it stops at is «جاهزة».** Once the bags exist there is nothing to rewind to:
     * every move after that describes where a physical parcel is.
     *
     * @return list<self>
     */
    public function allowedNext(): array
    {
        return match ($this) {
            // The one open status that cannot be cancelled, and it is deliberate: a job nobody
            // has started is two taps from being started, and cancelling would compete with the
            // moves that matter. Cancelling is still available from every status after this one
            // — the order has cost something by then, which is when writing it off is a decision
            // rather than a stray tap. «نواقص» is here for the opposite reason: it is not an
            // ending, it is the job failing to start.
            self::New => [self::Designing, self::Printing, self::Shortage],

            // Never straight to ready: artwork that has been agreed still has to be printed.
            self::Designing => [self::Printing, self::Cancelled],

            self::Printing => [self::Ready, self::Designing, self::Cancelled],

            // **Out, or written off. Nothing goes back from here.** «جاهزة» means the bags are
            // made, counted and on the shelf; the two ways out are the dispatch pair, and the
            // server picks which — see dispatchFor(). Returning to «قيد الطباعة» was offered for
            // a reprint and described the wrong event: bags that have to be printed again are a
            // *new* run, not this one rewinding, and the order's status would have gone on
            // saying the finished bags do not exist while they sat on the shelf.
            self::Ready => [self::OfficePickup, self::OutForDelivery, self::Cancelled],

            // **Only «جديدة» leads here, and that is the whole meaning of the status.** «نواقص»
            // is what the shop finds when it goes to start a job it has taken: the stock for one
            // of the sizes is not on the floor, so the order is parked before any work is done
            // on it. Offering the same status from «قيد الطباعة» and «جاهزة» made it a second
            // name for «the run came up short» — a different event, at a different desk, which
            // the press already answers by going back a step to print the rest.
            //
            // Out of it are the two ways in to the work it never started, plus the ending: a
            // shortage that is never resolved is written off rather than left parked forever.
            self::Shortage => [self::Designing, self::Printing, self::Cancelled],

            // No returns: it never left the building, so there is no courier and no carrier.
            // A customer who has not come yet is simply still waiting.
            self::OfficePickup => [self::Delivered, self::Cancelled],

            // **A return is a chain of custody, walked one link at a time.** The parcel is with
            // the courier, who hands it back to the company that sent him, who hands it back to
            // us — and each of those hand-overs is a real event somebody is answerable for.
            // Allowing «جاري التوصيل» to jump straight to «راجع مكتب» would let the system
            // record a parcel as being on our shelf while it is still in somebody's van.
            //
            // Cancelling is absent from all three for the same reason: an order is not written
            // off while it is physically outside the building. It comes home first, and
            // «راجع مكتب» is where that decision is taken.
            self::OutForDelivery => [self::Delivered, self::ReturnedCourier],

            self::ReturnedCourier => [self::ReturnedCarrier],

            // **Coming home is one link at a time; going out again is not.** A parcel sitting at
            // the delivery company's depot is most often waiting on nothing more than the
            // customer answering their phone, and the company then goes out with it a second
            // time — the van never comes to us. Making that trip pass through «راجع مكتب» would
            // have staff record the parcel onto a shelf it never reached in order to describe a
            // second attempt that was never interrupted, which is the same lie the chain exists
            // to prevent, told in the other direction. «راجع مكتب» stays for the parcel that
            // genuinely does come back.
            self::ReturnedCarrier => [self::ReturnedOffice, self::Resend],

            // Back on our shelf, and three real endings: the customer comes in for it, it goes
            // out again, or it is written off.
            self::ReturnedOffice => [self::Delivered, self::Resend, self::Cancelled],

            // A second attempt leaves exactly the way the first one did, and the destination
            // still decides which of the two that is.
            self::Resend => [self::OfficePickup, self::OutForDelivery, self::Cancelled],

            // Handing the bags over is not the end of the job: what was collected for them has
            // to come back and be agreed. Offered here whatever the order has been paid — the
            // map answers what *follows* what — and refused by the action while anything is
            // still owed, so the accountant is told what to record rather than left looking for
            // a button that vanished. See SettlementRequiresFullPayment.
            self::Delivered => [self::Settled],

            self::Settled, self::Cancelled => [],
        };
    }

    public function canMoveTo(self $target): bool
    {
        return in_array($target, $this->allowedNext(), true);
    }

    /** Finished. Nothing follows, and nothing may reopen it. */
    public function isFinal(): bool
    {
        return $this === self::Settled || $this === self::Cancelled;
    }

    /**
     * Whether the order itself is closed to editing.
     *
     * **Not the same question as {@see isFinal()}, and «تم الاستلام» is why.** The bags are with
     * the customer, so nothing about the order — its lines, its address, its price — may be
     * touched again; but the money it went out to collect has not been agreed yet, so the order
     * still has a move to make. One flag was asked to mean both and could only be right about
     * one of them.
     */
    public function isClosed(): bool
    {
        return $this === self::Delivered || $this->isFinal();
    }

    /** The order has left the workshop and is with — or waiting for — the customer. */
    public function isDispatch(): bool
    {
        return $this === self::OfficePickup || $this === self::OutForDelivery;
    }

    /**
     * Which of the two dispatch statuses a city implies.
     *
     * The clerk does not choose between them: they say "it is going out", and the destination
     * decides what that means. Keeping the decision here rather than in the request is what
     * stops an order for قرجي being marked out for delivery by a mistyped payload.
     *
     * The mapping lives in Order rather than on {@see FulfilmentType} so the delivery map stays
     * ignorant of orders — dependencies run one way.
     */
    public static function dispatchFor(FulfilmentType $type): self
    {
        return match ($type) {
            FulfilmentType::OfficePickup => self::OfficePickup,
            FulfilmentType::Delivery => self::OutForDelivery,
        };
    }

    /**
     * What a user must hold to move an order *into* this status.
     *
     * One permission per status, so the business composes roles — a designer, a printer, a
     * delivery coordinator — without any of that shape being baked into the code.
     *
     * **The two dispatch statuses share one.** They are the only pair the clerk does not choose
     * between, so splitting them would make the same button succeed for طرابلس and fail for
     * قرجي with nothing on screen to explain the difference. The three returns stay separate
     * precisely because a clerk *does* choose which one happened.
     *
     * `New` answers with the permission to create an order, since that is the only way in.
     */
    public function permission(): PermissionName
    {
        return match ($this) {
            self::New => PermissionName::ManageOrders,
            self::Designing => PermissionName::MoveOrderToDesigning,
            self::Printing => PermissionName::MoveOrderToPrinting,
            self::Ready => PermissionName::MoveOrderToReady,
            self::Shortage => PermissionName::MoveOrderToShortage,
            self::OfficePickup, self::OutForDelivery => PermissionName::DispatchOrders,
            self::Delivered => PermissionName::MarkOrdersDelivered,
            self::Settled => PermissionName::SettleOrders,
            self::ReturnedCourier => PermissionName::RecordCourierReturn,
            self::ReturnedCarrier => PermissionName::RecordCarrierReturn,
            self::ReturnedOffice => PermissionName::RecordOfficeReturn,
            self::Resend => PermissionName::ResendOrders,
            self::Cancelled => PermissionName::CancelOrders,
        };
    }

    /**
     * Whether the move must carry an explanation.
     *
     * Only writing an order off. Everything else is ordinary work whose reason is obvious from
     * the status itself, and demanding a sentence for each would produce a column full of "ok".
     */
    public function requiresReason(): bool
    {
        return $this === self::Cancelled;
    }

    /**
     * The column on `orders` stamped when this status is entered, if any.
     *
     * Denormalised on purpose: `order_status_transitions` holds the full history, but "orders
     * printed this week" should not have to walk it. Null where a column would be a lie or a
     * cost with nothing asking for it.
     */
    public function timestampColumn(): ?string
    {
        return match ($this) {
            self::New => 'placed_at',
            self::Designing => 'design_started_at',
            self::Printing => 'printing_started_at',
            self::Ready => 'ready_at',
            self::OfficePickup, self::OutForDelivery => 'dispatched_at',
            self::Delivered => 'delivered_at',
            self::Settled => 'settled_at',
            self::ReturnedCourier, self::ReturnedCarrier, self::ReturnedOffice => 'returned_at',
            self::Cancelled => 'cancelled_at',
            // A re-send is visited more than once by the orders that visit it at all — a parcel
            // goes out, comes back and goes out again — so a single column would keep the last
            // visit and quietly lose the first. A shortage is entered at most once now that
            // «جديدة» is its only way in, so a column *could* hold it honestly; it stays null
            // because nothing asks the question yet, and the transitions table already has the
            // answer. The day a report wants "orders parked short this week", this is a `case`
            // and a migration.
            self::Shortage, self::Resend => null,
        };
    }

    /**
     * The route an order is *meant* to take, in order.
     *
     * جديدة → قيد التصميم → قيد الطباعة → جاهزة → (التسليم) → تم الاستلام → تم التسوية. This is
     * the sequence the business described, and it is what a progress bar on the order screen
     * walks. The last step is money rather than bags, and it is on the line because an order
     * whose cash never came back is not a finished order.
     *
     * **Not every status is on it, and that is the point.** «نواقص»، الرواجع الثلاثة و«إعادة
     * إرسال» are detours — real, common, and off the line. Putting them in the sequence would
     * make the bar claim every order passes through a shortage on its way to being ready. They
     * are reported beside the line instead, as where the order actually is.
     *
     * The dispatch pair collapses to whichever the destination implies, so the line has one
     * step there rather than a fork the reader has to resolve.
     *
     * @return list<self>
     */
    public static function mainLine(FulfilmentType $fulfilment): array
    {
        return [
            self::New,
            self::Designing,
            self::Printing,
            self::Ready,
            self::dispatchFor($fulfilment),
            self::Delivered,
            self::Settled,
        ];
    }

    /**
     * Whether this status sits on the main line at all.
     *
     * A detour — a shortage, a return, a cancellation — is somewhere an order genuinely is, but
     * it is not a step on the way to anywhere, and a progress bar that pretended otherwise would
     * be drawing a road that does not exist.
     */
    public function isOnMainLine(FulfilmentType $fulfilment): bool
    {
        return in_array($this, self::mainLine($fulfilment), true);
    }

    /**
     * How far along the main line this status is, or null when it is a detour.
     */
    public function mainLinePosition(FulfilmentType $fulfilment): ?int
    {
        $index = array_search($this, self::mainLine($fulfilment), true);

        return $index === false ? null : $index;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $status) => $status->value, self::cases());
    }
}
