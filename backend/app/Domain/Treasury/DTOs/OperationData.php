<?php

declare(strict_types=1);

namespace App\Domain\Treasury\DTOs;

use App\Domain\Treasury\Enums\OperationType;
use App\Domain\Treasury\Support\Money;
use Illuminate\Support\Carbon;

/**
 * What the treasury screen sends for a hand operation.
 *
 * `amount` is absent for «جرد الحساب»: a count names the balance found, and the difference is
 * worked out under the lock — `countedBalance` carries it.
 */
final readonly class OperationData
{
    public function __construct(
        public OperationType $type,
        public ?string $amount,
        public ?int $fromAccountId,
        public ?int $toAccountId,
        public ?int $categoryId,
        public ?int $employeeId,
        public ?string $countedBalance,
        public Carbon $occurredAt,
        public ?string $notes,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $occurred = trim((string) ($validated['occurred_at'] ?? ''));
        $notes = trim((string) ($validated['notes'] ?? ''));

        return new self(
            type: OperationType::from((string) $validated['type']),
            amount: isset($validated['amount']) ? Money::normalize($validated['amount']) : null,
            fromAccountId: self::id($validated['from_account_id'] ?? null),
            toAccountId: self::id($validated['to_account_id'] ?? null),
            categoryId: self::id($validated['category_id'] ?? null),
            employeeId: self::id($validated['employee_id'] ?? null),
            countedBalance: isset($validated['counted_balance'])
                ? Money::normalize($validated['counted_balance'])
                : null,
            occurredAt: $occurred !== '' ? Carbon::parse($occurred) : Carbon::now(),
            notes: $notes !== '' ? $notes : null,
        );
    }

    private static function id(mixed $value): ?int
    {
        return $value === null || $value === '' ? null : (int) $value;
    }
}
