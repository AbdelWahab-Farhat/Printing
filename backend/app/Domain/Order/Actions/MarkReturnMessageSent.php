<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Exceptions\ReturnMessageNeedsAReturnedOrder;
use App\Domain\Order\Models\Order;

/**
 * Records that the customer was contacted about the return their order is in — or takes that
 * back.
 *
 * The twin of {@see MarkReadyMessageSent}: the only writer of the two columns besides the
 * clearing in `ChangeOrderStatus`, both columns together, and both directions in one action so a
 * stray tap can be undone. Nothing else on the order moves.
 */
final class MarkReturnMessageSent
{
    /**
     * @param  bool  $sent  true stamps now and the actor; false clears both.
     *
     * @throws ReturnMessageNeedsAReturnedOrder
     */
    public function __invoke(Order $order, bool $sent, ?User $actor = null): Order
    {
        if (! $order->returnMessageApplies()) {
            throw ReturnMessageNeedsAReturnedOrder::make();
        }

        // `forceFill`: neither column is fillable, so no request can put a colleague's name on it.
        $order->forceFill([
            'return_message_sent_at' => $sent ? now() : null,
            'return_message_sent_by' => $sent ? $actor?->getKey() : null,
        ])->save();

        return $order;
    }
}
