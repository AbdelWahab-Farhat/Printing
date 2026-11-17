<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * «نواقص» declared on an order whose stock has already left the warehouse.
 *
 * A shortage is an order that could not be begun, and it is found while the deposit is decided,
 * the artwork agreed or the goods gathered — all before «جاهزة للطباعة» draws the stock. An order
 * sent back to «قيد التصميم» after that has its goods already; a run that came out short is the
 * press's to answer, not this status's.
 */
final class ShortageAfterStockDrawn extends DomainException
{
    public static function make(): self
    {
        return new self('خرجت بضاعة هذه الطلبية من المخزن — النواقص تُسجَّل قبل «جاهزة للطباعة»');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['fields' => [$this->getMessage()]];
    }
}
