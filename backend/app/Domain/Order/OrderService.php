<?php

declare(strict_types=1);

namespace App\Domain\Order;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\AddOrderDesign;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Actions\CreateManufacturingCostRate;
use App\Domain\Order\Actions\CreateOrder;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\Actions\RecordScrapLoss;
use App\Domain\Order\Actions\RefundOrderPayment;
use App\Domain\Order\Actions\ReverseOrderPayment;
use App\Domain\Order\Actions\ReviewOrderDesign;
use App\Domain\Order\Actions\UpdateManufacturingCostRate;
use App\Domain\Order\Actions\UpdateOrder;
use App\Domain\Order\DTOs\ManufacturingCostRateData;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Exceptions\ScrapRequiresAnActor;
use App\Domain\Order\Models\ManufacturingCostRate;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Models\ProductionCostEntry;
use App\Domain\Order\Queries\ManufacturingCostRateFilters;
use App\Domain\Order\Queries\ManufacturingCostRateListQuery;
use App\Domain\Order\Queries\OrderFilters;
use App\Domain\Order\Queries\OrderListQuery;
use App\Domain\Order\Queries\OrderPaymentStatusCountsQuery;
use App\Domain\Order\Queries\OrderStatusCountsQuery;
use App\Domain\Order\Queries\OrderTotalsQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

/**
 * The Order module's public front door.
 *
 * Order depends on Catalog, Customer, Delivery and Identity, and reaches every one of them
 * through its service rather than its models. None of the four knows this module exists — which
 * is what lets an order gain a concept without the catalogue or the delivery map having to be
 * told.
 */
class OrderService
{
    public function __construct(
        private readonly CreateOrder $createOrder,
        private readonly UpdateOrder $updateOrder,
        private readonly ChangeOrderStatus $changeStatus,
        private readonly AddOrderDesign $addDesign,
        private readonly ReviewOrderDesign $reviewDesign,
        private readonly RecordOrderPayment $recordPayment,
        private readonly RefundOrderPayment $refundPayment,
        private readonly ReverseOrderPayment $reversePayment,
        private readonly CreateManufacturingCostRate $createManufacturingCostRate,
        private readonly UpdateManufacturingCostRate $updateManufacturingCostRate,
        private readonly RecordScrapLoss $recordScrapLoss,
        private readonly OrderListQuery $listQuery,
        private readonly OrderStatusCountsQuery $statusCounts,
        private readonly OrderPaymentStatusCountsQuery $paymentStatusCounts,
        private readonly OrderTotalsQuery $totals,
        private readonly ManufacturingCostRateListQuery $manufacturingCostRateListQuery,
    ) {}

    /**
     * @return LengthAwarePaginator<int, Order>
     */
    public function paginate(OrderFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->listQuery)($filters, $perPage);
    }

    /**
     * How many orders sit in each status, under the same filters as the list beside it.
     *
     * @return array<string, int>
     */
    public function statusCounts(OrderFilters $filters): array
    {
        return ($this->statusCounts)($filters);
    }

    /**
     * How many orders stand unpaid, part-paid, paid and overpaid, under the same filters.
     *
     * A second axis beside {@see statusCounts()} and never folded into it: «جاهزة» says nothing
     * about whether an order is paid, which is the whole reason the two were never merged into
     * one enum.
     *
     * @return array<string, int>
     */
    public function paymentStatusCounts(OrderFilters $filters): array
    {
        return ($this->paymentStatusCounts)($filters);
    }

    /**
     * How much work has come in: ever, today, and this month.
     *
     * Unfiltered on purpose — these are the shop's own numbers, not a view of a list somebody
     * is looking at.
     *
     * @return array{total: int, daily: int, monthly: int}
     */
    public function totals(): array
    {
        return ($this->totals)();
    }

    public function create(OrderData $data, ?User $actor = null): Order
    {
        return ($this->createOrder)($data, $actor);
    }

    public function update(Order $order, OrderData $data, ?User $actor = null): Order
    {
        return ($this->updateOrder)($order, $data, $actor);
    }

    /**
     * @param  array<string, mixed>  $fields  What the move asked for — artwork, and whatever a
     *                                        later path adds. See {@see TransitionFields}.
     */
    public function changeStatus(
        Order $order,
        OrderStatus $target,
        ?string $reason = null,
        ?User $actor = null,
        array $fields = [],
    ): Order {
        return ($this->changeStatus)($order, $target, $reason, $actor, $fields);
    }

    public function addDesign(Order $order, int $customerDesignId, ?string $notes = null): OrderDesign
    {
        return ($this->addDesign)($order, $customerDesignId, $notes);
    }

    public function reviewDesign(
        Order $order,
        OrderDesign $design,
        OrderDesignStatus $verdict,
        ?string $reason = null,
        ?User $actor = null,
    ): OrderDesign {
        return ($this->reviewDesign)($order, $design, $verdict, $reason, $actor);
    }

    /**
     * An order's money ledger, oldest first.
     *
     * Not paginated: an order's entries are counted on one hand, and a page boundary through a
     * ledger would hide the reversal that explains the entry above it.
     *
     * @return Collection<int, OrderPayment>
     */
    public function payments(Order $order): Collection
    {
        return $order->payments()->with(['recorder', 'reversal', 'reversedPayment'])->get();
    }

    public function recordPayment(Order $order, OrderPaymentData $data, ?User $actor = null): OrderPayment
    {
        return ($this->recordPayment)($order, $data, $actor);
    }

    public function refundPayment(Order $order, OrderPaymentData $data, ?User $actor = null): OrderPayment
    {
        return ($this->refundPayment)($order, $data, $actor);
    }

    /**
     * Undoes an entry that should never have been written, by writing another beside it.
     *
     * The reason is required rather than optional — see {@see ReverseOrderPayment}.
     */
    public function reversePayment(
        Order $order,
        OrderPayment $payment,
        string $reason,
        ?User $actor = null,
    ): OrderPayment {
        return ($this->reversePayment)($order, $payment, $reason, $actor);
    }

    // ── manufacturing cost rates ────────────────────────────────────────────────────────

    /**
     * @return LengthAwarePaginator<int, ManufacturingCostRate>
     */
    public function paginateManufacturingCostRates(
        ManufacturingCostRateFilters $filters,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return ($this->manufacturingCostRateListQuery)($filters, $perPage);
    }

    public function createManufacturingCostRate(ManufacturingCostRateData $data): ManufacturingCostRate
    {
        return ($this->createManufacturingCostRate)($data);
    }

    public function updateManufacturingCostRate(
        ManufacturingCostRate $rate,
        ManufacturingCostRateData $data,
    ): ManufacturingCostRate {
        return ($this->updateManufacturingCostRate)($rate, $data);
    }

    /**
     * The ordinary way to retire a rate — it stops applying to orders entering printing from
     * this point on, and every entry it already produced keeps its own snapshotted value.
     */
    public function setManufacturingCostRateActive(ManufacturingCostRate $rate, bool $isActive): ManufacturingCostRate
    {
        $rate->update(['is_active' => $isActive]);

        return $rate;
    }

    /**
     * For the row that should never have existed — a typo, a rate entered against the wrong
     * product. Nothing points at a rate by foreign key (an applied rate is snapshotted onto its
     * `production_cost_entries` row, not referenced), so unlike a business field this needs no
     * in-use guard.
     */
    public function deleteManufacturingCostRate(ManufacturingCostRate $rate): void
    {
        $rate->delete();
    }

    // ── production ──────────────────────────────────────────────────────────────────────

    /**
     * Bags spoiled producing one line — see {@see RecordScrapLoss}. Only possible once the order
     * has reached printing.
     */
    public function recordScrapLoss(
        Order $order,
        OrderItem $item,
        string $quantity,
        string $notes,
        ?User $actor = null,
    ): ProductionCostEntry {
        if ($actor === null) {
            throw ScrapRequiresAnActor::make();
        }

        return ($this->recordScrapLoss)($order, $item, $quantity, $notes, (int) $actor->getKey());
    }

    /**
     * Everything needed to render one order in full.
     *
     * **The ledger is absent on purpose.** It is read through {@see payments()} behind its own
     * permission, so loading it here would be work done for every reader and shipped to the ones
     * not allowed to see it.
     */
    public function loadForDisplay(Order $order): Order
    {
        return $order->load([
            'customer', 'shop', 'city', 'region', 'creator',
            'items', 'designs.customerDesign', 'transitions.user',
        ]);
    }
}
