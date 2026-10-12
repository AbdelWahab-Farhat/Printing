<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Enums;

/**
 * Where one attempt to top up stands.
 *
 * ```
 * created ──started──► pending ──paid──► succeeded (final)
 *    │                   │  ▲
 *    │ refused           │  └── a wrong OTP stays pending, until the attempts run out
 *    ▼                   ├──► failed   (declined, attempts exhausted) ──paid webhook──► succeeded
 *  failed                └──► expired  (nobody paid in time)          ──paid webhook──► succeeded
 *                        any ──amount mismatch──► needs_review (a person decides)
 * ```
 *
 * **A paid webhook is authoritative**: it may revive `failed` or `expired`. A timeout on our side
 * must never lose money that really moved.
 */
enum IntentStatus: string
{
    case Created = 'created';
    case Pending = 'pending';
    case Succeeded = 'succeeded';
    case Failed = 'failed';
    case Expired = 'expired';
    case NeedsReview = 'needs_review';

    public function label(): string
    {
        return match ($this) {
            self::Created => 'قيد البدء',
            self::Pending => 'بانتظار الدفع',
            self::Succeeded => 'تم الشحن',
            self::Failed => 'فشل',
            self::Expired => 'انتهت المهلة',
            self::NeedsReview => 'تحتاج مراجعة',
        };
    }

    /** Whether the app can stop asking — nothing will happen to it without a person. */
    public function isFinal(): bool
    {
        return $this === self::Succeeded || $this === self::NeedsReview;
    }

    /** Whether money the provider confirms may still be credited against it. */
    public function canBeSettled(): bool
    {
        return in_array($this, [self::Created, self::Pending, self::Failed, self::Expired], true);
    }
}
