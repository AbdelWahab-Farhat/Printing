<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\DesignTicket\Actions\CancelDesignTicket;
use App\Domain\DesignTicket\Enums\DesignTicketFileKind;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\Order;
use Illuminate\Database\Eloquent\Builder;

/**
 * **Closes the tickets the system opened for an order, when the order no longer needs them**
 * (owner, 2026-11-18).
 *
 * Two moments:
 *
 * - **The order leaves «قيد التصميم» for the warehouse or the press by hand** — the customer
 *   sent the final file. An automatic ticket nobody has submitted a version on is cancelled, so
 *   it leaves the designers' queue and does not block the move. One with a version is left
 *   open and keeps blocking: a designer's work is never thrown away without somebody looking.
 * - **The order is cancelled.** Every open automatic ticket goes with it.
 *
 * A ticket a person opened is never touched here; it says what somebody asked for, and only
 * somebody may call it off.
 */
final class CancelAutomaticDesignTickets
{
    public function __construct(private readonly CancelDesignTicket $cancelTicket) {}

    /**
     * The open automatic tickets on [$order] that no designer has submitted a version on.
     *
     * @return Builder<DesignTicket>
     */
    public static function untouched(Order $order): Builder
    {
        return self::open($order)
            ->whereDoesntHave('files', fn (Builder $files) => $files->where('kind', DesignTicketFileKind::Submission));
    }

    /**
     * The open tickets that keep [$order] from the warehouse or the press: every open one but
     * the {@see untouched()} automatic ones, which the move cancels instead.
     *
     * @return Builder<DesignTicket>
     */
    public static function blocking(Order $order): Builder
    {
        return DesignTicket::query()
            ->where('order_id', $order->getKey())
            ->whereNotIn('status', [DesignTicketStatus::Completed, DesignTicketStatus::Cancelled])
            ->whereKeyNot(self::untouched($order)->pluck('id')->all());
    }

    /**
     * @return Builder<DesignTicket>
     */
    private static function open(Order $order): Builder
    {
        return DesignTicket::query()
            ->where('order_id', $order->getKey())
            ->where('opened_automatically', true)
            ->whereNotIn('status', [DesignTicketStatus::Completed, DesignTicketStatus::Cancelled]);
    }

    /** The order left «قيد التصميم» onwards: only the tickets nobody worked on. */
    public function untouchedOnes(Order $order, ?User $actor = null): void
    {
        $this->cancel(self::untouched($order), 'أُلغيت لأن الطلبية خرجت من «قيد التصميم»', $actor);
    }

    /** The order was cancelled: every open automatic ticket. */
    public function all(Order $order, ?User $actor = null): void
    {
        $this->cancel(self::open($order), 'أُلغيت لأن الطلبية أُلغيت', $actor);
    }

    /**
     * @param  Builder<DesignTicket>  $tickets
     */
    private function cancel(Builder $tickets, string $reason, ?User $actor): void
    {
        foreach ($tickets->orderBy('id')->lockForUpdate()->get() as $ticket) {
            ($this->cancelTicket)($ticket, $reason, $actor);
        }
    }
}
