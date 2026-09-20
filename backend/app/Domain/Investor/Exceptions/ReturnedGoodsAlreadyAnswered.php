<?php

declare(strict_types=1);

namespace App\Domain\Investor\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A verdict is given once.
 *
 * «تالفة» posts a real stock adjustment: the goods leave the shelf and the pool's cost falls by
 * their value. Answering again would either post it twice or ask somebody to unwind a movement the
 * shelf has already been counted against — and a stocktake correction is a deliberate act with its
 * own screen, not the side effect of changing one's mind about a prompt.
 */
final class ReturnedGoodsAlreadyAnswered extends DomainException
{
    public static function make(string $verdict): self
    {
        return new self("هذه البضاعة فُحصت بالفعل: «{$verdict}»");
    }
}
