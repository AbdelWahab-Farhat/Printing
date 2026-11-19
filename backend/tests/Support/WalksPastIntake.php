<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;

/**
 * Puts an order where the map expects it before a move, for tests about something else.
 *
 * Since the owner's status document (2026-11-15; ORDERS-STATUS-FLOW.md §٢١) «جديدة» only asks the
 * deposit question, and «جاهزة للطباعة» is entered from «بانتظار التجهيز» alone. A test about stock,
 * costs or investors that used to move «جديدة» → «جاهزة للطباعة» in one step is not testing that
 * walk — `OrderStatusTest` and `OrderPreparingTest` do. So this places the order on the status the
 * move now starts from, the way a factory state would, and leaves the move itself to the domain.
 *
 * **Written with a query, not a model save**, so no audit row, event or transition appears that
 * the test did not ask for. Does nothing when the move is already legal.
 */
trait WalksPastIntake
{
    protected function walkPastIntake(Order|int $order, OrderStatus|string $target): void
    {
        $id = $order instanceof Order ? (int) $order->getKey() : $order;
        $target = $target instanceof OrderStatus ? $target : OrderStatus::from($target);

        $current = Order::query()->withTrashed()->findOrFail($id);
        $flow = $current->production_flow;

        if ($target->isDispatch()) {
            $target = OrderStatus::dispatchFor($current->fulfilment_type);
        }

        if ($current->status->canMoveTo($target, $flow)) {
            return;
        }

        $beforeThePress = [
            OrderStatus::New,
            OrderStatus::DepositPaid,
            OrderStatus::NoDeposit,
            OrderStatus::Shortage,
            OrderStatus::Designing,
        ];

        // A plain order reaches the shelf from «بانتظار التجهيز» alone (2026-11-18).
        $plainToTheShelf = $target === OrderStatus::Ready
            && $flow === OrderFlow::NoProduction
            && in_array($current->status, $beforeThePress, true);

        $place = match (true) {
            $target === OrderStatus::ReadyToPrint && in_array($current->status, $beforeThePress, true) => OrderStatus::Preparing,
            $plainToTheShelf => OrderStatus::Preparing,
            $current->status === OrderStatus::New && OrderStatus::NoDeposit->canMoveTo($target, $flow) => OrderStatus::NoDeposit,
            default => null,
        };

        if ($place === null) {
            return;
        }

        Order::query()->withTrashed()->whereKey($id)->update(['status' => $place->value]);

        if ($order instanceof Order) {
            $order->setRawAttributes(['status' => $place->value] + $order->getAttributes(), true);
        }
    }
}
