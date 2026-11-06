<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\DTOs;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletMethod;
use App\Domain\EmployeeWallet\Support\Money;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;

/**
 * مالٌ دخل المحفظة أو خرج منها عبر حساب — الإيداع والسحب، كما يصفهما من في المكتب.
 *
 * `recordedBy` غائب: من الموظف المسجّل عند الباب، فلا يضع طلبٌ اسم زميلٍ على حركة.
 */
final readonly class EmployeeMoneyData
{
    public function __construct(
        /** موجبٌ دائماً، بخانتين. */
        public string $amount,
        public EmployeeWalletMethod $method,
        public ?string $reference = null,
        /** متى تحرّك المال، لا متى كُتب. */
        public ?Carbon $occurredAt = null,
        public ?string $notes = null,
        public ?UploadedFile $receipt = null,
        /** الحساب الذي اختاره الموظف، أو null لتقرّره الخزينة — TREASURY-DESIGN §٥. */
        public ?int $treasuryAccountId = null,
        public ?string $clientToken = null,
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
            method: EmployeeWalletMethod::from((string) $validated['method']),
            reference: self::textOrNull($validated['reference'] ?? null),
            occurredAt: $occurredAt !== '' ? Carbon::parse($occurredAt) : null,
            notes: self::textOrNull($validated['notes'] ?? null),
            receipt: $receipt instanceof UploadedFile ? $receipt : null,
            treasuryAccountId: $account === null || $account === '' ? null : (int) $account,
            clientToken: self::textOrNull($validated['client_token'] ?? null),
        );
    }

    private static function textOrNull(mixed $value): ?string
    {
        $text = trim((string) ($value ?? ''));

        return $text !== '' ? $text : null;
    }
}
