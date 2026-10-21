<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * Why the vendor's cost cannot be recorded on this line after «جاهزة» — OUTSOURCED-PRODUCTS.md
 * §6.2.
 *
 * **One exception, three reasons**, because the three are the same refusal seen from three
 * sides: the endpoint fills a gap that only one kind of line can have, at one point in its life,
 * once. Each says what to do instead.
 */
final class VendorCostCannotBeRecorded extends DomainException
{
    /** A line we make ourselves: its cost comes off the shelf and the rate table. */
    public static function notOutsourced(): self
    {
        return new self('تكلفة المورد تُسجَّل على بنود الوسيط فقط');
    }

    /** Not yet at «جاهزة», where the box on the move asks for it. */
    public static function notYetReady(): self
    {
        return new self('الطلبية لم تصل إلى «جاهزة» بعد — تُطلب تكلفة المورد عند الانتقال إليها');
    }

    /** Recognised once, and it already was. */
    public static function alreadyCosted(): self
    {
        return new self('سُجّلت تكلفة هذا البند من قبل، ولا تُعدَّل بعد «جاهزة»');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['unit_cost' => [$this->getMessage()]];
    }
}
