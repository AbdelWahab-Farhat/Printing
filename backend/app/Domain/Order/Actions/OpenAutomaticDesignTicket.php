<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\DesignTicket\Actions\CreateDesignTicket;
use App\Domain\DesignTicket\Actions\SubmitDesignVersion;
use App\Domain\DesignTicket\DTOs\DesignTicketData;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;

/**
 * **An order entering «قيد التصميم» gets a design ticket if it has no open one** (owner,
 * 2026-11-18). The status is the designer's queue; without a ticket nothing in the designers'
 * app says there is work, and somebody had to remember to open one by hand.
 *
 * Every entry counts, the correction trip back from «جاهزة للطباعة», «قيد الطباعة» or «قيد
 * التصنيع» included — a correction is design work too. An order already holding an open ticket
 * keeps it: that one is the conversation about this artwork, and a second would split it.
 *
 * The ticket goes to the shared pool, so every designer is told. It opens without print colours
 * — the system has nobody to ask — and the designer gives them with the first version, which
 * {@see SubmitDesignVersion} already insists on.
 *
 * Marked `opened_automatically`, which is what lets {@see CancelAutomaticDesignTickets} close it
 * when the order leaves the queue before anybody worked on it.
 */
final class OpenAutomaticDesignTicket
{
    public function __construct(private readonly CreateDesignTicket $createTicket) {}

    public function __invoke(Order $order, ?User $actor = null): ?DesignTicket
    {
        if ($order->status !== OrderStatus::Designing || $order->customer_id === null) {
            return null;
        }

        $hasAnOpenTicket = DesignTicket::query()
            ->where('order_id', $order->getKey())
            ->whereNotIn('status', [DesignTicketStatus::Completed, DesignTicketStatus::Cancelled])
            ->exists();

        if ($hasAnOpenTicket) {
            return null;
        }

        return ($this->createTicket)(new DesignTicketData(
            customerId: (int) $order->customer_id,
            title: "تصميم طلبية {$order->code}",
            description: "فُتحت تلقائياً عند تحويل الطلبية {$order->code} إلى «قيد التصميم»",
            orderId: (int) $order->getKey(),
            openedAutomatically: true,
        ), $actor);
    }
}
