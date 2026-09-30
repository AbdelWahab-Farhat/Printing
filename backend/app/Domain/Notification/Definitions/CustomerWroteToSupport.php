<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * كتب عميلٌ إلى الدعم، والمحلُّ لم يقرأ بعد.
 *
 * **كانت التذكرة لا تُعرف إلا والشاشة مفتوحة** (طلب المستخدم، 2026-09-25). الدفعُ إلى هواتف
 * الموظفين قائمٌ أصلاً، فما كان ناقصاً هو هذا النوع وحده.
 *
 * **مَن على المكتب، أو كلُّ مَن يستطيع الردّ.** تذكرةٌ أخذها موظفٌ له وحده — كما تخاطب تذكرةُ
 * التصميم مَن قبلها — وتذكرةٌ في الطابور لكلّ مَن يحمل `support.manage`. لا `support.view`: مَن
 * يقرأ ولا يردّ لا يُوقَظ لأجل رسالةٍ لا يملك جوابها.
 *
 * **ونصُّ الرسالة لا يُذكر**: الدفعُ يُقرأ على شاشةٍ مقفلة، كما تقول {@see DesignTicketCommentPosted}.
 * اسمُ العميل والموضوع يكفيان ليعرف القارئ مَن ينتظره وفي أيّ شيء.
 */
final readonly class CustomerWroteToSupport implements NotificationDefinition
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        $assignee = (int) ($payload['assignee_id'] ?? 0);

        return $assignee > 0
            ? NotificationAudience::user($assignee)
            : NotificationAudience::permission(PermissionName::ManageSupportTickets);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $customer = (string) ($payload['customer_name'] ?? '');
        $subject = (string) ($payload['subject'] ?? '');

        return new RenderedNotification(
            // أولى رسائل التذكرة تذكرةٌ جديدة، وما بعدها رسالة: القارئُ يعرف من العنوان أهذه
            // محادثةٌ يعرفها أم بابٌ فُتح للتوّ.
            title: ($payload['is_opening'] ?? false) ? 'تذكرة دعم جديدة' : 'رسالة جديدة من العميل',
            body: implode(' · ', array_filter([$customer, $subject], fn (string $part) => $part !== '')),
            // إلى المحادثة نفسها، ومسارُها مسجَّلٌ في تطبيق الموظفين أصلاً.
            route: '/support/tickets/'.($payload['ticket_id'] ?? ''),
        );
    }

    /**
     * العميلُ ليس حساباً في `users`، فلا سببَ هنا يُستثنى — والسؤالُ يُجاب كما يُجاب في كل تعريفة.
     */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
