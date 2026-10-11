<?php

declare(strict_types=1);

namespace App\Domain\Wallet\DTOs;

use App\Domain\Wallet\Enums\TopUpMethod;
use App\Domain\Wallet\Support\Money;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;

/**
 * Money a customer put in their wallet, as a person at the counter describes it.
 *
 * `recordedBy` is absent for the reason it is absent from `OrderPaymentData`: it comes from the
 * signed-in user at the boundary, so no payload can put a colleague's name on a top-up.
 */
final readonly class TopUpData
{
    public function __construct(
        /** Always positive, two places. */
        public string $amount,
        public TopUpMethod $method,
        public ?string $reference = null,
        /** When the money arrived — not when this was typed. */
        public ?Carbon $occurredAt = null,
        public ?string $notes = null,
        public ?UploadedFile $receipt = null,
        /** The account the person chose, or null to let the treasury decide — TREASURY-DESIGN §٥. */
        public ?int $treasuryAccountId = null,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $receipt = $validated['receipt'] ?? null;
        $account = $validated['treasury_account_id'] ?? null;
        $occurredAt = trim((string) ($validated['occurred_at'] ?? ''));

        return new self(
            amount: Money::normalize($validated['amount']),
            method: TopUpMethod::from((string) $validated['method']),
            reference: self::textOrNull($validated['reference'] ?? null),
            occurredAt: $occurredAt !== '' ? Carbon::parse($occurredAt) : null,
            notes: self::textOrNull($validated['notes'] ?? null),
            receipt: $receipt instanceof UploadedFile ? $receipt : null,
            treasuryAccountId: $account === null || $account === '' ? null : (int) $account,
        );
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
