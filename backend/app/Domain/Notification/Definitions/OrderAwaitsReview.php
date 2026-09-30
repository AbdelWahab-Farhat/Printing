<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * طلبيةٌ وصلت من تطبيق العميل، وتنتظر مَن يراجعها.
 *
 * **كانت صامتةً عمداً ثم شُغّلت** (طلب المستخدم، 2026-09-25). الحجّةُ القديمة — «الجرسُ لعملٍ في
 * منتصفه، ولا أحد في منتصف طلب» — صحيحةٌ عن رفضه وعن التراجع عن رفضه، وهما حركتا المراجِع على
 * شاشته فبقيتا صامتتين. أما وصولُه فخبرٌ لمن لم يرَه: عميلٌ طلب في الثانية ليلاً ينتظر حتى يفتح
 * أحدُهم لوحة الرئيسية ويرى الرقم.
 */
final readonly class OrderAwaitsReview implements NotificationDefinition
{
    /**
     * مَن يستطيع قبولها أو رفضها — `orders.manage`، الصلاحيةُ نفسها التي يكلّفها الأمران.
     *
     * **لا `orders.view`** كما يفعل {@see OrderReachedStatus}: ذاك خبرٌ عن طلبيةٍ تتحرّك يهمّ كلَّ
     * مَن يقرأ الطلبيات، وهذا عملٌ وصل، ومَن لا يستطيع أن يقبله لا يُوقَظ لأجله.
     *
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::permission(PermissionName::ManageOrders);
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $code = (string) ($payload['order_code'] ?? '');
        $customer = (string) ($payload['customer_name'] ?? '');

        return new RenderedNotification(
            title: "طلبية جديدة من التطبيق — {$code}",
            // مَن طلب أولاً: هو ما يقول للقارئ أهذه الطلبيةُ التي ينتظرها. وما تنتظره ثانياً،
            // لأن «من التطبيق» في العنوان لا تقول إن أحداً لم يقبلها بعد.
            body: $customer !== '' ? "العميل: {$customer} · بانتظار المراجعة" : 'بانتظار المراجعة',
            route: '/orders/'.($payload['order_id'] ?? ''),
        );
    }

    /**
     * لم يسبّبها أحدٌ من الموظفين أصلاً — العميلُ ليس حساباً في `users` — فالسؤالُ لا يُغيّر شيئاً
     * هنا، ويُجاب كما يُجاب في كل تعريفة.
     */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
