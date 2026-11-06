<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Support;

use Carbon\CarbonImmutable;

/**
 * يومٌ من أيام المحلّ — بتوقيت طرابلس — محوَّلاً إلى UTC. نسخةُ هذا السياق، للسبب الذي يعطيه `Money`.
 */
final class BusinessDay
{
    public static function start(string $date): CarbonImmutable
    {
        return CarbonImmutable::parse($date, self::zone())->startOfDay()->utc();
    }

    public static function end(string $date): CarbonImmutable
    {
        return CarbonImmutable::parse($date, self::zone())->endOfDay()->utc();
    }

    private static function zone(): string
    {
        return (string) config('app.business_timezone', 'Africa/Tripoli');
    }
}
