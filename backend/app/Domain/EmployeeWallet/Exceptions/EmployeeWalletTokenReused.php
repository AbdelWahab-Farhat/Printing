<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Exceptions;

use App\Support\Exceptions\DomainException;

/** رمزٌ كتب حركةً من نوعٍ آخر: ليس إعادةً لطلبٍ سابق، بل طلبٌ آخر بمفتاحٍ مستعمل. */
final class EmployeeWalletTokenReused extends DomainException
{
    public static function make(): self
    {
        return new self('هذا الرمز استُعمل لحركةٍ أخرى على هذه المحفظة');
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['client_token' => [$this->getMessage()]];
    }
}
