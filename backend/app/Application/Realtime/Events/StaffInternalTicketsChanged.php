<?php

declare(strict_types=1);

namespace App\Application\Realtime\Events;

use App\Domain\InternalTicket\Enums\InternalTicketChange;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Contracts\Broadcasting\ShouldRescue;

/**
 * إشارةٌ إلى قناة كل موظفٍ تعنيه: تذكرةٌ هو طرفٌ فيها تغيّرت — فتعيد بطاقةُ الرئيسية والقائمةُ
 * طلبَ ما تعرضانه.
 *
 * **رقمٌ وسببٌ فقط**، كإشارة بريمولا `ticket.home.changed`: «مَن ينتظر مَن» وعددُ غير المقروء
 * يختلفان من قارئٍ لآخر، فحمولةٌ واحدة كانت ستكذب على أحدهما. والطلبُ الذي يليها يحسبهما له.
 */
final class StaffInternalTicketsChanged implements ShouldBroadcastNow, ShouldRescue
{
    public const NAME = 'internal_ticket.home.changed';

    /**
     * @param  list<int>  $userIds
     */
    public function __construct(
        public readonly array $userIds,
        public readonly int $ticketId,
        public readonly InternalTicketChange $change,
    ) {}

    /**
     * @return array<int, PrivateChannel>
     */
    public function broadcastOn(): array
    {
        return array_map(fn (int $id) => new PrivateChannel('staff.'.$id), $this->userIds);
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
        return ['ticket_id' => $this->ticketId, 'change' => $this->change->value];
    }
}
