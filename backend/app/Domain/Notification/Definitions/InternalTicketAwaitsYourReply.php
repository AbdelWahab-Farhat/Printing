<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * تذكيرٌ لمن يُنتظر ردّه في تذكرةٍ داخلية — مرّةً في اليوم، حتى ٢٤ يوماً.
 *
 * **إلى المنتظَر لا إلى الزميل الذي وُجّهت إليه**: صاحبُ التذكرة يُنتظر ردّه بقدر ما يُنتظر ردُّ
 * زميله. يحسبه `RemindAwaitedParties` ويحمله في الحمولة.
 */
final readonly class InternalTicketAwaitsYourReply implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::user((int) ($payload['awaited_id'] ?? 0));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        return new RenderedNotification(
            title: (string) ($payload['waiting_name'] ?? 'زميلك').' ينتظر ردّك',
            body: (string) ($payload['title'] ?? ''),
            route: '/internal-tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    public function notifiesCauser(): bool
    {
        return false;
    }
}
