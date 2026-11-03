<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Order\DTOs\OrderTicket;
use App\Domain\Order\Enums\OrderTicketKind;
use App\Domain\Order\Models\Order;
use App\Domain\Support\Models\SupportTicket;

/**
 * «التذاكر المرتبطة»: كلُّ تذكرةٍ تحمل `order_id` هذه الطلبية ويحقّ لقارئها رؤيتها، من الأنواع
 * الثلاثة، المفتوحةُ أولاً ثم الأحدثُ نشاطاً.
 *
 * **قاعدةُ الرؤية قاعدةُ كلّ نوعٍ نفسها، لا قاعدةٌ رابعة**:
 *
 * - تذكرةُ الموظفين: طرفاها والمدير — {@see InternalTicket::isVisibleTo()}.
 * - تذكرةُ التصميم: لمن يملك `design_tickets.view`، ثم ما هو طرفٌ فيه والطابورُ المشترك ما لم
 *   يملك `view_all` — {@see DesignTicket::isVisibleTo()}.
 * - تذكرةُ العميل: لمن يملك `support.view`، كقائمتها.
 *
 * **والتضييقُ بعد الجلب هنا، بخلاف القوائم**، لأن ما منعها منه هناك — صفحةٌ تُسقط صفوفاً فتقصر —
 * لا وجود له: تذاكرُ طلبيةٍ واحدة بضعُ صفوف بلا صفحات. فتُسأل دوالُّ النماذج نفسها بدل كتابة
 * القاعدة مرّةً ثالثة في SQL.
 */
final class OrderTicketsQuery
{
    /**
     * @return list<OrderTicket>
     */
    public function __invoke(Order $order, User $reader): array
    {
        $orderId = (int) $order->getKey();

        $tickets = [
            ...$this->internal($orderId, $reader),
            ...$this->design($orderId, $reader),
            ...$this->support($orderId, $reader),
        ];

        usort($tickets, fn (OrderTicket $a, OrderTicket $b): int => $this->sortKey($b) <=> $this->sortKey($a));

        return $tickets;
    }

    /**
     * @return array{0: bool, 1: int, 2: int}
     */
    private function sortKey(OrderTicket $ticket): array
    {
        return [$ticket->isOpen, $ticket->activityAt?->getTimestamp() ?? 0, $ticket->id];
    }

    /**
     * @return list<OrderTicket>
     */
    private function internal(int $orderId, User $reader): array
    {
        return InternalTicket::query()
            ->where('order_id', $orderId)
            ->get()
            ->filter(fn (InternalTicket $ticket): bool => $ticket->isVisibleTo($reader))
            ->map(fn (InternalTicket $ticket): OrderTicket => new OrderTicket(
                kind: OrderTicketKind::Internal,
                id: (int) $ticket->getKey(),
                code: $ticket->code,
                title: $ticket->title,
                status: $ticket->status->value,
                statusLabel: $ticket->status->label(),
                isOpen: $ticket->status->isOpen(),
                activityAt: $ticket->last_message_at ?? $ticket->updated_at,
            ))
            ->values()
            ->all();
    }

    /**
     * @return list<OrderTicket>
     */
    private function design(int $orderId, User $reader): array
    {
        if (! $reader->can(PermissionName::ViewDesignTickets->value)) {
            return [];
        }

        $seesAll = $reader->can(PermissionName::ViewAllDesignTickets->value);

        return DesignTicket::query()
            ->where('order_id', $orderId)
            ->get()
            ->filter(fn (DesignTicket $ticket): bool => $seesAll || $ticket->isVisibleTo($reader))
            ->map(fn (DesignTicket $ticket): OrderTicket => new OrderTicket(
                kind: OrderTicketKind::Design,
                id: (int) $ticket->getKey(),
                code: $ticket->code,
                title: $ticket->title,
                status: $ticket->status->value,
                statusLabel: $ticket->status->label(),
                isOpen: $ticket->status->isOpen(),
                activityAt: $ticket->updated_at,
            ))
            ->values()
            ->all();
    }

    /**
     * @return list<OrderTicket>
     */
    private function support(int $orderId, User $reader): array
    {
        if (! $reader->can(PermissionName::ViewSupportTickets->value)) {
            return [];
        }

        return SupportTicket::query()
            ->where('order_id', $orderId)
            ->get()
            ->map(fn (SupportTicket $ticket): OrderTicket => new OrderTicket(
                kind: OrderTicketKind::Support,
                id: (int) $ticket->getKey(),
                code: null,
                title: $ticket->subject,
                status: $ticket->status->value,
                statusLabel: $ticket->status->label(),
                isOpen: $ticket->status->isOpen(),
                activityAt: $ticket->last_message_at ?? $ticket->updated_at,
            ))
            ->values()
            ->all();
    }
}
