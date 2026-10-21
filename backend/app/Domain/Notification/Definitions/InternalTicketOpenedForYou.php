<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * زميلٌ فتح تذكرةً داخلية إليك.
 *
 * **إلى من وُجّهت وحده**، كبريمولا. **ونصُّ التفاصيل لا يُذكر**: الدفعُ يُقرأ على شاشةٍ مقفلة، كما
 * تقول {@see DesignTicketCommentPosted} — اسمُ الزميل والعنوانُ يكفيان ليعرف القارئ مَن ينتظره وفي
 * أيّ شيء.
 */
final readonly class InternalTicketOpenedForYou implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::user((int) ($payload['assignee_id'] ?? 0));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        return new RenderedNotification(
            title: 'تذكرة جديدة من '.(string) ($payload['opener_name'] ?? 'زميل'),
            body: (string) ($payload['title'] ?? ''),
            route: '/internal-tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    public function notifiesCauser(): bool
    {
        return false;
    }
}
