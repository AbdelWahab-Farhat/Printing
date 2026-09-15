<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * A design ticket moved, and the other side of the conversation has not heard yet.
 *
 * **One definition for five moves**, exactly as {@see OrderReachedStatus} is one for fifteen
 * statuses: acceptance, a submission, a change request, a revised version and an approval share a
 * subject, a route and a shape of sentence, and the status rides in the payload. Five types would
 * have meant five classes doing one lookup each.
 *
 * **The audience is the other party, and which party that is depends on the status.** That is the
 * whole content of this class:
 *
 * - accepted, submitted → the employee who raised it, who is now the one being waited on;
 * - changes requested → the designer, whose turn it is again;
 * - approved → the designer, because the work being signed off is the news they have been
 *   waiting for. The reviewer already knows: they are the one who approved it;
 * - cancelled → the designer, so a job that vanished overnight does not simply vanish.
 *
 * **An audience of one throughout, never a permission.** A ticket is a conversation between two
 * named people, and broadcasting each step to everybody holding `design_tickets.view` would teach
 * the whole shop to scroll past the bell — the argument `orders.ready_message` makes for its own
 * grant, and the one `ShortageAssignedToYou` makes for its audience.
 */
final readonly class DesignTicketReachedStatus implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        $status = DesignTicketStatus::tryFrom((string) ($payload['status'] ?? ''));

        $recipientId = match ($status) {
            DesignTicketStatus::InProgress,
            DesignTicketStatus::UnderReview => $payload['requester_id'] ?? null,
            default => $payload['designer_id'] ?? null,
        };

        // Nobody to tell — an unattributed ticket, or a designer whose account has since gone.
        // `user(0)` resolves to no recipients, which is the honest outcome: the notification is
        // published and reaches nobody, rather than being broadcast to whoever happens to fit.
        return NotificationAudience::user((int) ($recipientId ?? 0));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $status = DesignTicketStatus::tryFrom((string) ($payload['status'] ?? ''));
        $title = (string) ($payload['title'] ?? '');
        $code = (string) ($payload['code'] ?? '');

        return new RenderedNotification(
            title: match ($status) {
                DesignTicketStatus::InProgress => 'بدأ العمل على طلب التصميم',
                DesignTicketStatus::UnderReview => 'وصل تصميم للمراجعة',
                DesignTicketStatus::ChangesRequested => 'مطلوب تعديل على التصميم',
                DesignTicketStatus::Completed => 'تم اعتماد التصميم',
                DesignTicketStatus::Cancelled => 'أُلغيت تذكرة التصميم',
                default => 'تحديث على طلب التصميم',
            },
            body: $title !== '' ? $title : "تذكرة {$code}",
            route: '/design-tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    /**
     * The person who moved it watched it move.
     *
     * Load-bearing here rather than merely tidy: an approval's audience is the designer, and the
     * designer is refused the review — so the only way the causer could also be the recipient is
     * a rule this system does not allow. It stays `false` for the ordinary reason anyway.
     */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
