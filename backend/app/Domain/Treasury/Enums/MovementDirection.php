<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Enums;

enum MovementDirection: string
{
    case In = 'in';
    case Out = 'out';

    public function label(): string
    {
        return match ($this) {
            self::In => 'داخل',
            self::Out => 'خارج',
        };
    }

    public function opposite(): self
    {
        return $this === self::In ? self::Out : self::In;
    }

    /** +1 or −1 — what a balance multiplies the amount by. */
    public function sign(): int
    {
        return $this === self::In ? 1 : -1;
    }
}
