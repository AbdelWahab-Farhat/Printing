<?php

declare(strict_types=1);

namespace App\Domain\Notification\Listeners;

use App\Domain\Notification\DTOs\CustomerPush;
use App\Domain\Notification\NotificationService;
use App\Domain\OnlinePayment\Events\WalletToppedUpOnline;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * «تم شحن محفظتك» on the customer's phone, once an online payment is credited.
 *
 * **No amount on it** — the lock-screen rule every customer push follows; the app shows the
 * balance once tapped. Primula sent nothing for an online top-up, which left a customer who closed
 * the card page wondering whether the money had arrived. Queued, and after the commit.
 */
final class NotifyCustomerWhenWalletToppedUp implements ShouldQueue
{
    public bool $afterCommit = true;

    public function __construct(private readonly NotificationService $notifications) {}

    public function handle(WalletToppedUpOnline $event): void
    {
        $intent = PaymentIntent::query()->find($event->intentId);

        if ($intent === null) {
            return;
        }

        $this->notifications->pushToCustomer(new CustomerPush(
            customerId: (int) $intent->customer_id,
            title: 'تم شحن محفظتك',
            body: 'اضغط لعرض رصيدك',
            route: '/wallet',
        ));
    }
}
