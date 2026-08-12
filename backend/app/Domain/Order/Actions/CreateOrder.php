<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\CustomerService;
use App\Domain\Customer\Exceptions\CustomerIsInactive;
use App\Domain\Customer\Exceptions\ShopDoesNotBelongToCustomer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\DiscountRequiresPermission;
use App\Domain\Order\Exceptions\OrderNeedsAtLeastOneItem;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * Takes an order.
 *
 * The whole thing is one transaction: an order that exists with no lines, or with lines and no
 * opening row in its timeline, is worse than an order that failed outright.
 */
final class CreateOrder
{
    public function __construct(
        private readonly ResolveOrderDestination $resolveDestination,
        private readonly AddOrderItem $addItem,
        private readonly RecalculateOrderTotals $recalculate,
        private readonly RecordStatusTransition $record,
        private readonly CustomerService $customers,
        private readonly AddOrderDesign $addDesign,
    ) {}

    /**
     * @throws OrderNeedsAtLeastOneItem
     * @throws DiscountRequiresPermission
     * @throws ShopDoesNotBelongToCustomer
     */
    public function __invoke(OrderData $data, ?User $actor = null): Order
    {
        if ($data->items === null || $data->items === []) {
            throw OrderNeedsAtLeastOneItem::make();
        }

        $this->guardDiscount($data, $actor);

        $customer = $this->customers->find($data->customerId);

        // Before anything is priced or written: a deactivated customer is one the shop has
        // stopped selling to, and «معطَّل» has to mean that here rather than only in the app
        // that hides the button.
        if (! $customer->is_active) {
            throw CustomerIsInactive::make((string) $customer->name);
        }

        $shopName = $this->resolveShop($data, (int) $customer->getKey());

        $destination = ($this->resolveDestination)($data->cityId, $data->regionId);

        return DB::transaction(function () use ($data, $destination, $customer, $shopName, $actor): Order {
            $order = new Order;

            $order->fill([
                'customer_shop_id' => $data->customerShopId,
                // Snapshotted like the city and the region: a renamed branch must not rewrite
                // where an old order said it was going.
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
                'tracking_number' => $data->trackingNumber,
            ]);

            // Server-assigned, so they go on directly rather than through the fillable list —
            // a request that could post these could post any total it liked. `customer_id` is
            // here for a different reason: an order never changes hands, so leaving it
            // unfillable is what stops an update moving one between customers.
            $order->forceFill([
                'customer_id' => $customer->getKey(),
                'status' => OrderStatus::New,
                'design_fee' => $data->designSource->isChargeable() ? $data->designFee : '0.00',
                'delivery_price' => $destination->deliveryPrice,
                'discount' => $data->discount,
                'placed_at' => now(),
                'created_by' => $actor?->getKey(),
            ]);

            $order->save();

            foreach ($data->items as $item) {
                ($this->addItem)($order, $item);
            }

            // **The artwork the customer walked in with.** Through {@see AddOrderDesign} like
            // every other version, so the rule that a design belongs to this customer is
            // enforced by the one place that knows it, and the version numbers are allocated the
            // same way — in the order the clerk picked them.
            //
            // Inside the transaction, which is the whole reason it happens here rather than in
            // a second request from the app: a design belonging to somebody else takes the order
            // down with it, instead of leaving one behind with a number, a customer, and none of
            // the files it was taken for.
            //
            // The order is «جديدة» at this point and that status accepts versions — see
            // {@see Order::designsAreEditable()}. Before this it did not, and the file could
            // only be recorded by walking the order through the designer's queue for work
            // nobody was doing.
            foreach ($data->designIds as $designId) {
                ($this->addDesign)($order, $designId);
            }

            ($this->recalculate)($order->load('items'));

            // `from` is null exactly once per order, which is what makes "when was this taken"
            // a query on the timeline rather than a special case somewhere else.
            ($this->record)($order, null, OrderStatus::New, null, $actor);

            return $order->refresh();
        });
    }

    /**
     * The field is hidden in the app for staff without the grant. This is the half that
     * matters: a hidden field is a suggestion, a refused request is a rule.
     *
     * @throws DiscountRequiresPermission
     */
    private function guardDiscount(OrderData $data, ?User $actor): void
    {
        if (bccomp($data->discount, '0', Money::SCALE) <= 0) {
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
