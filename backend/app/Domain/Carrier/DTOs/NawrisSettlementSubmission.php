<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Order\Support\Money;

/**
 * ما يرسله الموظف مع «تنفيذ»: كم وصل من النورس، ولماذا أقل إن كان أقل، وأين نزل المال.
 */
final readonly class NawrisSettlementSubmission
{
    /**
     * @param  array<string, int>  $fields  حقل الحساب => الحساب المختار
     * @param  list<int>  $leftOut  طلبيات صالحة تركها الموظف لأن مالها لم يصل
     */
    public function __construct(
        public string $fileName,
        public string $clientToken,
        public string $fingerprint,
        public ?string $receivedAmount = null,
        public ?string $differenceReason = null,
        public array $fields = [],
        public array $leftOut = [],
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(string $fileName, array $data): self
    {
        $received = $data['received_amount'] ?? null;
        $reason = trim((string) ($data['difference_reason'] ?? ''));

        return new self(
            fileName: $fileName,
            clientToken: (string) $data['client_token'],
            fingerprint: (string) $data['fingerprint'],
            receivedAmount: $received === null || $received === '' ? null : Money::normalize($received),
            differenceReason: $reason === '' ? null : $reason,
            fields: array_map(
                fn (mixed $id): int => (int) $id,
                array_filter((array) ($data['fields'] ?? []), fn (mixed $id): bool => $id !== null && $id !== ''),
            ),
            leftOut: array_values(array_map(fn (mixed $id): int => (int) $id, (array) ($data['left_out'] ?? []))),
        );
    }
}
