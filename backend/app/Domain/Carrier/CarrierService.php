<?php

declare(strict_types=1);

namespace App\Domain\Carrier;

use App\Domain\Carrier\Actions\CancelNawrisParcel;
use App\Domain\Carrier\Actions\DeleteNawrisParcel;
use App\Domain\Carrier\Actions\DetachNawrisParcel;
use App\Domain\Carrier\Actions\DispatchToNawris;
use App\Domain\Carrier\Actions\EditNawrisParcel;
use App\Domain\Carrier\Actions\ResendNawrisParcel;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Delivery\Enums\FulfilmentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

/**
 * The carrier context's only public entry point.
 *
 * **Nothing outside `Carrier` touches its models or its actions.** The Application layer calls
 * this after a dispatch has committed; `Order` never calls it at all, and never imports anything
 * from here — this context depends on Order and Delivery, and dependencies run one way.
 *
 * The door is deliberately thin. Work lives in the Actions; this exists so the seam is one file
 * rather than a habit everybody has to remember.
 */
final class CarrierService
{
    public function __construct(
        private readonly DispatchToNawris $dispatch,
        private readonly DeleteNawrisParcel $delete,
        private readonly DetachNawrisParcel $detach,
        private readonly EditNawrisParcel $edit,
        private readonly CancelNawrisParcel $cancel,
        private readonly ResendNawrisParcel $resend,
    ) {}

    /**
     * Hand an order to Nawris.
     *
     * Throws on every refusal — an office-pickup order, an unmapped city, an order already out —
     * so the caller decides whether that is fatal to the request it is serving. It is not fatal
     * to the *dispatch*: the status change has already committed by the time this runs, and an
     * order that went out without being lodged is a retryable state, not a mistake to undo.
     */
    public function dispatchOrder(Order $order): NawrisParcel
    {
        return ($this->dispatch)($order);
    }

    /**
     * Hand several orders to Nawris as one parcel.
     *
     * One customer, one destination, one recipient phone — refused as a whole otherwise, before
     * any call. Moves no status: the orders stay at «جاهزة» until the courier's pick-up arrives by
     * webhook and moves them all together. See {@see DispatchToNawris::group()}.
     *
     * @param  list<Order>  $orders
     */
    public function dispatchGroup(array $orders): NawrisParcel
    {
        return $this->dispatch->group($orders);
    }

    /**
     * Whether this order is one Nawris should be told about at all.
     *
     * **Not every delivery goes through them.** A city with no mapping is somewhere the business
     * uses its own courier, and «استلام مكتب» never leaves the building — neither is an error, so
     * neither may raise one. Unconfigured credentials answer false for the same reason: a
     * deployment that has not set them up yet should not have every dispatch fail.
     *
     * This is the question the Application layer asks *before* dispatching. Once it says yes, a
     * refusal from `dispatchOrder()` is a real problem worth surfacing.
     */
    public function shouldDispatch(Order $order): bool
    {
        $config = (array) config('services.nawris', []);

        if (trim((string) ($config['authentication_key'] ?? '')) === '') {
            return false;
        }

        $order->loadMissing('city');

        return $order->fulfilment_type === FulfilmentType::Delivery
            && $order->city?->nawris_government_id !== null
            && trim((string) $order->city?->nawris_government_id) !== '';
    }

    /**
     * Tell Nawris the COD moved.
     *
     * **Safe to call whenever an order's money changes**, including when nothing is out with the
     * carrier: it answers with null rather than refusing, so the payment path does not have to
     * know whether this order happens to be on a courier's van. That is what keeps the carrier
     * out of the ledger's business.
     */
    public function syncMoneyFor(Order $order): ?NawrisParcel
    {
        $parcel = $this->openParcelFor($order);

        return $parcel !== null ? ($this->edit)($parcel) : null;
    }

    /**
     * Delete the parcel at the carrier and close ours, freeing the order to be sent again.
     *
     * Answers `null` when there is nothing out, so pressing it twice is a person checking rather
     * than an error — the same courtesy {@see cancelShipmentFor} extends.
     */
    public function deleteShipmentFor(Order $order): ?NawrisParcel
    {
        $parcel = $this->openParcelFor($order);

        return $parcel !== null ? ($this->delete)($parcel) : null;
    }

    /**
     * Let go of the parcel without telling the carrier, for one they already deleted themselves.
     *
     * Releases every order in it, not only this one — see {@see DetachNawrisParcel}.
     */
    public function detachParcelFrom(Order $order): ?NawrisParcel
    {
        $parcel = $this->openParcelFor($order);

        return $parcel !== null ? ($this->detach)($parcel) : null;
    }

    /**
     * Call off a live shipment.
     *
     * Does **not** move the order — see {@see CancelNawrisParcel}. The goods still have to come
     * home, and they come home the ordinary way.
     */
    public function cancelShipmentFor(Order $order): ?NawrisParcel
    {
        $parcel = $this->openParcelFor($order);

        return $parcel !== null ? ($this->cancel)($parcel) : null;
    }

    /** Send a returned parcel out again, under a new code and a new row. */
    public function resendFor(Order $order): ?NawrisParcel
    {
        $parcel = NawrisParcel::query()
            ->whereHas('links', fn ($q) => $q->where('order_id', $order->getKey()))
            ->latest('id')
            ->first();

        return $parcel !== null ? ($this->resend)($parcel) : null;
    }

    /**
     * The parcel an order is currently out with, if any.
     *
     * Reads `closed_at` rather than a status, which is what makes "still out there" a query.
     */
    public function openParcelFor(Order $order): ?NawrisParcel
    {
        return NawrisParcel::query()
            ->whereNull('closed_at')
            ->whereHas('links', fn ($q) => $q->where('order_id', $order->getKey()))
            ->first();
    }

    /**
     * The carrier's code for each of a page of orders, keyed by order id.
     *
     * **What lets an order screen show «كود النورس» without `Order` learning that a carrier
     * exists.** The back-reference a relation would need is the cycle RULES §3 forbids — see
     * {@see ordersNotLodged()}, which refuses the same convenience for the same reason. The table
     * name is the seam: this context already knows it, and a controller that is allowed to know
     * both hands the answer to the resource.
     *
     * **The latest link wins.** A resent order sits in more than one parcel over its life, and
     * the code a person reads off the screen has to be the one on the label in the courier's hand
     * — so the rows are walked newest link first and the first one per order is kept. `is_open`
     * comes from `closed_at`, the same reading «ما زال في الطريق» is built on everywhere else.
     *
     * A parcel whose code has not come back yet is skipped rather than published as null: that
     * instant exists only between building the row and the carrier's response, and «كود النورس:
     * لا شيء» is a worse answer than no line at all.
     *
     * **`shared_with` names the other orders in the same parcel**, empty for a parcel of one. It is
     * what lets the order screen say «ضمن طرد مشترك مع …», and lets every button that acts on the
     * parcel say which other orders it will take with it. One more query for the whole page, not
     * one per order.
     *
     * @param  list<int>  $orderIds
     * @return array<int, array{code: string, bar_code: ?string, is_open: bool, shared_with: list<array{id: int, code: string}>}>
     */
    public function parcelCodesFor(array $orderIds): array
    {
        if ($orderIds === []) {
            return [];
        }

        $rows = DB::table('nawris_parcel_orders as l')
            ->join('nawris_parcels as p', 'p.id', '=', 'l.nawris_parcel_id')
            ->whereIn('l.order_id', $orderIds)
            ->whereNull('l.deleted_at')
            ->whereNull('p.deleted_at')
            ->whereNotNull('p.code')
            ->orderByDesc('l.id')
            ->get(['l.order_id', 'l.nawris_parcel_id', 'p.code', 'p.bar_code', 'p.closed_at']);

        $latest = [];

        foreach ($rows as $row) {
            // Newest first, so the first one seen for an order is the one to keep.
            $latest[(int) $row->order_id] ??= $row;
        }

        $members = $this->ordersInParcels(
            array_values(array_unique(array_map(fn ($row): int => (int) $row->nawris_parcel_id, $latest))),
        );

        $codes = [];

        foreach ($latest as $orderId => $row) {
            $codes[$orderId] = [
                'code' => (string) $row->code,
                'bar_code' => $row->bar_code === null ? null : (string) $row->bar_code,
                'is_open' => $row->closed_at === null,
                'shared_with' => array_values(array_filter(
                    $members[(int) $row->nawris_parcel_id] ?? [],
                    fn (array $member): bool => $member['id'] !== $orderId,
                )),
            ];
        }

        return $codes;
    }

    /**
     * Every live order in each of these parcels, by parcel id, in id order.
     *
     * @param  list<int>  $parcelIds
     * @return array<int, list<array{id: int, code: string}>>
     */
    private function ordersInParcels(array $parcelIds): array
    {
        if ($parcelIds === []) {
            return [];
        }

        $rows = DB::table('nawris_parcel_orders as l')
            ->join('orders as o', 'o.id', '=', 'l.order_id')
            ->whereIn('l.nawris_parcel_id', $parcelIds)
            ->whereNull('l.deleted_at')
            ->whereNull('o.deleted_at')
            ->orderBy('o.id')
            ->get(['l.nawris_parcel_id', 'o.id', 'o.code']);

        $members = [];

        foreach ($rows as $row) {
            $members[(int) $row->nawris_parcel_id][] = ['id' => (int) $row->id, 'code' => (string) $row->code];
        }

        return $members;
    }

    /**
     * Orders that left as deliveries but were never lodged with the carrier.
     *
     * **The outbound twin of «وصل ولم يُعالَج».** Because the carrier call happens after the
     * status change commits, a failure leaves an order at «جاري التوصيل» with no parcel and no
     * webhook that will ever arrive for it. Nothing is wrong with the order — it simply is not
     * lodged — so this is a queue to work, and it wants an alert rather than a screen somebody
     * remembers to open.
     *
     * **Written as a raw `whereNotExists` rather than as a relation on `Order`.** A
     * `$order->nawrisLinks()` relation would be convenient and would make `Order` import
     * `Carrier` — a back-reference from the context this one depends on, which is the cycle
     * RULES.md §3 forbids. The table name is the seam instead: this context already knows it,
     * and `Order` stays ignorant that a carrier exists.
     *
     * @return Builder<Order>
     */
    public function ordersNotLodged(): Builder
    {
        return Order::query()
            ->where('status', OrderStatus::OutForDelivery->value)
            ->whereHas('city', fn ($city) => $city->whereNotNull('nawris_government_id'))
            ->whereNotExists(
                fn ($link) => $link->select(DB::raw('1'))
                    ->from('nawris_parcel_orders')
                    ->whereColumn('nawris_parcel_orders.order_id', 'orders.id')
                    ->whereNull('nawris_parcel_orders.deleted_at'),
            );
    }
}
