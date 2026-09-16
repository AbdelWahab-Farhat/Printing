<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * There is no second unit to state, so there is nothing to state it in.
 *
 * **Three rows reach this, and each is a different misunderstanding.** A manual shortage has no
 * order line and has only ever had one unit. A size the warehouse counts the way it was sold has
 * one gap, not two — «٣٠ قطعة» is already the number that will be bought. And a row whose weight
 * somebody has already stated has converted: its requirement is in the shelf's unit now, and
 * restating it would rewrite a figure the ledger may already have been measured against.
 *
 * Refused rather than ignored, for the reason `ShortageIsNotStockable` is: the caller believes a
 * conversion is about to happen that is not.
 */
final class ShortageNeedsNoWarehouseQuantity extends DomainException
{
    public static function manual(): self
    {
        return new self('هذا النقص مكتوبٌ بخط اليد ولا يتبع بنداً — كميته بوحدةٍ واحدة');
    }

    public static function unitsAgree(string $unitLabel): self
    {
        return new self("هذا الصنف يُحسب في المخزن بـ«{$unitLabel}» نفسها — لا كمية مخزنٍ أخرى له");
    }

    public static function alreadyStated(): self
    {
        return new self('الكمية من المخزن محدَّدةٌ بالفعل — تُصحَّح من شاشة الطلبية');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['quantity' => [$this->getMessage()]];
    }
}
