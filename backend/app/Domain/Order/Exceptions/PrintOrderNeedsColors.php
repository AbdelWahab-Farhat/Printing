<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * A design on a print order whose colours are missing or incomplete: none at all, or one named
 * without its swatch or press code. See PRINT-COLORS.md §9.
 *
 * [$designId] is the library design, so the app can point at the tile that needs them.
 */
final class PrintOrderNeedsColors extends DomainException
{
    public function __construct(string $message, public readonly ?int $designId = null)
    {
        parent::__construct($message);
    }

    /** Refused while the order is being taken or accepted. */
    public static function forDesign(?string $label, ?int $designId): self
    {
        return new self(
            'حدّد ألوان الطباعة لـ'.self::name($label).' — كل لون بعيّنته، ولا تُنشأ طلبية طباعة دونها',
            $designId,
        );
    }

    /** Refused on the move into «قيد الطباعة». */
    public static function atThePress(?string $label, ?int $designId): self
    {
        return new self(
            'حدّد ألوان الطباعة لـ'.self::name($label).' — كل لون بعيّنته — قبل الانتقال إلى «قيد الطباعة»',
            $designId,
        );
    }

    private static function name(?string $label): string
    {
        return $label !== null && trim($label) !== '' ? "«{$label}»" : 'التصميم';
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['print_colors' => [$this->getMessage()]];
    }
}
