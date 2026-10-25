<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * أُغلقت تذكرةٌ داخلية لأن أحداً من طرفيها لم يكتب ثلاثة أيام.
 *
 * **إلى الطرفين معاً** — نشرةٌ واحدة، كتعليقات التصميم: لا فاعلَ يخرج منها، فالنظامُ هو مَن أغلق.
 * والطرفان يُحسبان ساعةَ الإغلاق ويُحملان في الحمولة.
 */
final readonly class InternalTicketClosedAfterSilence implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        $parties = is_array($payload['party_ids'] ?? null) ? $payload['party_ids'] : [];

        return NotificationAudience::users(array_values(array_map('intval', $parties)));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        return new RenderedNotification(
            title: 'أُغلقت التذكرة لعدم الردّ',
            body: (string) ($payload['title'] ?? ''),
            route: '/internal-tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    public function notifiesCauser(): bool
    {
        return false;
    }
}
