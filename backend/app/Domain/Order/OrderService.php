<?php

declare(strict_types=1);

namespace App\Domain\Order;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\AddOrderDesign;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Actions\CreateOrder;
use App\Domain\Order\Actions\ReviewOrderDesign;
use App\Domain\Order\Actions\UpdateOrder;
use App\Domain\Order\DTOs\OrderData;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use App\Domain\Order\Queries\OrderFilters;
use App\Domain\Order\Queries\OrderListQuery;
use App\Domain\Order\Queries\OrderStatusCountsQuery;
use App\Domain\Order\Queries\OrderTotalsQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

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
        private readonly OrderListQuery $listQuery,
        private readonly OrderStatusCountsQuery $statusCounts,
        private readonly OrderTotalsQuery $totals,
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

    /** Everything needed to render one order in full. */
    public function loadForDisplay(Order $order): Order
    {
        return $order->load([
            'customer', 'shop', 'city', 'region', 'creator',
            'items', 'designs.customerDesign', 'transitions.user',
        ]);
    }
}
