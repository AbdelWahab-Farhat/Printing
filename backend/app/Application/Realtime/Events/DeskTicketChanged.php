<?php

declare(strict_types=1);

namespace App\Application\Realtime\Events;

use App\Application\Api\V1\Resources\SupportTicketMessageResource;
use App\Application\Api\V1\Resources\SupportTicketResource;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Broadcasting\ShouldRescue;

/**
 * ما يسمعه مكتبُ الدعم حين تتغيّر تذكرة: التذكرةُ كما يراها في طابوره، والرسالةُ الجديدة إن كانت.
 *
 * **بالمورد نفسه الذي يرسله الـ API للمكتب** ({@see SupportTicketResource})، فالصفُّ الذي يرقّعه
 * التطبيق من المقبس هو الصفُّ الذي كان سيقرؤه من `GET support/tickets` — لا شكلٌ ثالث يُحفظ
 * متزامناً مع الاثنين. بلا الخيط كاملاً: الطابور لا يرسم الرسائل، والخيطُ المفتوح يضيف الرسالةَ
 * الواحدة التي جاءت.
 *
 * **`ShouldBroadcastNow` لا عبر الطوابير**: ردٌّ حيٌّ ينتظر عاملاً يستيقظ كل ثلاث ثوانٍ ليس حيّاً.
 * **و`ShouldRescue`**: إن كان Reverb نائماً سُجّل الفشل ولم يُرمَ على أحد — انظر
 * BroadcastTicketChange.
 */
final class DeskTicketChanged implements ShouldBroadcastNow, ShouldRescue
{
    /** اسمُ الحدث كما يربط عليه التطبيقان — واحدٌ للطرفين، والقناةُ هي ما يفرّقهما. */
    public const NAME = 'support.ticket.changed';

    public function __construct(
        public readonly SupportTicket $ticket,
        public readonly ?TicketMessage $message = null,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel('support.desk')];
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
        return [
            'ticket' => (new SupportTicketResource($this->ticket))->resolve(),
            'message' => $this->message === null
                ? null
                : (new SupportTicketMessageResource($this->message))->resolve(),
        ];
    }
}
