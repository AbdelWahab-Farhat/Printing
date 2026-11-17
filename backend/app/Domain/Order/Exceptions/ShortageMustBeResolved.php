<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Sending an order to the warehouse, or on to the press, while something is still missing from it.
 *
 * **«تجهيز للطباعة» and «جاهزة للطباعة» are promises to other departments**: the goods are all
 * here to be gathered, and then they have been weighed and the press can start. An order that
 * still carries a shortage on any line has made neither true — the warehouse would gather half
 * an order and the press would set up for a run it cannot finish.
 *
 * The way through is not this button. The move into «تجهيز» asks «كم وصل من كل بند؟» and subtracts
 * what arrived, so an order whose stock has actually turned up answers that form and passes here
 * on the same move — see `ChangeOrderStatus::recordArrivedShortages()`. The
 * message names what is still short rather than saying «غير مكتملة», because the person reading it
 * is standing in front of the shelves and needs to know which size to go and find.
 */
final class ShortageMustBeResolved extends DomainException
{
    /**
     * @param  list<string>  $stillShort  The labels of the sizes that have not arrived.
     */
    public static function make(array $stillShort): self
    {
        return new self(
            'لا يمكن تجهيز الطلبية للطباعة وبها نواقص — ما زال ناقصاً: '.implode('، ', $stillShort)
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['fields' => [$this->getMessage()]];
    }
}
