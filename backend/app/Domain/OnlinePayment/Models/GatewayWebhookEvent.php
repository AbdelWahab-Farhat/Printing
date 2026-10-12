<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * One call EzonePay made to our webhook, kept as it arrived — once, by `(gateway, event_key)`.
 *
 * **Not a business record**, like `NawrisWebhookEvent`: already an immutable record of an external
 * event, so it is neither audited nor soft-deleted (see `ModelConventionsTest`).
 *
 * @property array<string, mixed> $payload
 */
class GatewayWebhookEvent extends Model
{
    public const RECEIVED = 'received';

    public const PROCESSED = 'processed';

    public const IGNORED = 'ignored';

    public const FAILED = 'failed';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'processed_at' => 'datetime',
        ];
    }
}
