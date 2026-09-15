<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\Customer\CustomerService;
use App\Domain\DesignTicket\DTOs\DesignTicketData;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketAssigned;
use App\Domain\DesignTicket\Exceptions\DesignTicketOrderBelongsToAnotherCustomer;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\Order;

/**
 * Opens a design request and puts it in front of a designer.
 *
 * **The customer is resolved through {@see CustomerService}, never queried here.** That seam is
 * what lets the Customer context change internally without a ripple, and it is also what makes
 * the snapshot honest: `customer_name` is copied off the resolved row, so it can never be a claim
 * from a request body.
 *
 * **The snapshot is the access-control decision, not a denormalisation for speed.** It is what
 * lets a designer read whose bag they are drawing without holding `customers.view` — the grant
 * that would open that customer's orders and money. See DESIGN-TICKETS-DESIGN.md §6.1.
 *
 * **An order is optional and checked when given.** A ticket for one customer pointing at
 * another's order would put the approved artwork on an account the work was never done for.
 *
 * No transaction: one insert, and the event is dispatched after it. The code is allocated by the
 * model's `creating` hook, so every path that creates a ticket gets one.
 */
final class CreateDesignTicket
{
    public function __construct(private readonly CustomerService $customers) {}

    /**
     * @throws DesignTicketOrderBelongsToAnotherCustomer
     */
    public function __invoke(DesignTicketData $data, ?User $actor = null): DesignTicket
    {
        $customer = $this->customers->find($data->customerId);

        if ($data->orderId !== null) {
            $order = Order::query()->findOrFail($data->orderId);

            if ((int) $order->customer_id !== (int) $customer->getKey()) {
                throw DesignTicketOrderBelongsToAnotherCustomer::make(
                    (int) $order->getKey(),
                    (int) $customer->getKey(),
                );
            }
        }

        $ticket = new DesignTicket([
            'order_id' => $data->orderId,
            'title' => $data->title,
            'description' => $data->description,
            'instructions' => $data->instructions,
        ]);

        // Force-filled rather than mass-assigned, all of it: the customer and its snapshot must
        // agree and neither may come from a body, the status is where every ticket starts, and
        // the requester is the signed-in user — attribution nobody can set is attribution nobody
        // can forge.
        $ticket->forceFill([
            'customer_id' => $customer->getKey(),
            'customer_name' => $customer->name,
            'status' => DesignTicketStatus::New,
            'requested_by_user_id' => $actor?->getKey(),
            'assigned_designer_id' => $data->assignedDesignerId,
        ])->save();

        // After the write, and fired whether or not a designer was named: a ticket left in the
        // shared pool is news for every designer, which is exactly what a null id means to the
        // notification. Queued after commit — one about a transaction that rolled back must never
        // have been sent.
        DesignTicketAssigned::dispatch(
            (int) $ticket->getKey(),
            $data->assignedDesignerId,
            $actor === null ? null : (int) $actor->getKey(),
        );

        return $ticket->refresh();
    }
}
