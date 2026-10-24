<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\DTOs;

use Illuminate\Http\UploadedFile;

/**
 * What an employee asked for, on the way in.
 *
 * The customer is an id rather than a model: resolving it is the Customer context's job, and the
 * creating action asks `CustomerService` for it so that a ticket can never be opened against a
 * customer this context invented. The snapshot of the name is taken there too, from the resolved
 * row — never from the request, where it would be a claim.
 *
 * `assignedDesignerId` being null is «الطابور المشترك» and not missing data; see the column's own
 * comment on the migration.
 *
 * `files` مرفقاتُ الطلب مع إنشائه، بالترتيب الذي اختيرت به — تُحفظ «مرفقاتٍ» (brief) كالتي تُرفق
 * من شاشة التذكرة بعدها.
 */
final readonly class DesignTicketData
{
    /**
     * @param  list<UploadedFile>  $files
     */
    public function __construct(
        public int $customerId,
        public string $title,
        public string $description,
        public ?string $instructions = null,
        public ?int $orderId = null,
        public ?int $assignedDesignerId = null,
        public array $files = [],
    ) {}

    /**
     * @param  array<string, mixed>  $data  already-validated request data
     * @param  list<UploadedFile>  $files  بالترتيب الذي اختيرت به
     */
    public static function fromArray(array $data, array $files = []): self
    {
        return new self(
            customerId: (int) $data['customer_id'],
            title: trim((string) $data['title']),
            description: trim((string) $data['description']),
            instructions: self::textOrNull($data['instructions'] ?? null),
            orderId: isset($data['order_id']) && $data['order_id'] !== ''
                ? (int) $data['order_id']
                : null,
            assignedDesignerId: isset($data['assigned_designer_id']) && $data['assigned_designer_id'] !== ''
                ? (int) $data['assigned_designer_id']
                : null,
            files: $files,
        );
    }

    /**
     * Blank is not a value. A cleared textarea arrives as an empty string, and storing that would
     * make «لا توجد تعليمات» and «التعليمات فارغة» two different-looking states that read
     * identically on screen.
     */
    private static function textOrNull(mixed $value): ?string
    {
        $text = $value === null ? '' : trim((string) $value);

        return $text !== '' ? $text : null;
    }
}
