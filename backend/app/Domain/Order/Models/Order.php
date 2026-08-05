<?php

declare(strict_types=1);

namespace App\Domain\Order\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\AllocateOrderIdentifier;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderStatus;
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
            'design_source' => DesignSource::class,
            // Strings, not floats: these are summed, and money that is summed must stay exact.
            'items_total' => 'decimal:2',
            'design_fee' => 'decimal:2',
            'delivery_price' => 'decimal:2',
            'discount' => 'decimal:2',
            'grand_total' => 'decimal:2',
            // Three places, like a quantity: an order priced by the kilo is invoiced from this.
            'weight_kg' => 'decimal:3',
            // Null unless what came back differed from what was invoiced.
            'collected_amount' => 'decimal:2',
            'placed_at' => 'datetime',
            'design_started_at' => 'datetime',
            'printing_started_at' => 'datetime',
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
     * Whether anything on this order is sold by the kilo.
     *
     * **Any line, not every line.** A mixed order still has to be weighed, because one of its
     * lines is invoiced from the scale — and «some of it needs a weight» is the same practical
     * instruction as «all of it does».
     */
    public function isPricedByWeight(): bool
    {
        return $this->items->contains(
            fn (OrderItem $item) => $item->pricing_unit === PricingUnit::Kilogram,
        );
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
            [OrderStatus::New, OrderStatus::Designing, OrderStatus::Printing],
            true,
        );
    }

    /**
     * Whether another version of the artwork may be put on the order.
     *
     * **One status, and it is the one named after the work.** «قيد التصميم» *is* the artwork
     * conversation; a version belongs to it and nowhere else. An order still «جديدة» has not
     * begun that conversation — the artwork it starts with arrives *with* the move into design,
     * which is why {@see ChangeOrderStatus} writes the status before
     * it attaches what the move carried — and an order being printed is running against a file
     * that was approved, so changing it means going back to design on purpose.
     *
     * **A different line from {@see itemsAreEditable()}, deliberately.** A quantity is a number
     * the shop floor can still act on; a design is a decision that has already been acted on.
     */
    public function designsAreEditable(): bool
    {
        return $this->status === OrderStatus::Designing;
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
            $this->status->allowedNext(),
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
        $line = OrderStatus::mainLine($this->fulfilment_type);
        $position = $this->status->mainLinePosition($this->fulfilment_type);

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
        ];
    }
}
