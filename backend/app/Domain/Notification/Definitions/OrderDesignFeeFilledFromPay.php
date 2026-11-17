<?php

declare(strict_types=1);

namespace App\Domain\Notification\Definitions;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Notification\Audience\NotificationAudience;
use App\Domain\Notification\Contracts\GroupNotification;
use App\Domain\Notification\Contracts\NotificationDefinition;
use App\Domain\Notification\Definitions\Concerns\OneSwitch;
use App\Domain\Notification\DTOs\RenderedNotification;

/**
 * «أجرة التصميم» on an order was filled from «أجرة المصمم» because nobody had set it
 * (ORDER-DESIGN-FEE.md). Told to whoever may see the fee, so they can set the real price.
 */
final readonly class OrderDesignFeeFilledFromPay implements GroupNotification, NotificationDefinition
{
    use OneSwitch;

    public function groupPermission(): PermissionName
    {
        return PermissionName::SetOrderDesignFee;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function audience(array $payload): NotificationAudience
    {
        return NotificationAudience::permission($this->groupPermission());
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function render(array $payload): RenderedNotification
    {
        $code = (string) ($payload['order_code'] ?? '');
        $amount = preg_replace('/\.00$/', '', (string) ($payload['amount'] ?? ''));

        return new RenderedNotification(
            title: "أجرة التصميم على {$code}",
            body: "صارت {$amount} د.ل من أجرة المصمم — حدّدها إن أردت غيرها",
            route: '/orders/'.($payload['order_id'] ?? ''),
        );
    }

    /**
     * The approver approved a design, not a price: they are told like everybody else.
     */
    public function notifiesCauser(): bool
    {
        return true;
    }
}
