<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Exceptions;

use App\Domain\Wallet\Enums\TopUpMethod;
use App\Support\Exceptions\DomainException;

/** A top-up by transfer with no receipt — the order payments' rule, for the same reason. */
final class TopUpNeedsReceipt extends DomainException
{
    public static function make(TopUpMethod $method): self
    {
        return new self("الشحن بـ«{$method->label()}» يتطلب إرفاق الواصل");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['receipt' => [$this->getMessage()]];
    }
}
