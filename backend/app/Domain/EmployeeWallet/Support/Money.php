<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Support;

/**
 * تقريبُ المال — نسخةُ هذا السياق، للسبب الذي يعطيه `Treasury\Support\Money`: لا يستورد سياقٌ مساعدَ
 * سياقٍ آخر (RULES §3). وbcmath يقطع، فيُضاف نصفُ أصغر وحدة قبل القطع.
 */
final class Money
{
    public const SCALE = 2;

    public static function round(string $value): string
    {
        $half = bccomp($value, '0', 8) < 0 ? '-0.005' : '0.005';

        return bcadd(bcadd($value, $half, 8), '0', self::SCALE);
    }

    /** رقمُ الطلب — `"5"` أو `5.5` — نصّاً عشرياً بخانتين. */
    public static function normalize(mixed $value): string
    {
        return number_format((float) $value, self::SCALE, '.', '');
    }

    public static function isPositive(string $value): bool
    {
        return bccomp($value, '0', self::SCALE) > 0;
    }
}
