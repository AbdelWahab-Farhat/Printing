<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An order heading for the warehouse («بانتظار التجهيز») or the press — ours («قيد الطباعة») or the
 * vendor's («قيد التصنيع») — while a design ticket opened for it is still open. Its approval puts
 * the design on the order (PRINT-COLORS.md §10–§11), so going on before it closes would prepare
 * and print the wrong file.
 */
final class OrderHasOpenDesignTicket extends DomainException
{
    /**
     * @param  list<string>  $codes
     * @param  string  $before  The step it blocks, as the sentence ends: «الطباعة» or «التجهيز».
     */
    public static function make(array $codes, string $before = 'الطباعة'): self
    {
        $list = implode('، ', $codes);

        return new self("تذكرة التصميم {$list} مفتوحة على هذه الطلبية — تُعتمد أو تُلغى قبل {$before}");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['design_ticket' => [$this->getMessage()]];
    }
}
