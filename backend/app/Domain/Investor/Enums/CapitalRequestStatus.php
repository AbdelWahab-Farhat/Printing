<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * What has become of a queued capital request.
 *
 * Append-in-spirit: a request is never edited into a different amount. Changing your mind is
 * `Cancelled` plus a fresh request, which is how this codebase treats every money-adjacent row.
 */
enum CapitalRequestStatus: string
{
    /** Waiting for its boundary. The money is still in the investor's wallet. */
    case Pending = 'pending';

    /** It happened: a wallet row exists and this names it. */
    case Applied = 'applied';

    /** Withdrawn before it took effect. Nothing moved. */
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'بانتظار الفترة القادمة',
            self::Applied => 'نُفِّذت',
            self::Cancelled => 'أُلغيت',
        };
    }

    /** Whether it can still be cancelled — only before it has taken effect. */
    public function isCancellable(): bool
    {
        return $this === self::Pending;
    }
}
