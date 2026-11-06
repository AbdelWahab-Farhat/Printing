<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Exceptions;

use App\Support\Exceptions\DomainException;

/**
 * أكثر مما تحمله المحفظة. لا طريق يكتب فيها دَيناً — السلفة تبقى مصروفاً — فهذا ما يلقاه كلُّ خصمٍ
 * تحت قفل الموظف.
 */
final class EmployeeWalletBalanceTooLow extends DomainException
{
    public static function make(string $amount, string $balance): self
    {
        return new self("رصيد المحفظة ({$balance}) أقل من المبلغ المطلوب ({$amount})");
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return ['amount' => [$this->getMessage()]];
    }
}
