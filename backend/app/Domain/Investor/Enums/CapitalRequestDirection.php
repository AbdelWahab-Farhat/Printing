<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * Which way queued capital is travelling.
 *
 * A word rather than a sign, exactly as {@see WalletEntryType} carries direction: the amount on the
 * row is always positive and this says what it means. {@see walletType()} is the one place each
 * direction is mapped to the ledger row it eventually becomes, so the two cannot drift.
 */
enum CapitalRequestDirection: string
{
    /** Into the pool — becomes an `allocation` when the period it joins opens. */
    case In = 'in';

    /** Out of the pool and back to the wallet — becomes a `release` at the close. */
    case Out = 'out';

    public function label(): string
    {
        return match ($this) {
            self::In => 'إدخال رأس مال',
            self::Out => 'سحب رأس مال من الصندوق',
        };
    }

    /** The ledger row this request turns into. One mapping, one place. */
    public function walletType(): WalletEntryType
    {
        return match ($this) {
            self::In => WalletEntryType::Allocation,
            self::Out => WalletEntryType::Release,
        };
    }

    /**
     * Whether this direction takes effect when a period **opens** rather than when one closes.
     *
     * Money in joins at the start of the period it will earn through. Money out leaves at the
     * close, **after** that period's profit has been distributed — so a man who asks to leave in
     * September is still paid his September share.
     */
    public function appliesAtPeriodOpen(): bool
    {
        return $this === self::In;
    }
}
