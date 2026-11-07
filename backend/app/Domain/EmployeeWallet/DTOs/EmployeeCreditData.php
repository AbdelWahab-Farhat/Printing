<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\DTOs;

use App\Domain\EmployeeWallet\Support\Money;
use Illuminate\Support\Carbon;

/** مستحقٌّ صار للموظف على الشركة: كم، وتحت أيّ تصنيف، ومتى. */
final readonly class EmployeeCreditData
{
    public function __construct(
        public string $amount,
        public int $categoryId,
        public ?Carbon $occurredAt = null,
        public ?string $notes = null,
        public ?string $clientToken = null,
        /** يكتبه النظام عن عملٍ انتهى، فوقته وقته الفعلي ولا يحرسه تاريخٌ يدوي. */
        public bool $bySystem = false,
    ) {}

    /**
     * @param  array<string, mixed>  $validated
     */
    public static function fromArray(array $validated): self
    {
        $occurredAt = trim((string) ($validated['occurred_at'] ?? ''));
        $notes = trim((string) ($validated['notes'] ?? ''));
        $token = trim((string) ($validated['client_token'] ?? ''));

        return new self(
            amount: Money::normalize($validated['amount']),
            categoryId: (int) $validated['category_id'],
            occurredAt: $occurredAt !== '' ? Carbon::parse($occurredAt) : null,
            notes: $notes !== '' ? $notes : null,
            clientToken: $token !== '' ? $token : null,
        );
    }
}
