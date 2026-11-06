<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Exceptions;

use App\Domain\EmployeeWallet\Enums\EmployeeWalletMethod;
use App\Support\Exceptions\DomainException;

final class EmployeeWalletNeedsReceipt extends DomainException
{
    public static function make(EmployeeWalletMethod $method): self
    {
        return new self("«{$method->label()}» تتطلب إرفاق الواصل");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['receipt' => [$this->getMessage()]];
    }
}
