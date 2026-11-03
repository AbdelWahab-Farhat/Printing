<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * The inks are a record of what was printed once the press has started.
 *
 * The same line {@see OrderDesignsAreLocked} draws for the file, and the same way back: send the
 * order to «قيد التصميم», which the timeline records. Its own class only so the sentence names
 * the colors and the error lands under `print_colors` on the form that sent them.
 */
final class OrderDesignColorsAreLocked extends DomainException
{
    public static function make(OrderStatus $status): self
    {
        return new self(
            'تعديل ألوان الطباعة متاح قبل «قيد الطباعة» — '
            ."والطلبية الآن «{$status->label()}»، وتعديلها يبدأ بإرجاعها إلى «قيد التصميم»",
        );
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['print_colors' => [$this->getMessage()]];
    }
}
