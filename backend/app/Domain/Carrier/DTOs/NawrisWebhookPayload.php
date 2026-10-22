<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Carrier\Enums\NawrisStatusCode;

/**
 * One inbound webhook body, read defensively.
 *
 * **Nine fields are meaningful and only one drives state.** Everything is optional, because the
 * contract says so and because a payload we refuse to parse is a delivery we never hear about: an
 * unmatched or unreadable event still gets stored, still gets a row, and can still be replayed.
 *
 * `order_price` **arrives as a string in practice**, so it is normalised here rather than in the
 * comparison — a numeric comparison decided by PHP's string rules is a coin toss on money.
 *
 * **`changes` rides only on `shipment.updated`**, their edit event, and is the one place two facts
 * appear: the door amount *before* the edit, and `shipment_on_sender`. Its `old` arrives as a
 * number and its `new` as text (`{"old": 1, "new": "2"}`), so both are normalised the same way.
 */
final readonly class NawrisWebhookPayload
{
    /**
     * @param  array<string, mixed>  $raw
     */
    public function __construct(
        public array $raw,
        public ?string $reference,
        public ?string $code,
        public ?int $statusCode,
        public ?string $statusText,
        public ?string $collectedAmount,
        public ?string $returnReason,
        public ?string $delayReason,
        public ?string $captainName,
        public ?string $captainPhone,
        public ?string $collectedAmountBefore = null,
        public ?int $shipmentOnSenderBefore = null,
        public ?int $shipmentOnSenderAfter = null,
        public bool $cityChanged = false,
    ) {}

    /**
     * @param  array<string, mixed>  $body
     */
    public static function fromArray(array $body): self
    {
        $amountChange = self::change($body, 'amount_to_be_collected');
        $senderChange = self::change($body, 'shipment_on_sender');
        $cityChange = self::change($body, 'government_id');

        return new self(
            raw: $body,
            reference: self::text($body['remote_order_id'] ?? null),
            code: self::text($body['order_code'] ?? null),
            statusCode: isset($body['to_status_code']) && is_numeric($body['to_status_code'])
                ? (int) $body['to_status_code']
                : null,
            statusText: self::text($body['to_status_text'] ?? null),
            collectedAmount: self::money($body['order_price'] ?? null),
            returnReason: self::text($body['return_reason'] ?? null),
            delayReason: self::text($body['delay_reason'] ?? null),
            captainName: self::text($body['captain_name'] ?? null),
            captainPhone: self::text($body['captain_phone'] ?? null),
            collectedAmountBefore: self::money($amountChange['old'] ?? null),
            shipmentOnSenderBefore: self::integer($senderChange['old'] ?? null),
            shipmentOnSenderAfter: self::integer($senderChange['new'] ?? null),
            cityChanged: self::cityMoved($cityChange),
        );
    }

    public function status(): ?NawrisStatusCode
    {
        return NawrisStatusCode::tryFromCode($this->statusCode);
    }

    /**
     * A stable hash of the fields that make this event *this* event.
     *
     * **The raw body is deliberately not hashed.** Their payload may carry a timestamp or a field
     * we do not read, and any of those would make every duplicate look distinct — which is exactly
     * the failure this is meant to prevent. Hashing the meaningful fields means a genuine re-send
     * of the same news collides, as it should.
     *
     * **`changes` joins the hash only when it is there**, so every event without one keeps the
     * fingerprint it always had. An edit that flips who pays the fee while leaving the status and
     * the door amount where an earlier event put them would otherwise be thrown away as a
     * duplicate — and the payment on delivery depends on that flip.
     */
    public function fingerprint(): string
    {
        $fields = [
            $this->reference ?? '',
            $this->code ?? '',
            (string) ($this->statusCode ?? ''),
            $this->collectedAmount ?? '',
            $this->returnReason ?? '',
        ];

        if (is_array($this->raw['changes'] ?? null) && $this->raw['changes'] !== []) {
            $fields[] = (string) json_encode($this->raw['changes']);
        }

        return hash('sha256', implode('|', $fields));
    }

    private static function text(mixed $value): ?string
    {
        if ($value === null || is_array($value)) {
            return null;
        }

        $text = trim((string) $value);

        return $text !== '' ? $text : null;
    }

    /** Normalised to a decimal string, so nothing downstream compares money as text. */
    private static function money(mixed $value): ?string
    {
        if ($value === null || $value === '' || ! is_numeric($value)) {
            return null;
        }

        return number_format((float) $value, 2, '.', '');
    }

    /**
     * Whether an edit moved the parcel to another city.
     *
     * **By name when the names are there.** Their ids for one city get re-mapped — event 378 went
     * 4 → 232 and stayed «طرابلس» both sides — and a fee is the city's, not the id's. Without
     * names, different ids are read as a move: a fee wrongly kept costs money, one wrongly dropped
     * costs a person a minute.
     *
     * @param  array<string, mixed>  $change
     */
    private static function cityMoved(array $change): bool
    {
        if ($change === []) {
            return false;
        }

        $oldName = self::text($change['old_name'] ?? null);
        $newName = self::text($change['new_name'] ?? null);

        if ($oldName !== null && $newName !== null) {
            return $oldName !== $newName;
        }

        return self::text($change['old'] ?? null) !== self::text($change['new'] ?? null);
    }

    private static function integer(mixed $value): ?int
    {
        return is_numeric($value) ? (int) $value : null;
    }

    /**
     * One entry of `changes` as `{old, new}`, or an empty array when that field did not move.
     *
     * @param  array<string, mixed>  $body
     * @return array<string, mixed>
     */
    private static function change(array $body, string $field): array
    {
        $changes = $body['changes'] ?? null;
        $change = is_array($changes) ? ($changes[$field] ?? null) : null;

        return is_array($change) ? $change : [];
    }
}
