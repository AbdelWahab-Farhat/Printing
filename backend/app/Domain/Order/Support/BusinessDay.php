<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Order\Queries\Concerns\FiltersOrders;
use Carbon\CarbonImmutable;

/**
 * يومٌ من أيام المحلّ — بتوقيت طرابلس — محوَّلاً إلى UTC الذي تُخزَّن به كلُّ الأوقات.
 *
 * «اليوم» في فلتر قائمةٍ يومُ من يقرؤها لا يومُ UTC: دفعةٌ سُجّلت ٠٠:٥٥ في طرابلس هي ٢٢:٥٥ UTC من
 * اليوم السابق، وكان طابورا المراجعة والتسوية يُسقطانها من يومها (الطلبية 1307، ٢٠٢٦-١٠-٠٨). القاعدةُ
 * نفسُها التي يقرأ بها فلترُ الطلبيات أيامَه ({@see FiltersOrders}).
 */
final class BusinessDay
{
    /** The first instant of that local day, as UTC. */
    public static function start(string $date): CarbonImmutable
    {
        return CarbonImmutable::parse($date, self::zone())->startOfDay()->utc();
    }

    /** The last instant of that local day, as UTC. */
    public static function end(string $date): CarbonImmutable
    {
        return CarbonImmutable::parse($date, self::zone())->endOfDay()->utc();
    }

    private static function zone(): string
    {
        return (string) config('app.business_timezone', 'Africa/Tripoli');
    }
}
