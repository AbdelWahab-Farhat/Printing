<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\CustomerService;
use App\Domain\Customer\Exceptions\ShopDoesNotBelongToCustomer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\ShortageRevision;
use App\Domain\Order\Events\OrderShortagesRecorded;
use App\Domain\Order\Exceptions\AdditionalCostRequiresPermission;
use App\Domain\Order\Exceptions\DestinationCannotChange;
use App\Domain\Order\Exceptions\DiscountRequiresPermission;
use App\Domain\Order\Exceptions\EditWouldChangeTheRoad;
use App\Domain\Order\Exceptions\OrderIsClosed;
use App\Domain\Order\Exceptions\OutsourcedOrderNeedsAVendor;
use App\Domain\Order\Exceptions\RecipientPhoneCannotChange;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use App\Domain\Vendor\VendorService;
use Illuminate\Support\Facades\DB;

/**
 * Edits an order that is still open.
 *
 * Three things are guarded rather than freely editable, each for a different reason:
 *
 * - **The customer never moves.** An order belongs to whoever placed it, and reassigning one
 *   would rewrite two histories to fix a typo. Cancel it and take it again.
 * - **The destination freezes once the parcel is outside the business** — past that point the
 *   address on our screen and the address on the label have already parted company, and only
 *   the label is real. **The recipient's phone freezes with it**, being the other half of the
 *   same fact: the courier is already carrying both.
 * - **The lines close when printing starts**, enforced by {@see SyncOrderItems} — which also
 *   moves the stock behind them once it has left the shelf.
 *
 * Changing the city re-snapshots its name and its rate, and re-derives the fulfilment type. An
 * order already dispatched cannot reach this code, so there is no case where that silently
 * contradicts the status it is sitting in.
 */
final class UpdateOrder
{
    public function __construct(
        private readonly ResolveOrderDestination $resolveDestination,
        private readonly SyncOrderItems $syncItems,
        private readonly RecalculateOrderTotals $recalculate,
        private readonly CustomerService $customers,
        private readonly ResolveOrderFlow $resolveFlow,
        private readonly VendorService $vendors,
        private readonly GuardOneBench $guardOneBench,
    ) {}

    /**
     * @throws OrderIsClosed
     * @throws DestinationCannotChange
     * @throws DiscountRequiresPermission
     * @throws AdditionalCostRequiresPermission
     * @throws ShopDoesNotBelongToCustomer
     */
    public function __invoke(Order $order, OrderData $data, ?User $actor = null): Order
    {
        // Closed, not final: an order the customer already has is not editable even though it
        // still owes a settlement.
        if ($order->status->isClosed()) {
            throw OrderIsClosed::make($order->status);
        }

        $this->guardDiscount($order, $data, $actor);
        $this->guardAdditionalCost($order, $data, $actor);
        $shopName = $this->resolveShop($data, (int) $order->customer_id);

        $destinationMoved = (int) $order->city_id !== $data->cityId
            || (int) $order->region_id !== (int) $data->regionId;

        if ($destinationMoved && ! $order->destinationIsEditable()) {
            throw DestinationCannotChange::make($order->status);
        }

        // The number the courier is calling freezes when the address does — see
        // RecipientPhoneCannotChange. Compared rather than blanket-refused, because every edit
        // re-sends the whole order: a phone that comes back unchanged is not somebody changing
        // it, and refusing that would make the notes on a parcel in delivery uncorrectable.
        if ($data->recipientPhone !== $order->recipient_phone && ! $order->destinationIsEditable()) {
            throw RecipientPhoneCannotChange::make($order->status);
        }

        $destination = ($this->resolveDestination)($data->cityId, $data->regionId);

        // Re-read on every edit, like the city name beside it: moving the job to another vendor
        // moves the name with it, and clearing the vendor clears both.
        $vendorName = $data->vendorId === null
            ? null
            : (string) $this->vendors->find($data->vendorId)->name;

        $updated = DB::transaction(function () use ($order, $data, $destination, $shopName, $vendorName, $actor): Order {
            // **The lock `ChangeOrderStatus` takes first, taken first here too.** An edit to the
            // lines can move stock, and so can a status move — so the two must not interleave: a
            // cancellation crediting back a draw this edit is replacing would reverse it twice.
            // Whichever arrives second waits, then reads the order as the first one left it.
            Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();
            $order->refresh();

            // What the lines said before this edit, so a road the edit did not move is never a
            // reason to refuse it — see the guard after the lines are written.
            $roadBefore = $data->items === null ? null : $this->resolveFlow->fromLines($order);

            $order->update([
                'customer_shop_id' => $data->customerShopId,
                'customer_shop_name' => $shopName,
                'vendor_id' => $data->vendorId,
                'vendor_name' => $vendorName,
                'city_id' => $destination->cityId,
                'region_id' => $destination->regionId,
                'city_name' => $destination->cityName,
                'region_name' => $destination->regionName,
                'fulfilment_type' => $destination->fulfilmentType,
                'design_source' => $data->designSource,
                'recipient_name' => $data->recipientName,
                'recipient_phone' => $data->recipientPhone,
                'address_details' => $data->addressDetails,
                'notes' => $data->notes,
                'tracking_number' => $data->trackingNumber,
                // **Only when the request mentioned it.** Every edit re-sends the whole order,
                // so a key that never arrived has to leave the flag standing — otherwise
                // correcting an address on an urgent order would quietly calm it down. See
                // OrderData::$isUrgent.
                ...($data->isUrgent === null ? [] : ['is_urgent' => $data->isUrgent]),
            ]);

            $order->forceFill([
                'design_fee' => $data->designFee,
                'delivery_price' => $destination->deliveryPrice,
                'discount' => $data->discount,
                'additional_cost' => $data->additionalCost,
                'additional_cost_reason' => $data->additionalCostReason,
                'additional_cost_note' => $data->additionalCostNote,
            ])->save();

            if ($data->items !== null) {
                ($this->syncItems)($order, $data->items, $actor);

                // The rule `CreateOrder` asks on the way in, asked again now that lines can be
                // added: a وسيط line beside an in-house one is refused whichever door it used.
                ($this->guardOneBench)($order);

                $this->guardTheRoadCanMove($order, $roadBefore);
            }

            // Called unconditionally and idempotent: a set of lines that comes back unchanged
            // resolves to the flow the order already has and writes nothing. Once work has
            // started it writes nothing at all — see {@see ResolveOrderFlow::mayMove()}.
            ($this->resolveFlow)($order->load('items'));

            // **The same question `CreateOrder` asks, asked again for the same reason.** An edit
            // can put an order onto the vendor road — swapping the last printed line out of an
            // order still in «جديدة» does exactly that — and an order that arrived there with no
            // vendor named would be one nobody could chase. Refused whole, inside the
            // transaction, so the lines are not left rewritten around a hole.
            //
            // **And skipped for a request under review, for the reason `CreateOrder` skips it.**
            // Staff correcting an address on something the customer app sent must not be refused
            // because they have not yet decided who will make it. The rule binds once, at
            // acceptance, in `ChangeOrderStatus`.
            if ($order->status !== OrderStatus::Requested
                && $order->production_flow->needsAVendor()
                && $order->vendor_id === null) {
                throw OutsourcedOrderNeedsAVendor::make();
            }

            return ($this->recalculate)($order->load('items'))->refresh();
        });

        // **After the commit, never inside it** — the rule `SetOrderShortages` follows for the
        // same event. A line removed from an order parked on a shortage takes its shortage row
        // with it, and a kept line's changed quantity is mirrored; both are the listener's job.
        if ($data->items !== null && $updated->status === OrderStatus::Shortage) {
            OrderShortagesRecorded::dispatch(
                (int) $updated->getKey(),
                ShortageRevision::Corrected,
                $actor === null ? null : (int) $actor->getKey(),
            );
        }

        return $updated;
    }

    /**
     * Refuses an edit whose lines describe another road than they did, from a status the order
     * can no longer change roads in.
     *
     * Compared with what the lines said *before* the edit rather than with the stamped road, so
     * an order whose categories were re-filed after it was taken is never refused over a road
     * this edit did not move.
     *
     * @throws EditWouldChangeTheRoad
     */
    private function guardTheRoadCanMove(Order $order, ?OrderFlow $before): void
    {
        if ($before === null) {
            return;
        }

        $after = $this->resolveFlow->fromLines($order->load('items'));

        if ($after !== $before && ! $this->resolveFlow->mayMove($order->status, $after)) {
            throw EditWouldChangeTheRoad::make($order->status, $before, $after);
        }
    }

    /**
     * Only a *change* to the discount is guarded. A clerk without the grant editing the notes on
     * an order that already carries one must not be refused for a number they did not touch.
     *
     * @throws DiscountRequiresPermission
     */
    private function guardDiscount(Order $order, OrderData $data, ?User $actor): void
    {
        if (bccomp($data->discount, (string) $order->discount, Money::SCALE) === 0) {
            return;
        }

        if (! $actor?->can(PermissionName::DiscountOrders->value)) {
            throw DiscountRequiresPermission::make();
        }
    }

    /**
     * The same rule for the charge going the other way, and only a *change* is guarded.
     *
     * **Compared on the amount alone, not on the reason beside it.** Every edit re-sends the
     * whole order, so a clerk without the grant correcting the notes on an order that already
     * carries a charge sends its reason back untouched — and refusing that would make such an
     * order uneditable by everybody else over a field nobody touched. The words cannot move
     * without the money moving with them, because the app only offers them together.
     *
     * @throws AdditionalCostRequiresPermission
     */
    private function guardAdditionalCost(Order $order, OrderData $data, ?User $actor): void
    {
        if (bccomp($data->additionalCost, (string) $order->additional_cost, Money::SCALE) === 0) {
            return;
        }

        if (! $actor?->can(PermissionName::AddOrderAdditionalCost->value)) {
            throw AdditionalCostRequiresPermission::make();
        }
    }

    /**
     * Checks the shop belongs to this customer, and hands back its name for the snapshot.
     *
     * Returning the row rather than just validating it: the name is needed a line later, and a
     * second query for something already in hand is the kind of N+1 that arrives one call site
     * at a time.
     *
     * @throws ShopDoesNotBelongToCustomer
     */
    private function resolveShop(OrderData $data, int $customerId): ?string
    {
        if ($data->customerShopId === null) {
            return null;
        }

        $shop = $this->customers->find($customerId)->shops()->find($data->customerShopId);

        if ($shop === null) {
            throw ShopDoesNotBelongToCustomer::make($data->customerShopId, $customerId);
        }

        return $shop->name;
    }
}
