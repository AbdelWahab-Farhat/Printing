<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\CustomerService;
use App\Domain\Customer\Exceptions\ShopDoesNotBelongToCustomer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Exceptions\DestinationCannotChange;
use App\Domain\Order\Exceptions\DiscountRequiresPermission;
use App\Domain\Order\Exceptions\OrderIsClosed;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
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
 *   the label is real.
 * - **The lines close when printing starts**, enforced by {@see SyncOrderItems}.
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
    ) {}

    /**
     * @throws OrderIsClosed
     * @throws DestinationCannotChange
     * @throws DiscountRequiresPermission
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
        $shopName = $this->resolveShop($data, (int) $order->customer_id);

        $destinationMoved = (int) $order->city_id !== $data->cityId
            || (int) $order->region_id !== (int) $data->regionId;

        if ($destinationMoved && ! $order->destinationIsEditable()) {
            throw DestinationCannotChange::make($order->status);
        }

        $destination = ($this->resolveDestination)($data->cityId, $data->regionId);

        return DB::transaction(function () use ($order, $data, $destination, $shopName): Order {
            $order->update([
                'customer_shop_id' => $data->customerShopId,
                'customer_shop_name' => $shopName,
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
                'shipping_company' => $data->shippingCompany,
                'tracking_number' => $data->trackingNumber,
                'courier_name' => $data->courierName,
            ]);

            $order->forceFill([
                'design_fee' => $data->designFee,
                'delivery_price' => $destination->deliveryPrice,
                'discount' => $data->discount,
            ])->save();

            if ($data->items !== null) {
                ($this->syncItems)($order, $data->items);
            }

            return ($this->recalculate)($order->load('items'))->refresh();
        });
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
