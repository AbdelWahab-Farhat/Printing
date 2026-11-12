<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An order heading for the press — ours («قيد الطباعة») or the vendor's («قيد التصنيع») — while a
 * design ticket opened for it is still open. Its approval puts the design on the order
 * (PRINT-COLORS.md §10–§11), so printing before it closes would print the wrong file.
 */
final class OrderHasOpenDesignTicket extends DomainException
{
    /**
     * @param  list<string>  $codes
     */
    public static function make(array $codes): self
    {
        $list = implode('، ', $codes);

        return new self("تذكرة التصميم {$list} مفتوحة على هذه الطلبية — تُعتمد أو تُلغى قبل الطباعة");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['design_ticket' => [$this->getMessage()]];
    }
}
