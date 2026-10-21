<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A وسيط order cannot be called ready while any of its lines still has no vendor cost.
 *
 * **The cost-side twin of {@see OrderLinesNeedAPrice}.** «جاهزة» is where a وسيط line's cost is
 * recognised — `unit_cost × billable quantity`, see `ApplyOutsourcingCosts` — and a line reaching
 * it with no `unit_cost` is recognised as nothing: its `cogs` stays null and the order's «مجمل
 * الربح» with it, for good, because nothing costs an order a second time. That is the state four
 * in five «حسب الطلب» jobs were left in before the figure could be typed. See
 * OUTSOURCED-PRODUCTS.md §6.1.
 *
 * The lines are named rather than counted, for the reason the price refusal names them.
 */
final class OutsourcedLinesNeedACost extends DomainException
{
    /**
     * @param  list<string>  $lines
     */
    public static function make(array $lines): self
    {
        return new self(
            'لا يمكن اعتبار الطلبية جاهزة قبل تحديد تكلفة المورد لكل سطر — تنقص تكلفة: '.implode('، ', $lines),
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['items' => [$this->getMessage()]];
    }
}
