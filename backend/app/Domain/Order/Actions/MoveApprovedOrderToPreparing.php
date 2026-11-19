<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;

/**
 * **A design approved on its ticket sends the order on to «بانتظار التجهيز»** (owner, 2026-11-18).
 *
 * Called by `ReviewDesignVersion` once the approved design is on the order. Only an order still
 * in «قيد التصميم» on the printed road moves: the وسيط road has no «بانتظار التجهيز», and an order
 * somewhere else was moved on purpose by somebody.
 *
 * **Asks before it moves, rather than catching a refusal** — nothing in `app/` catches. The
 * questions are the refusals {@see ChangeOrderStatus} would give on this move: another open
 * ticket, a shortage not yet resolved, no approved design. When one applies, the approval still
 * stands and the order waits in «قيد التصميم» for a person: the designer's work is done, and an
 * order rule is not a reason to undo it. Otherwise the move goes through `ChangeOrderStatus`, so
 * every rule is still enforced there, and the reviewer is recorded as the one who moved it.
 */
final class MoveApprovedOrderToPreparing
{
    public function __construct(private readonly ChangeOrderStatus $changeStatus) {}

    public function __invoke(Order $order, ?User $actor = null): bool
    {
        $order->refresh();

        if (! $this->mayMove($order)) {
            return false;
        }

        ($this->changeStatus)($order, OrderStatus::Preparing, null, $actor);

        return true;
    }

    private function mayMove(Order $order): bool
    {
        $flow = $order->production_flow ?? OrderFlow::Standard;

        return $order->status === OrderStatus::Designing
            && $flow === OrderFlow::Standard
            && $order->status->canMoveTo(OrderStatus::Preparing, $flow)
            && ! CancelAutomaticDesignTickets::blocking($order)->exists()
            && $order->load('items')->unresolvedShortages() === []
            && $order->designs()->where('status', OrderDesignStatus::Approved)->exists();
    }
}
