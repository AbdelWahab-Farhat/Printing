<?php

declare(strict_types=1);

namespace App\Application\Realtime\Events;

use App\Application\Api\V1\Resources\DesignTicketMessageResource;
use App\Application\Api\V1\Resources\DesignTicketThreadResource;
use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Broadcasting\ShouldRescue;
use Illuminate\Http\Request;

/**
 * ما تسمعه محادثةُ تذكرة تصميم مفتوحة: ماذا تغيّر، والمحادثةُ كما صارت — بلا رسائلها — والرسالةُ
 * التي قيلت أو عُدّلت أو سُحبت.
 *
 * **كـ`InternalTicketThreadChanged`، بلا قارئ**: الحمولةُ واحدة لكل مَن على القناة، فلا `is_mine`
 * ولا أعلام قدرةٍ تخصّ أحداً. والتطبيقُ يعرف نفسه، فيحسب `is_mine` من `author.id`، والمهلةَ من
 * `mutable_until`، ويُبقي `can_reply` و`is_party` اللذين عنده.
 *
 * `ShouldBroadcastNow` و`ShouldRescue`، للسببين اللذين في DeskTicketChanged.
 */
final class DesignTicketThreadChanged implements ShouldBroadcastNow, ShouldRescue
{
    public const NAME = 'design_ticket.changed';

    public function __construct(
        public readonly DesignTicket $ticket,
        public readonly DesignConversationChange $change,
        public readonly ?DesignTicketMessage $message = null,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel('design-tickets.'.$this->ticket->getKey())];
    }

    public function broadcastAs(): string
    {
        return self::NAME;
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        $nobody = Request::create('/');

        return [
            'change' => $this->change->value,
            'thread' => (new DesignTicketThreadResource($this->ticket))->resolve($nobody),
            'message' => $this->message === null
                ? null
                : (new DesignTicketMessageResource($this->message))->resolve($nobody),
        ];
    }
}
