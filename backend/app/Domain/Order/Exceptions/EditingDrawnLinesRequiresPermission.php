<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Changing the lines after the stock has left takes the grant that took it out.
 *
 * **An edit there is a stock movement**, not just a change to an invoice: a removed line goes
 * back on the shelf and an added one comes off it. So it asks the grant for moving an order into
 * «جاهزة للطباعة» — the person allowed to take goods off the shelf for an order — on top of
 * `orders.manage`. Only a change to the lines is guarded; the rest of the order edits as before.
 */
final class EditingDrawnLinesRequiresPermission extends DomainException
{
    public static function make(): self
    {
        return new self(
            'خرجت بضاعة هذه الطلبية من المخزن، وتعديل بنودها يحرّك المخزن —'
            .' يحتاج صلاحية نقل الطلبية إلى «جاهزة للطباعة»'
        );
    }

    public function httpStatus(): int
    {
        return 403;
    }
}
