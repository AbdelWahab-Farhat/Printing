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
        $type = OperationType::from((string) $validated['type']);
        $notes = trim((string) ($validated['notes'] ?? ''));

        return new self(
            type: $type,
            amount: isset($validated['amount']) ? Money::normalize($validated['amount']) : null,
            fromAccountId: self::id($validated['from_account_id'] ?? null),
            toAccountId: self::id($validated['to_account_id'] ?? null),
            categoryId: self::id($validated['category_id'] ?? null),
            employeeId: self::id($validated['employee_id'] ?? null),
            countedBalance: isset($validated['counted_balance'])
                ? Money::normalize($validated['counted_balance'])
                : null,
            occurredAt: self::moment(trim((string) ($validated['occurred_at'] ?? '')), $type),
            notes: $notes !== '' ? $notes : null,
        );
    }

    /**
     * متى وقعت العملية — والآن إن لم تُذكر.
     *
     * **والعدُّ بيومٍ بلا ساعة يقع آخرَ ذلك اليوم.** الافتتاحُ والجرد يُعدّان عند الإقفال
     * (TREASURY-DESIGN §١١)، فجردُ «٣٠ سبتمبر» يشهد بما كان في الدرج مساءه، بحركات يومه كلِّها،
     * ويقع في السجلّ بعدها. وإن كان اليومُ هو اليوم فالآن: العدُّ لا يقع في ساعةٍ لم تأتِ.
     */
    private static function moment(string $raw, OperationType $type): Carbon
    {
        if ($raw === '') {
            return Carbon::now();
        }

        $at = Carbon::parse($raw);
        $isCount = $type === OperationType::Opening || $type === OperationType::Adjustment;

        if (! $isCount || preg_match('/^\d{4}-\d{2}-\d{2}$/', $raw) !== 1) {
            return $at;
        }

        return $at->isToday() ? Carbon::now() : $at->endOfDay();
    }

    private static function id(mixed $value): ?int
    {
        return $value === null || $value === '' ? null : (int) $value;
    }
}
