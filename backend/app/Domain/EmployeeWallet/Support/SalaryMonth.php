<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Support;

use Carbon\CarbonImmutable;

/**
 * The months of the automatic salary run — EMPLOYEE-WALLET-DESIGN §١٤.
 *
 * The run on the 1st pays the month just worked: 1 Dec pays «راتب نوفمبر». Every date here is in
 * the shop's time zone, because "the 1st" is the 1st in Tripoli, not in UTC.
 */
final class SalaryMonth
{
    private const NAMES = [
        1 => 'يناير', 2 => 'فبراير', 3 => 'مارس', 4 => 'أبريل', 5 => 'مايو', 6 => 'يونيو',
        7 => 'يوليو', 8 => 'أغسطس', 9 => 'سبتمبر', 10 => 'أكتوبر', 11 => 'نوفمبر', 12 => 'ديسمبر',
    ];

    /** The 1st of the month `$now` falls in, at midnight in the shop's time zone. */
    public static function postingMonth(CarbonImmutable $now): CarbonImmutable
    {
        return $now->setTimezone(self::zone())->startOfMonth();
    }

    /** The month worked, paid on `$postingMonth`'s 1st. */
    public static function workMonth(CarbonImmutable $postingMonth): CarbonImmutable
    {
        return $postingMonth->subMonthNoOverflow();
    }

    /** `2026-11` — the key in the salary's client token. */
    public static function key(CarbonImmutable $workMonth): string
    {
        return $workMonth->format('Y-m');
    }

    /** «نوفمبر 2026». */
    public static function label(CarbonImmutable $workMonth): string
    {
        return self::NAMES[(int) $workMonth->month].' '.$workMonth->year;
    }

    private static function zone(): string
    {
        return (string) config('app.business_timezone', 'Africa/Tripoli');
    }
}
