<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\DTOs;

/**
 * What one salary run did — EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * `status` is `off` (the switch is off), `not_yet` (the first 1st after switching on has not
 * come), or `ran`. On a dry run, `posted` lists who would be paid and nothing is written.
 */
final readonly class SalaryRunResult
{
    public const OFF = 'off';

    public const NOT_YET = 'not_yet';

    public const RAN = 'ran';

    /**
     * @param  array<int, string>  $posted  user id => amount
     * @param  list<int>  $skippedManual  user ids whose salary was already entered by hand this month
     */
    public function __construct(
        public string $status,
        public ?string $monthKey = null,
        public ?string $monthLabel = null,
        public array $posted = [],
        public array $skippedManual = [],
    ) {}

    public function total(): string
    {
        return array_reduce($this->posted, fn (string $sum, string $amount) => bcadd($sum, $amount, 2), '0.00');
    }
}
