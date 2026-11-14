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

    /**
     * The vendor text for this outsourced order, or null when it asks for none.
     *
     * Also null when the lines were not loaded: a list row that does not carry them must not
     * cost a query per row, and no card copies this text.
     */
    public function vendorFor(Order $order): ?string
    {
        if (! $order->vendorMessageApplies() || ! $order->relationLoaded('items')) {
            return null;
        }

        return str_replace(
            CustomerMessage::ITEMS_PLACEHOLDER,
            $this->vendorItems($order),
            $this->render(CustomerMessage::VendorRequest, $order),
        );
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
     * What the vendor makes: one bullet per line, then the inks.
     *
     * **Nothing about the customer or money.** No name, no phone, no selling price and no cost:
     * the vendor makes the goods and needs to know what, how many and in which colours — not
     * who buys them or what our margin is.
     *
     * The colours are the order's, from the design the press would print ({@see
     * Order::designForPress()}); they are read only when the designs are already loaded, so this
     * never adds a query.
     */
    private function vendorItems(Order $order): string
    {
        $lines = [];

        foreach ($order->items as $item) {
            $parts = array_filter([
                (string) $item->product_name,
                self::isolateNumbers((string) $item->variant_label),
                trim(self::isolateNumbers(self::quantity((string) $item->quantity)).' '.$item->pricing_unit?->label()),
            ], fn (string $part): bool => trim($part) !== '');

            $lines[] = '• '.implode(' — ', $parts);

            if (is_string($item->notes) && trim($item->notes) !== '') {
                $lines[] = '  ملاحظة : '.self::isolateNumbers(trim($item->notes));
            }
        }

        $colors = $order->relationLoaded('designs') ? $order->designForPress()?->print_colors : null;

        if (is_array($colors) && $colors !== []) {
            $named = array_map(
                fn (array $color): string => $color['code'] === null
                    ? $color['name']
                    : $color['name'].' ('.self::isolateNumbers($color['code']).')',
                $colors,
            );

            $lines[] = '';
            $lines[] = 'الألوان : '.implode('، ', $named);
        }

        return implode("\n", $lines);
    }

    /** `500.000` → `500`, `12.500` → `12.5`: a quantity as somebody would write it. */
    private static function quantity(string $quantity): string
    {
        return str_contains($quantity, '.') ? rtrim(rtrim($quantity, '0'), '.') : $quantity;
    }

    /**
     * Every run of digits pinned left-to-right, so «25×35» is not read as «35×25».
     *
     * Pasted into an Arabic chat, a measurement sits in a right-to-left paragraph, where Unicode
     * rule N1 turns the `×` between two numbers right-to-left and swaps them. An isolate
     * (U+2066 … U+2069) around the run stops that. A run is digits plus the characters that hold
     * a number together, and always starts and ends on a digit, so the Arabic around it keeps
     * its own order. Same rule as the client app's `bidiSafe`.
     */
    private static function isolateNumbers(string $text): string
    {
        return (string) preg_replace(
            '/[0-9\x{0660}-\x{0669}](?:[0-9\x{0660}-\x{0669}×xX*.,\/:\- ]*[0-9\x{0660}-\x{0669}])?/u',
            "\u{2066}\$0\u{2069}",
            $text,
        );
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
