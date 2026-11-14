<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Order\Enums\CustomerMessage;
use App\Domain\Order\Models\Order;
use App\Domain\Settings\SettingsService;

/**
 * The customer messages as the admin worded them, written out for one order.
 *
 * **The server writes the text, the app only copies it.** The ready texts used to be built in
 * Dart; once the admin can change them, a phone holding its own copy would keep sending the old
 * words until it was updated. One writer means every phone copies what the settings say today.
 *
 * **Read once per request.** `OrderResource` asks for a text on every row of a page, and the
 * settings row is the same for all of them, so it is read on the first ask and held. Bound
 * `scoped` in AppServiceProvider, so a queue worker never carries an old wording into the next
 * job; {@see forget()} drops it after a save inside the same request.
 */
final class CustomerMessageTexts
{
    /** @var array<string, string>|null */
    private ?array $templates = null;

    public function __construct(private readonly SettingsService $settings) {}

    /** The ready text for this order, or null before it has been dispatched. */
    public function readyFor(Order $order): ?string
    {
        if (! $order->readyMessageApplies()) {
            return null;
        }

        return $this->render(CustomerMessage::forReady($order->fulfilment_type), $order);
    }

    /** The return text for the return this order is in, or null when it is in none. */
    public function returnFor(Order $order): ?string
    {
        $message = CustomerMessage::forReturn($order->status);

        return $message === null ? null : $this->render($message, $order);
    }

    /** The wording in force — the admin's when set, the built-in one otherwise. */
    public function template(CustomerMessage $message): string
    {
        return $this->templates()[$message->value];
    }

    /** Whether the admin has replaced the built-in wording. */
    public function isCustomised(CustomerMessage $message): bool
    {
        return $this->templates()[$message->value] !== $message->defaultBody();
    }

    public function forget(): void
    {
        $this->templates = null;
    }

    private function render(CustomerMessage $message, Order $order): string
    {
        return str_replace(CustomerMessage::INVOICE_PLACEHOLDER, (string) $order->code, $this->template($message));
    }

    /**
     * @return array<string, string>
     */
    private function templates(): array
    {
        if ($this->templates !== null) {
            return $this->templates;
        }

        $row = $this->settings->current();
        $templates = [];

        foreach (CustomerMessage::cases() as $message) {
            $typed = $row->getAttribute($message->settingColumn());

            $templates[$message->value] = is_string($typed) && trim($typed) !== ''
                ? $typed
                : $message->defaultBody();
        }

        return $this->templates = $templates;
    }
}
