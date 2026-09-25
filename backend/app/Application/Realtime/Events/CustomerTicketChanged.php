<?php

declare(strict_types=1);

namespace App\Application\Realtime\Events;

use App\Application\Api\V1\Resources\Client\ClientSupportTicketResource;
use App\Application\Api\V1\Resources\Client\ClientTicketMessageResource;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Broadcasting\ShouldRescue;

/**
 * ما يسمعه العميلُ حين تتغيّر إحدى تذاكره، على قناته هو وحده.
 *
 * **بموارد العميل لا بموارد المكتب، وهذا هو الجدار.** اسمُ الموظف الذي ردّ ومكتبُ التذكرة لا
 * يرسلهما الـ API للعميل ({@see ClientSupportTicketResource}، {@see ClientTicketMessageResource})،
 * فلا يرسلهما المقبسُ أيضاً: الحدثُ نفسه بحمولتين لجمهورين، لا حمولةٌ واحدة يُرجى أن يتجاهل
 * أحدهما نصفها.
 *
 * بلا `preview`: الرسالةُ نفسها في الحمولة، والتطبيق يأخذ سطرَ المعاينة منها — نسختان من النص
 * نفسه في حدثٍ واحد تضاعفان أطول ما يُرسل.
 */
final class CustomerTicketChanged implements ShouldBroadcastNow, ShouldRescue
{
    public function __construct(
        public readonly SupportTicket $ticket,
        public readonly ?TicketMessage $message = null,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return [new PrivateChannel('customers.'.$this->ticket->customer_id)];
    }

    public function broadcastAs(): string
    {
        return DeskTicketChanged::NAME;
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return [
            'ticket' => (new ClientSupportTicketResource($this->ticket))->resolve(),
            'message' => $this->message === null
                ? null
                : (new ClientTicketMessageResource($this->message))->resolve(),
        ];
    }
}
