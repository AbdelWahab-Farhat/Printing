<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * An order for our press with no artwork on it, and nobody asked to draw one.
 *
 * Print colours are mandatory on a print order (PRINT-COLORS.md §9), and colours live on a
 * design, so the order needs one. The exception is an in-house design: it does not exist yet,
 * and the colours are asked for on the design ticket opened from the order instead.
 */
final class PrintOrderNeedsADesign extends DomainException
{
    public static function make(): self
    {
        return new self('طلبية الطباعة تحتاج تصميماً بألوانه — اختر التصميم من مكتبة العميل، أو اجعلها «تصميم من عندنا»');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['design_ids' => [$this->getMessage()]];
    }
}
