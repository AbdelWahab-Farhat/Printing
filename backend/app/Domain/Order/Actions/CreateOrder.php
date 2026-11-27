<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\CustomerService;
use App\Domain\Customer\Exceptions\CustomerIsInactive;
use App\Domain\Customer\Exceptions\ShopDoesNotBelongToCustomer;
use App\Domain\Customer\Support\PrintColors;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\DeliveryPayer;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\OrderType;
use App\Domain\Order\Exceptions\AdditionalCostRequiresPermission;
use App\Domain\Order\Exceptions\DiscountRequiresPermission;
use App\Domain\Order\Exceptions\OrderNeedsAtLeastOneItem;
use App\Domain\Order\Exceptions\OutsourcedLineCannotShareAnOrder;
use App\Domain\Order\Exceptions\OutsourcedOrderNeedsAVendor;
use App\Domain\Order\Exceptions\PrintOrderNeedsADesign;
use App\Domain\Order\Exceptions\PrintOrderNeedsColors;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use App\Domain\Vendor\VendorService;
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
        // Which road the order walks, read off its lines' categories — the flow twin of
        // `ResolveOrderDestination` above.
        private readonly ResolveOrderFlow $resolveFlow,
        // Who is making it, for the road where somebody else does — read through the Service
        // rather than the model, per RULES.md §3: cross-context work goes through the other
        // module's front door.
        private readonly VendorService $vendors,
        private readonly GuardOneBench $guardOneBench,
        private readonly GuardPrintColors $guardPrintColors,
        private readonly UpdateOrderDesignColors $updateDesignColors,
        private readonly GuardCompensation $guardCompensation,
    ) {}

    /**
     * One chosen design, with the colours the clerk typed for it in the form, if any.
     *
     * The colours fill the library design when it has none worth keeping, so the next order
     * starts with them, and the copy is taken from it. A design whose library colours are already
     * complete keeps them, and only this order's copy takes the typed list («هالمرة بالأزرق»).
     *
     * @param  array<int, array<string, mixed>>|null  $colors
     */
    private function attachDesign(Order $order, int $designId, ?array $colors): void
    {
        if ($colors !== null) {
            $design = $this->customers->findDesign($designId);

            // Ownership is AddOrderDesign's refusal to make; writing another customer's library
            // first would leave the write behind if anything but a rollback followed.
            if ((int) $design->customer_id === (int) $order->customer_id) {
                $this->customers->fillDesignColorsIfIncomplete($design, $colors);
            }
        }

        $version = ($this->addDesign)($order, $designId);

        $typed = $colors === null ? null : PrintColors::normalise($colors);

        if ($typed !== null && $version->print_colors !== $typed) {
            ($this->updateDesignColors)($order, $version, $typed);
        }
    }

    /**
     * [$initialStatus] is the door this order came through, and the only caller that passes
     * anything but the default is {@see RequestOrder} — the customer app's. It changes three
     * things and nothing else: the status written, the status the opening timeline row records,
     * and whether the vendor rule binds now or at acceptance.
     *
     * @throws OrderNeedsAtLeastOneItem
     * @throws DiscountRequiresPermission
     * @throws AdditionalCostRequiresPermission
     * @throws ShopDoesNotBelongToCustomer
     * @throws OutsourcedOrderNeedsAVendor
     * @throws OutsourcedLineCannotShareAnOrder
     * @throws PrintOrderNeedsADesign
     * @throws PrintOrderNeedsColors
     */
    public function __invoke(
        OrderData $data,
        ?User $actor = null,
        OrderStatus $initialStatus = OrderStatus::New,
        // Only {@see CreateInstantOrder} passes anything else. An instant sale is collected at the
        // branch counter and carries no delivery fee (INSTANT-ORDERS-PLAN.md §3).
        OrderType $type = OrderType::Normal,
    ): Order {
        if ($data->items === null || $data->items === []) {
            throw OrderNeedsAtLeastOneItem::make();
        }

        $this->guardDiscount($data, $actor);
        $this->guardAdditionalCost($data, $actor);

        // «طلبية تعويض» — the grant, no charges, and the original (when named) is this
        // customer's ordinary order. Only on the clerk's door: the customer app never sends it.
        if ($data->isCompensation) {
            $this->guardCompensation->permission($actor);
            $this->guardCompensation->noCharges($data->discount, $data->additionalCost);
            $this->guardCompensation->original($data->compensatesOrderId, $data->customerId);
        }

        $customer = $this->customers->find($data->customerId);

        // Before anything is priced or written: a deactivated customer is one the shop has
        // stopped selling to, and «معطَّل» has to mean that here rather than only in the app
        // that hides the button.
        if (! $customer->is_active) {
            throw CustomerIsInactive::make((string) $customer->name);
        }

        $shopName = $this->resolveShop($data, (int) $customer->getKey());

        $destination = ($this->resolveDestination)($data->cityId, $data->regionId);

        // Looked up before the transaction like the shop and the city are, and for the same
        // reason: the name is a snapshot, and reading it here means the write below has every
        // value it needs in hand. A vendor that does not exist is already refused by the request.
        $vendorName = $data->vendorId === null
            ? null
            : (string) $this->vendors->find($data->vendorId)->name;

        $payer = $data->deliveryPaidBy ?? DeliveryPayer::Recipient;

        // «أجرة التصميم» is not typed when an order is taken (ORDER-DESIGN-FEE.md). An older
        // build still sends the box: kept from whoever holds the fee, dropped from anybody else,
        // who would otherwise be pricing a number they are not allowed to read.
        $designFee = $data->designSource->isChargeable()
            && $actor?->can(PermissionName::SetOrderDesignFee->value) === true
            && ! $data->isCompensation
                ? $data->designFee
                : '0.00';
        $designFeeDecided = bccomp($designFee, '0', 2) > 0;

        $deliveryPrice = $type->isInstant() ? '0.00' : $destination->deliveryPrice;

        return DB::transaction(function () use ($data, $destination, $customer, $shopName, $vendorName, $actor, $initialStatus, $payer, $designFee, $designFeeDecided, $type, $deliveryPrice): Order {
            $order = new Order;

            $order->fill([
                'customer_shop_id' => $data->customerShopId,
                // Snapshotted like the city and the region: a renamed branch must not rewrite
                // where an old order said it was going.
                'customer_shop_name' => $shopName,
                // Chosen from the vendor list, and its name kept beside it for the same reason
                // the branch above keeps one — see OUTSOURCED-PRODUCTS.md §5.
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
                // False when nothing was said, because «لم يُسأل» and «ليست مستعجلة» are the
                // same answer for a new order — unlike on an edit, where the silence means
                // «اتركها كما هي». See OrderData::$isUrgent.
                'is_urgent' => $data->isUrgent ?? false,
            ]);

            // Server-assigned, so they go on directly rather than through the fillable list —
            // a request that could post these could post any total it liked. `customer_id` is
            // here for a different reason: an order never changes hands, so leaving it
            // unfillable is what stops an update moving one between customers.
            $order->forceFill([
                'customer_id' => $customer->getKey(),
                'status' => $initialStatus,
                'order_type' => $type,
                'design_fee' => $designFee,
                'design_fee_set_at' => $designFeeDecided ? now() : null,
                'design_fee_set_by' => $designFeeDecided ? $actor?->getKey() : null,
                'delivery_price' => $deliveryPrice,
                // The recipient unless the form said otherwise; when we pay, the city's rate is
                // the order's delivery cost until settlement shows the real one.
                'delivery_paid_by' => $payer,
                'delivery_cost' => $payer === DeliveryPayer::Us ? $deliveryPrice : '0.00',
                'discount' => $data->discount,
                // The three move together and are guarded together: an amount, why it was
                // charged, and the words beside it are one decision, not three fields.
                'additional_cost' => $data->additionalCost,
                'additional_cost_reason' => $data->additionalCostReason,
                'additional_cost_note' => $data->additionalCostNote,
                // Read by RecalculateOrderTotals below, which zeroes the total when it is set.
                'is_compensation' => $data->isCompensation,
                'compensation_reason' => $data->isCompensation ? $data->compensationReason : null,
                'compensation_note' => $data->isCompensation ? $data->compensationNote : null,
                'compensates_order_id' => $data->isCompensation ? $data->compensatesOrderId : null,
                'placed_at' => now(),
                'created_by' => $actor?->getKey(),
                // On the row in the same write, so an order and its key are never apart: the
                // unique index is what stops two copies of one request racing each other.
                'client_token' => $data->clientToken,
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
                $this->attachDesign($order, $designId, $data->designColors[$designId] ?? null);
            }

            ($this->recalculate)($order->load('items'));

            // The other thing the lines decide, read the moment they are all on: whether this
            // order has anything to design or print at all — see {@see ResolveOrderFlow}. Inside
            // the transaction and after the loop above, because it is an answer about the whole
            // set: an order is only put on the short road when *every* line is goods that are
            // already made.
            ($this->resolveFlow)($order);

            // **The lines must agree about whose bench they are made on.**
            // `ResolveOrderFlow` above wants them unanimous and falls back to the standard road
            // when they are not — right for «سادة» beside «مطبوعة», and wrong the moment a
            // وسيط line is in the order: that order would walk «قيد التصميم» and «قيد الطباعة»
            // for goods no press of ours touches, and `deductsStock()` would ask a warehouse for
            // goods that were never on a shelf of ours.
            //
            // Asked here for the reason the vendor rule below is: the answer is read off the
            // lines' categories, so it cannot be had until the lines exist. Inside the same
            // transaction, so a refused order is rolled back whole — and *both* doors come
            // through here, the clerk's and the app's, so there is one rule and no way round it.
            ($this->guardOneBench)($order);

            // **Asked here and nowhere earlier, because here is the first place it can be
            // asked.** Whether an order owes a vendor depends on the road it walks, and the road
            // is read off the lines that were written moments ago — a rule in the request would
            // have to guess at it from product ids. Inside the transaction, so an order that
            // should have named a vendor is rolled back whole rather than left standing without
            // one.
            //
            // **Except for a request, which is allowed to be incomplete.** An order the customer
            // app sent cannot name a vendor — the customer does not know we outsource anything,
            // and it is not their choice to make. So the rule binds at *acceptance* instead:
            // `ChangeOrderStatus` refuses «بانتظار المراجعة» → «جديدة» until a vendor is named,
            // which is the moment a real order comes into being. A request under review may be
            // incomplete; an order may not.
            if ($initialStatus !== OrderStatus::Requested
                && $order->production_flow->needsAVendor()
                && $order->vendor_id === null) {
                throw OutsourcedOrderNeedsAVendor::make();
            }

            // **No print order without its colours** (PRINT-COLORS.md §9). After the road is
            // resolved, because only the standard road reaches our press. Only on the clerk's
            // door («جديدة»): the customer app's orders — a request, or one born waiting on its
            // deposit — must not lose their checkout over it. A request meets the rule when it is
            // accepted, and every order meets it again on the way into «قيد الطباعة».
            if ($initialStatus === OrderStatus::New) {
                $this->guardPrintColors->forIntake($order);
            }

            // `from` is null exactly once per order, which is what makes "when was this taken"
            // a query on the timeline rather than a special case somewhere else.
            ($this->record)($order, null, $initialStatus, null, $actor);

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
     * The other half of the same arrangement, and a grant of its own.
     *
     * Charging a customer more is not the same decision as charging them less, however alike
     * the two fields look — see {@see AdditionalCostRequiresPermission}.
     *
     * @throws AdditionalCostRequiresPermission
     */
    private function guardAdditionalCost(OrderData $data, ?User $actor): void
    {
        if (bccomp($data->additionalCost, '0', Money::SCALE) <= 0) {
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
