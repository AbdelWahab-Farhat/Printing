<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

use App\Domain\Investor\Queries\InvestorProfitSources;

/**
 * أين ربحُ طلبيةٍ واحدة من رجلٍ واحد — ما تقوله شارتُها في «مصدر الربح».
 *
 * {@see InvestorProfitSources} يقرأ الحالةَ من البوّابتين اللتين يُفرج بهما الإقفال (§٠.٨):
 * انقضاءُ الفترة، ثم تحصيلُ الطلبية. وما قبل التسليم محسوبٌ لا مقيَّد.
 */
enum ProfitSourceState: string
{
    /** بلغت «جاهزة» ولم تُسلَّم — رقمُها ما سيقيّده التسليم. */
    case AwaitingDelivery = 'awaiting_delivery';

    /** قُيِّد ربحُها، وفترتُها لم تنتهِ بعد. */
    case AwaitingPeriodEnd = 'awaiting_period_end';

    /** انتهت فترتُها، والزبونُ لم يدفع كاملاً — يحجزها الإقفال. */
    case AwaitingPayment = 'awaiting_payment';

    /** صفقةٌ قديمة من قبل الصندوق لم تُقفَل بعد. */
    case AwaitingDealClose = 'awaiting_deal_close';

    /** أُفرج عنه إلى محفظته. */
    case Released = 'released';

    public function label(): string
    {
        return match ($this) {
            self::AwaitingDelivery => 'قيد التسليم',
            self::AwaitingPeriodEnd => 'بانتظار انتهاء الفترة',
            self::AwaitingPayment => 'بانتظار التحصيل',
            self::AwaitingDealClose => 'بانتظار إقفال الصفقة',
            self::Released => 'استُلم الربح',
        };
    }

    /** ترتيبُها في القائمة: الأبعدُ عن الجيب أوّلاً. */
    public function rank(): int
    {
        return match ($this) {
            self::AwaitingDelivery => 0,
            self::AwaitingPayment => 1,
            self::AwaitingPeriodEnd => 2,
            self::AwaitingDealClose => 3,
            self::Released => 4,
        };
    }
}
