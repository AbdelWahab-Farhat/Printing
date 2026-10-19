<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\DTOs\RenderedNotification;
use App\Domain\Order\Enums\OrderStatus;

/**
 * العميلُ اختار عربونَ طلبيةٍ قبلها المتجر — صاحب العمل، 2026-10-19.
 *
 * **لمن يقبل الطلبيات** (`orders.manage`)، الجمهورُ نفسه الذي أُخبر بوصولها في {@see OrderAwaitsReview}:
 * هو الذي قبلها وينتظر ما يقرّره العميل — نقداً في المكتب، فينتظر المال؛ أو مدفوعاً، فيبدأ العمل.
 */
final readonly class CustomerChoseDeposit implements NotificationDefinition
{
    /**
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
        $amount = preg_replace('/\.00$/', '', (string) ($payload['deposit_amount'] ?? ''));

        $body = ($payload['status'] ?? null) === OrderStatus::DepositPaid->value
            ? "دفع العميل عربون {$amount} د.ل من المحفظة"
            : "اختار العميل عربون {$amount} د.ل في المكتب";

        return new RenderedNotification(
            title: "عربون الطلبية {$code}",
            body: $customer !== '' ? "{$customer} · {$body}" : $body,
            route: '/orders/'.($payload['order_id'] ?? ''),
        );
    }

    /**
     * لم يسبّبه أحدٌ من الموظفين — العميلُ ليس حساباً في `users`.
     */
    public function notifiesCauser(): bool
    {
        return false;
    }
}
