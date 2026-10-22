<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * كتب زميلُك في تذكرةٍ داخلية بينكما.
 *
 * **إلى الطرف الآخر وحده** — يحسبه المستمع ساعةَ الكتابة، فتحويلٌ لاحقٌ لا يغيّر لمن قيل. **وبلا
 * نصّ الرسالة**، كأخواتها: «🎤 رسالة صوتية» أو «صورة» حين لا كلام، وإلا عنوانُ التذكرة.
 */
final readonly class InternalTicketMessagePosted implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::user((int) ($payload['recipient_id'] ?? 0));
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $title = (string) ($payload['title'] ?? '');
        $kind = (string) ($payload['kind'] ?? 'text');

        return new RenderedNotification(
            title: (string) ($payload['author_name'] ?? 'زميل').' · '.$title,
            body: match ($kind) {
                'voice' => '🎤 رسالة صوتية',
                'image' => 'صورة',
                default => 'رسالة جديدة',
            },
            route: '/internal-tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    public function notifiesCauser(): bool
    {
        return false;
    }
}
