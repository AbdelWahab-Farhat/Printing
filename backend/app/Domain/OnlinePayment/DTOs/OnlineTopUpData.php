<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\DTOs;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Support\Money;

/**
 * A customer asking to put `net` in their wallet through one method.
 */
final readonly class OnlineTopUpData
{
    public function __construct(
        public OnlineMethod $method,
        /** What the wallet should receive — the customer's number, two places. */
        public string $net,
        /** «اشحن وادفع»: the order paid from the wallet once it is topped up. */
        public ?int $orderId = null,
        public ?string $cardNumber = null,
        public ?string $serviceMobileNumber = null,
        public ?string $birthYear = null,
        public ?string $qrContent = null,
        public ?string $clientToken = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        return new self(
            method: OnlineMethod::from((int) $validated['method']),
            net: Money::normalize($validated['amount']),
            orderId: isset($validated['order_id']) ? (int) $validated['order_id'] : null,
            cardNumber: self::text($validated['card_number'] ?? null),
            serviceMobileNumber: self::text($validated['service_mobile_number'] ?? null),
            birthYear: self::text($validated['birth_year'] ?? null),
            qrContent: self::text($validated['qr_content'] ?? null),
            clientToken: self::text($validated['client_token'] ?? null),
        );
    }

    private static function text(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text === '' ? null : $text;
    }
}
