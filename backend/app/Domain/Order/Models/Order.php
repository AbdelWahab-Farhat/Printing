<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\AllocateOrderIdentifier;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Enums\AdditionalCostReason;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentStatus;
use App\Domain\Order\Exceptions\SettlementRequiresFullPayment;
use App\Domain\Order\Support\Money;
use Database\Factories\OrderFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A job of work: bags printed for a customer and got to them.
 *
 * `code` is deliberately absent from the fillable list — it is allocated by
 * {@see AllocateOrderIdentifier} and must never arrive in a request. So are the money columns
 * and every lifecycle timestamp: a total is derived from the lines by
 * {@see RecalculateOrderTotals} and a timestamp is stamped by the
 * transition that earned it. A client that could post `grand_total` could post any number it
 * liked.
 *
 * The address fields *are* fillable and are snapshots: see the migration for why nothing shown
 * on an old order is read back through its foreign keys.
 */
#[UseFactory(OrderFactory::class)]
#[Fillable([
    'customer_shop_id', 'customer_shop_name', 'city_id', 'region_id',
    'city_name', 'region_name', 'fulfilment_type',
    'design_source', 'recipient_name', 'recipient_phone', 'address_details', 'notes',
    'tracking_number',
])]
class Order extends Model implements HasAuditTrail
{
    /** @use HasFactory<OrderFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * Gives every order its number, on whatever path created it.
     *
     * On the model rather than in `CreateOrder`, for the reason products settled on: three
     * places create one — the action, the factory and any future importer — `code` is NOT NULL,
     * and an allocation living in only one of them is a crash waiting for the next caller.
     * There is exactly one correct code for any order, so nothing is taken from a caller by
     * settling it here.
     */
    protected static function booted(): void
    {
        static::creating(function (self $order): void {
            if ($order->code === null) {
                $identifier = app(AllocateOrderIdentifier::class)();

                $order->id = $identifier->id;
                $order->code = $identifier->code;
            }
        });
    }

    /**
     * @return array<string, mixed>
     */
    protected function casts(): array
    {
        return [
            'status' => OrderStatus::class,
            'fulfilment_type' => FulfilmentType::class,
            // Which road this order walks, stamped at intake by `ResolveOrderFlow` and never
            // re-read afterwards — see that action for why it is a snapshot. Absent from the
            // fillable list for the reason `grand_total` is: a request that could post it could
            // skip the press on paper.
            'production_flow' => OrderFlow::class,
            'design_source' => DesignSource::class,
            // Strings, not floats: these are summed, and money that is summed must stay exact.
            'items_total' => 'decimal:2',
            'design_fee' => 'decimal:2',
            'delivery_price' => 'decimal:2',
            'discount' => 'decimal:2',
            // The charge that goes the other way — packaging, transport, a change to what was
            // agreed. Beside the discount rather than inside it, so «لماذا تغيّر الإجمالي؟» has
            // two readable halves rather than one net figure that answers nothing.
            'additional_cost' => 'decimal:2',
            // Cast, and that is the whole of what makes the change history say «تغليف خاص»
            // rather than `special_packaging` — see AuditValueLabels, which derives from here.
            'additional_cost_reason' => AdditionalCostReason::class,
            'grand_total' => 'decimal:2',
            // The cost-side twin of grand_total — written only by RecalculateOrderCogs, and
            // absent from the fillable list for the same reason grand_total is.
            'total_cogs' => 'decimal:2',
            // The ledger's running total. Written only by RecalculateOrderPayments and absent
            // from the fillable list for the same reason `grand_total` is: a request that could
            // set it could tell us it had been paid.
            'paid_amount' => 'decimal:2',
            // The other half of what closes a debt: what the business decided not to collect.
            // Same writer, same reason for staying out of the fillable list — and kept apart
            // from `paid_amount` so that column never stops meaning cash.
            'written_off_amount' => 'decimal:2',
            // The third thing that closes a debt: what the customer handed the courier instead of
            // us, because our delivery fee was taken off the COD before the parcel went out. Same
            // writer, same reason for staying out of the fillable list — and kept apart from both
            // of the others so `paid_amount` never stops meaning cash and `written_off_amount`
            // never stops meaning a loss. See OrderPaymentType::CarrierSettled.
            'carrier_settled_amount' => 'decimal:2',
            // The idempotence flag behind both money entries a delivery webhook writes. On the
            // order rather than the parcel so it survives the parcel being deleted, re-created or
            // re-dispatched under a new code — see its migration.
            'carrier_collection_recorded_at' => 'datetime',
            // **Retired, and kept for the orders written before it was.** Nothing fills it any
            // more: settling used to ask «المبلغ المستلم» and write the answer here, a number no
            // total ever read — so an order could carry «المدفوع ٥٠٠» and «المستلم فعلياً ٤٥٠»
            // at once with nothing able to say which was true. That question the ledger now
            // answers exactly. See `TransitionFields::money()`.
            'collected_amount' => 'decimal:2',
            'placed_at' => 'datetime',
            'ready_to_print_at' => 'datetime',
            'design_started_at' => 'datetime',
            'printing_started_at' => 'datetime',
            // Stamped once by ChangeOrderStatus, on the first entry into `ready` — see
            // DeductOrderStock. Unlike ready_at, never overwritten by a later visit:
            // its whole job is to remember whether stock has already left the warehouse.
            'stock_deducted_at' => 'datetime',
            'ready_at' => 'datetime',
            'dispatched_at' => 'datetime',
            'delivered_at' => 'datetime',
            'settled_at' => 'datetime',
            'returned_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<CustomerShop, $this>
     */
    public function shop(): BelongsTo
    {
        return $this->belongsTo(CustomerShop::class, 'customer_shop_id');
    }

    /**
     * @return BelongsTo<City, $this>
     */
    public function city(): BelongsTo
    {
        return $this->belongsTo(City::class);
    }

    /**
     * @return BelongsTo<Region, $this>
     */
    public function region(): BelongsTo
    {
        return $this->belongsTo(Region::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * @return HasMany<OrderItem, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class)->orderBy('sort_order')->orderBy('id');
    }

    /**
     * Newest version first — the one under discussion is the one staff need.
     *
     * @return HasMany<OrderDesign, $this>
     */
    public function designs(): HasMany
    {
        return $this->hasMany(OrderDesign::class)->orderByDesc('version');
    }

    /**
     * @return HasMany<OrderStatusTransition, $this>
     */
    public function transitions(): HasMany
    {
        return $this->hasMany(OrderStatusTransition::class)->orderBy('id');
    }

    /**
     * The money ledger: what was paid, given back, or entered by mistake.
     *
     * **Oldest first, unlike the designs.** A ledger is read as a story — the deposit, then the
     * balance, then the correction — and a correction printed above the entry it corrects makes
     * a reader work backwards through an argument.
     *
     * Ordered by `paid_at` and then by id, because two entries can share a moment: a deposit and
     * its immediate reversal are typed a second apart and stored with the same date. The id
     * breaks that tie in the order they were written, which is the only tie-break that cannot
     * put a correction above its cause.
     *
     * @return HasMany<OrderPayment, $this>
     */
    public function payments(): HasMany
    {
        return $this->hasMany(OrderPayment::class)->orderBy('paid_at')->orderBy('id');
    }

    /**
     * What is still owed on this order.
     *
     * **Three things close a debt: money collected, money the business decided not to collect,
     * and money the customer handed the courier instead of us.** All three are subtracted here,
     * which is what lets an order of 110 that took 105 and wrote off the difference reach «تم
     * التسوية» — see {@see OrderPaymentType::WriteOff} — and what lets one dispatched through
     * Nawris reach it without a write-off at all, see {@see OrderPaymentType::CarrierSettled}.
     * They remain three columns rather than one running total precisely so this method is the
     * only place they are added together: `paid_amount` never has to mean anything but cash, and
     * `written_off_amount` never has to mean anything but a loss.
     *
     * **Negative when the order is overpaid, and deliberately not floored here.** A screen wants
     * to say «زائد ٥٠» so somebody refunds it; the *payment* path floors it at zero separately,
     * because "you may pay -50 more" is not a sentence. Two readers, two right answers, and the
     * one that loses information is the one computed where it is needed.
     */
    public function remainingAmount(): string
    {
        $covered = bcadd(
            bcadd((string) $this->paid_amount, (string) $this->written_off_amount, 8),
            (string) $this->carrier_settled_amount,
            8,
        );

        return Money::round(bcsub((string) $this->grand_total, $covered, 8));
    }

    public function paymentStatus(): PaymentStatus
    {
        return PaymentStatus::for($this);
    }

    /**
     * What this order made, on the accrual side: `grand_total` less what it cost to produce.
     *
     * **Null until `total_cogs` is known**, not zero — an order that has not reached printing has
     * no cost to subtract yet, and a zero would read as "this order costs nothing to fulfil"
     * rather than "production hasn't happened". Computed here rather than cached: both inputs are
     * already cached columns, and a third one to keep in sync would only be able to disagree with
     * them.
     */
    public function grossProfit(): ?string
    {
        if ($this->total_cogs === null) {
            return null;
        }

        return Money::round(bcsub((string) $this->grand_total, (string) $this->total_cogs, 8));
    }

    /**
     * Whether this order ended without its money being accounted for.
     *
     * **The honest cost of a deliberate decision.** Settling an order does not write a ledger
     * entry — no payment is recorded except by the person who took it. Rather than invent an
     * entry nobody made, the discrepancy is surfaced: the app draws a warning, somebody records
     * what was actually collected, and the warning goes away.
     *
     * A generated entry would have hidden exactly this, which is why there isn't one.
     *
     * **The gap is no longer opened by settling.** An order that still owes anything is refused
     * the move — see {@see SettlementRequiresFullPayment} — so what
     * this now catches is the gap opened *afterwards*: a refund against a settled order takes
     * `paid_amount` back down and leaves a remainder somebody has to explain. Orders settled
     * before that guard existed keep whatever they were recorded with, and are exactly what this
     * flag was written to surface.
     */
    public function hasUnrecordedMoney(): bool
    {
        return $this->status->isFinal()
            && $this->status !== OrderStatus::Cancelled
            && bccomp($this->remainingAmount(), '0', Money::SCALE) > 0;
    }

    /**
     * Whether the lines may still be edited.
     *
     * **Open while the press is running, closed once the bags are on the shelf.** A run that is
     * being printed is exactly when a quantity gets corrected — the customer rings and asks for
     * five hundred instead of three — and the shop floor can still act on it. From «جاهزة»
     * onwards the bags exist and are counted, so changing what the order says was ordered would
     * make the invoice disagree with the shelf.
     *
     * A customer taking one product and leaving another at the counter is a real thing that
     * happens; it is recorded in BACKLOG.md rather than solved by leaving this open further.
     */
    public function itemsAreEditable(): bool
    {
        return in_array(
            $this->status,
            [
                OrderStatus::New,
                OrderStatus::Designing,
                // The status named after the problem, and for a while the one status that could
                // not fix it: an order parked on a shortage is exactly where somebody argues the
                // number — and the number now moves the invoice.
                OrderStatus::Shortage,
                OrderStatus::Printing,
            ],
            true,
        );
    }

    /**
     * The sizes still missing from this order, by label.
     *
     * **What stands between «نواقص» and the press.** «جاهزة للطباعة» tells another department the
     * goods are all here; an order still short of one size has not made that true — see
     * `ShortageMustBeResolved`.
     *
     * Returns labels rather than a bare boolean because the person refused by it is standing at
     * the shelves: «ما زال ناقصاً: 25*35» sends them somewhere, «الطلبية غير مكتملة» does not.
     * Empty means nothing is short, which is what makes it readable as a yes/no at the call site.
     *
     * @return list<string>
     */
    public function unresolvedShortages(): array
    {
        return $this->items
            ->filter(fn (OrderItem $item) => $item->shortage_quantity !== null
                && bccomp((string) $item->shortage_quantity, '0', 3) > 0)
            ->map(fn (OrderItem $item) => (string) $item->variant_label)
            ->values()
            ->all();
    }

    /**
     * Whether another version of the artwork may be put on the order.
     *
     * **Open before the work starts and while it is being done; closed once the press is
     * running against it.** «قيد التصميم» *is* the artwork conversation, so it was once the only
     * status here — and that was wrong about the commonest order in the shop. A customer very
     * often arrives with the finished file, agreed long before the order was taken; there is
     * nothing to design, and the file still has to go on the order. The old rule left one way to
     * record it: send the order to the designer's queue and pull it straight back out, which
     * puts a status on the screen saying work is being done that nobody is doing and two moves
     * on the timeline standing for nothing that happened.
     *
     * So «جديدة» accepts a version too — including at the moment the order is taken, see
     * {@see CreateOrder} — and «قيد التصميم» remains what it always was: the queue for the
     * orders whose artwork does not exist yet.
     *
     * **«جاهزة للطباعة» accepts one for the same reason «جديدة» does, and must.** The short path
     * is an agreed file going on the order and the press starting; that path now runs through the
     * handover, so refusing artwork here would leave the customer's own file with nowhere to go
     * but a detour into the designer's queue and straight back out — the exact walk this rule was
     * loosened to end. The goods being weighed and off the shelf by then changes nothing about
     * the artwork: the press has not run.
     *
     * The line stops at «قيد الطباعة» because that is where it means something: the bags are
     * being printed from a settled file, and changing it is going back to design on purpose —
     * a move somebody makes and the timeline records.
     *
     * Every move that touches the artwork carries it while the order stands on the permitting
     * side of the move, which is why {@see ChangeOrderStatus} writes the status before the
     * attachment in one direction and after it in the other.
     *
     * **A different line from {@see itemsAreEditable()}, deliberately.** A quantity is a number
     * the shop floor can still act on; a design is a decision that has already been acted on.
     */
    public function designsAreEditable(): bool
    {
        return in_array(
            $this->status,
            [OrderStatus::New, OrderStatus::ReadyToPrint, OrderStatus::Designing],
            true,
        );
    }

    /**
     * Whether the destination may still be changed.
     *
     * **Refused in exactly one open status: «جاري التوصيل».** That is the only moment the
     * address on our screen and the address on the label can part company while somebody is
     * acting on the label — the parcel is moving, and only the label is real.
     *
     * The three returns used to be refused too, on the same reasoning. They are open again
     * because the reasoning did not survive the return chain: a parcel at «راجع لدى المندوب» is
     * on its way *back to us*, and the commonest thing said about it is «ابعثها للفرع الثاني
     * بدل ما ترجع». Refusing that meant the address was corrected after the re-send instead of
     * before it, which is the same edit made later and read by nobody.
     *
     * Closed rather than final, because those two came apart: «تم الاستلام» has a move left —
     * the money — but the bags are with the customer, so its address is history.
     */
    public function destinationIsEditable(): bool
    {
        return $this->status !== OrderStatus::OutForDelivery && ! $this->status->isClosed();
    }

    /**
     * The moves this order may make, as *choices a person makes*, narrowed to those the given
     * user may actually make.
     *
     * The app draws its buttons from this rather than from a copy of the rules, which is what
     * stops a screen offering an action the server will refuse.
     *
     * **The two dispatch statuses collapse into the one the destination implies.** The
     * transition map legitimately lists both — either is a legal target — but a *button* for
     * each would put «استلام مكتب» and «جاري التوصيل» side by side on a screen where tapping
     * either produces whichever the city says, so one of the two would appear to do nothing.
     * The clerk's decision is "it is leaving"; the address settles the rest.
     *
     * Done here rather than in the resource so every reader gets the same answer — a second
     * caller building its own list is how the screen and the server start disagreeing.
     *
     * @return list<OrderStatus>
     */
    public function availableTransitionsFor(?User $user): array
    {
        $dispatch = OrderStatus::dispatchFor($this->fulfilment_type);

        $targets = array_map(
            fn (OrderStatus $target) => $target->isDispatch() ? $dispatch : $target,
            // **Both facts about this order, and neither is its status.** The destination
            // collapses the dispatch pair below; the flow decides whether the designer and the
            // press are on this order's road at all — an order of ready-made goods is offered
            // «جاهزة» from «جديدة» and is never shown two buttons for work nobody will do.
            $this->status->allowedNext($this->production_flow),
        );

        // array_unique keeps the first occurrence, so the collapsed pair leaves one entry in
        // the position the map put it — the order of the buttons stays deliberate.
        $targets = array_unique($targets, SORT_REGULAR);

        return array_values(array_filter(
            $targets,
            fn (OrderStatus $target) => $user?->can($target->permission()->value) ?? false,
        ));
    }

    /**
     * The order's journey, as steps a progress bar can draw.
     *
     * Each entry says which status, what to call it, and where the order stands relative to it —
     * `done`, `current`, or `upcoming`. The **order** of the list is the domain's, not a
     * client's: which status follows which is exactly the knowledge this app refuses to keep two
     * copies of, so it is answered here and shipped with the order.
     *
     * **A detour is reported, not hidden.** An order sitting in «نواقص» or a راجع is nowhere on
     * the main line, so every step it has genuinely passed is marked done, the rest upcoming,
     * and nothing is marked current — the screen shows the detour beside the line instead of
     * pretending the order is on it. `isDetour` on the payload is what tells it to.
     *
     * A cancelled order keeps whatever it had reached: the bar stops where the work stopped,
     * which is the honest picture of an order written off halfway.
     *
     * @return array{steps: list<array{status: string, label: string, state: string}>, is_detour: bool}
     */
    public function progress(): array
    {
        // The same pair `availableTransitionsFor()` reads, and for the same reason: an order
        // that skips production draws five steps rather than seven, instead of two steps it will
        // never reach sitting on the bar claiming it is a third of the way through.
        $line = OrderStatus::mainLine($this->fulfilment_type, $this->production_flow);
        $position = $this->status->mainLinePosition($this->fulfilment_type, $this->production_flow);

        // A detour has no position of its own, so "how far did it get" comes from the furthest
        // main-line step its timeline actually recorded. Without this an order returned from
        // the road would draw an empty bar, as though nothing had ever happened to it.
        $reached = $position ?? $this->furthestMainLineStep($line);

        $steps = [];

        foreach ($line as $index => $status) {
            $steps[] = [
                'status' => $status->value,
                'label' => $status->label(),
                'state' => match (true) {
                    $index < $reached => 'done',
                    $index === $reached && $position !== null => 'current',
                    $index === $reached => 'done',
                    default => 'upcoming',
                },
            ];
        }

        return ['steps' => $steps, 'is_detour' => $position === null];
    }

    /**
     * The furthest main-line step this order has actually been in, read from its timeline.
     *
     * @param  list<OrderStatus>  $line
     */
    private function furthestMainLineStep(array $line): int
    {
        $visited = $this->transitions()->pluck('to_status')->all();
        $furthest = 0;

        foreach ($visited as $status) {
            $index = array_search(
                $status instanceof OrderStatus ? $status : OrderStatus::from((string) $status),
                $line,
                true,
            );

            if ($index !== false && $index > $furthest) {
                $furthest = $index;
            }
        }

        return $furthest;
    }

    /**
     * An order's history is the whole job's: its lines, its designs and every status move.
     *
     * "Who cancelled this, and when did it go out?" is what the endpoint exists to answer, and
     * those facts live on three other tables. Making the client fetch four histories and merge
     * them would push the shape of our schema into its code.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [
            $this->getMorphClass() => [$this->getKey()],
            (new OrderItem)->getMorphClass() => $this->items()->withTrashed()->pluck('id')->all(),
            (new OrderDesign)->getMorphClass() => $this->designs()->withTrashed()->pluck('id')->all(),
            (new OrderStatusTransition)->getMorphClass() => $this->transitions()->withTrashed()->pluck('id')->all(),
            // The ledger belongs in the order's story for the same reason the lines do — «من
            // ألغى دفعة الـ٥٠٠؟» is asked of the order, not of a table nobody knows the name of.
            (new OrderPayment)->getMorphClass() => $this->payments()->withTrashed()->pluck('id')->all(),
        ];
    }
}
