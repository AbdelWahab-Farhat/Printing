<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\InvestorProfitSources;
use App\Domain\Investor\Queries\PeriodOrdersByState;

/**
 * أين ربحُ طلبيةٍ من جيوب المستثمرين — «أيُّها استُلم، وأيُّها ينتظر».
 *
 * المواصفة: §١١ و§١٣ من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md}.
 *
 * **ليست حالةً تُكتب.** تُقرأ كلَّ مرّةٍ من حال الفترة وحال الطلبية — البوّابتان في §٠.٨ — فلا
 * تتأخّر عمّا يفعله الإقفالُ ولا تسبقه. **وقاعدتُها واحدة، هنا** ({@see ofLedgerRow()}): تقرؤها
 * شاشةُ الفترة ({@see PeriodOrdersByState}) وورقةُ «مصدر الربح» على صفحة المستثمر
 * ({@see InvestorProfitSources}) — فلا تقول إحداهما «استُلم» والأخرى «ينتظر» عن الصفّ نفسِه.
 *
 * **وترتيبُ الحالات هو ترتيبُ البوّابات** ({@see rank()}): الأولى أبعدُها عن الجيب. وطلبيةٌ تحمل
 * جزءين — هامشُ سادةٍ أُفرج عنه وربحُ تسليمٍ ينتظر — حالتُها أبعدُ جزءَيها، ومبلغُ كلِّ جزءٍ تحت حالته.
 */
enum ProfitSourceState: string
{
    /** سحبت من رفّ الصندوق ولم تُسلَّم: لا صفَّ لربحها في الدفتر بعد، ورقمُها ما سيقيّده التسليم. */
    case AwaitingDelivery = 'awaiting_delivery';

    /** قُيِّد ربحُها، والفترةُ لم تنتهِ — «لا أرباح تُسحب من أي طلبية حتى تنتهي مدة الفترة». */
    case AwaitingPeriodEnd = 'awaiting_period_end';

    /** انقضت الفترة، والعميلُ لم يدفع كاملاً — بوّابةُ التحصيل تحجزه. */
    case AwaitingPayment = 'awaiting_payment';

    /** صفقةٌ قديمة من قبل الصندوق لم تُقفَل بعد — لا تقع في فترةٍ أبداً. */
    case AwaitingDealClose = 'awaiting_deal_close';

    /** أُفرج عنه إلى محافظ أصحابه — لا «سُحب»: السحبُ من المحفظة كلِّها لا من طلبية. */
    case Released = 'released';

    public function label(): string
    {
        return match ($this) {
            self::AwaitingDelivery => 'قيد التسليم',
            self::AwaitingPeriodEnd => 'بانتظار انتهاء الفترة',
            self::AwaitingPayment => 'بانتظار التحصيل',
            self::AwaitingDealClose => 'بانتظار إقفال الصفقة',
            // لا «تم الاستلام»: ذاك لفظُ حالة الطلبية «سُلِّمت للعميل»، وهو على البطاقة نفسِها.
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

    /**
     * أيَّ بوّابةٍ اجتاز صفُّ ربحٍ مختومٌ بفترة — القاعدةُ التي يُفرج بها الإقفالُ نفسُه.
     *
     * {@see InvestorBalances::releasableInPeriod()} يُفرج في «قيد الإغلاق» عن كلّ صفٍّ إلا ربحَ
     * طلبيةٍ لم يُدفع ثمنُها؛ والمغلقةُ «لم يبقَ فيها شيء» بتعريفها.
     *
     * @param  bool  $heldForPayment  مصدرُ الصفّ الطلبيةُ نفسُها، ولم يُدفع ثمنُها
     *                                ({@see InvestorBalances::ordersNotCollected()})
     */
    public static function ofLedgerRow(PeriodStatus $period, bool $heldForPayment): self
    {
        return match ($period) {
            PeriodStatus::Open => self::AwaitingPeriodEnd,
            PeriodStatus::Closing => $heldForPayment ? self::AwaitingPayment : self::Released,
            PeriodStatus::Closed => self::Released,
        };
    }

    /**
     * ما يقع في فترة — كلُّها إلا «بانتظار إقفال الصفقة»، بترتيب البوّابات.
     *
     * @return list<self>
     */
    public static function inAPeriod(): array
    {
        return [self::AwaitingDelivery, self::AwaitingPayment, self::AwaitingPeriodEnd, self::Released];
    }
}
