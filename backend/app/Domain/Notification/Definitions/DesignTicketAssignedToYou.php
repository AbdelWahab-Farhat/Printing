<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * There is artwork to draw.
 *
 * **The first definition whose audience is a single person *or* a whole permission**, decided
 * from the payload. A ticket addressed to a named designer is that designer's news; one left in
 * the shared pool is news for everybody who could take it, and telling nobody would leave it
 * sitting there until somebody happened to scroll past.
 *
 * That the two share a type rather than splitting into two is the same judgement
 * {@see OrderReachedStatus} makes for fifteen statuses: they are the same sentence, going to the
 * same screen, about the same thing. Only the size of the audience differs, and
 * {@see NotificationAudience} already carries that distinction as data.
 */
final readonly class DesignTicketAssignedToYou implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        $designerId = $payload['designer_id'] ?? null;

        // Null is the shared pool, not missing data — see `DesignTicketAssigned`.
        return $designerId === null
            ? NotificationAudience::permission(PermissionName::AcceptDesignTickets)
            : NotificationAudience::user((int) $designerId);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $title = (string) ($payload['title'] ?? '');
        $customer = (string) ($payload['customer_name'] ?? '');
        $isPool = ($payload['designer_id'] ?? null) === null;

        return new RenderedNotification(
            title: $isPool ? 'طلب تصميم جديد' : 'طلب تصميم مُسنَد إليك',
            // What is wanted and for whom — the two things that decide whether this is worth
            // opening now. The brief itself is on the screen the route opens, and putting it here
            // would push the customer's name off a lock screen.
            body: trim($title.' — '.$customer, ' —') !== ''
                ? trim($title.' — '.$customer, ' —')
                : 'تذكرة '.(string) ($payload['code'] ?? ''),
            route: '/design-tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    /**
     * Somebody who raised a ticket and addressed it to themselves watched it happen on their own
     * screen.
     */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
