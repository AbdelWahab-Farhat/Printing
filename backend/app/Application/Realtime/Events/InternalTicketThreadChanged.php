<?php

declare(strict_types=1);

namespace App\Application\Realtime\Events;

use App\Application\Api\V1\Resources\InternalTicket\InternalTicketMessageResource;
use App\Application\Api\V1\Resources\InternalTicket\InternalTicketResource;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Broadcasting\ShouldRescue;
use Illuminate\Http\Request;

/**
 * ما تسمعه محادثةٌ داخلية مفتوحة: ماذا تغيّر، والتذكرةُ كما صارت، والرسالةُ التي قيلت أو عُدّلت
 * أو سُحبت.
 *
 * **بالموردين نفسيهما اللذين يرسلهما الـ API**، كبثّ الدعم — **لكن بلا قارئ**: الحمولةُ واحدة لكل
 * مَن على القناة، فلا `is_mine` ولا أعلام قدرةٍ تخصّ أحداً. ولهذا تُحلّ الموارد بطلبٍ فارغ لا بطلب
 * الكاتب الذي ما زال قائماً ساعةَ البثّ (`defer`): كانت ستقول لزميله إن الرسالة رسالتُه. والتطبيقُ
 * يعرف نفسه، فيحسب `is_mine` من `author.id`، والمهلةَ من `mutable_until`.
 *
 * `ShouldBroadcastNow` و`ShouldRescue`، للسببين اللذين في DeskTicketChanged.
 */
final class InternalTicketThreadChanged implements ShouldBroadcastNow, ShouldRescue
{
    public const NAME = 'internal_ticket.changed';

    public function __construct(
        public readonly InternalTicket $ticket,
        public readonly InternalTicketChange $change,
        public readonly ?InternalTicketMessage $message = null,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel('internal-tickets.'.$this->ticket->getKey())];
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
            'ticket' => (new InternalTicketResource($this->ticket))->resolve($nobody),
            'message' => $this->message === null
                ? null
                : (new InternalTicketMessageResource($this->message))->resolve($nobody),
        ];
    }
}
