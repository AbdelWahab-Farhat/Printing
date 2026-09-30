<?php

declare(strict_types=1);

namespace App\Domain\Investor\Support;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Investor\Actions\PostFundProceedsForOrder;
use App\Domain\Investor\Queries\FundDraws;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Order\Enums\PaymentStatus;

/**
 * «ما زال على العميل شيء» — الشرطُ الواحد الذي يقرؤه الصندوقُ من الطلبيات.
 *
 * ## وكان `paid_amount < grand_total`، وهذا ما تغيّر
 *
 * الدَّينُ يُغلَق بثلاثة: نقدٌ قُبض، ومبلغٌ شُطب، ومبلغٌ قبضه الناقلُ عند الباب — وهذا تعريفُ
 * {@see PaymentStatus::between()} نفسُه. والصندوقُ كان يقرأ الأوّلَ وحده، فطلبيةٌ شُطب فرقُها
 * تبقى «غيرَ محصَّلة» إلى الأبد: تحبس فترتَها «قيد الإغلاق»، وتُعدّ مستحقّاً في قيمة الصندوق،
 * ولا يُفرَج عن ربحها أبداً.
 *
 * **والشطبُ يُغلق الدَّين هنا لأن الشركة تدفعه.** قرارُ المالك: خطرُ العميل على المطبعة لا على
 * المستثمر — كما في الإلغاء: «استلم الزبون ما استلمش، المطبعة تتحمّل». فالشطبُ يُدخل خزينةَ
 * الصندوق نصيبَه من الفرق من مال الشركة ({@see PostFundProceedsForOrder})، والفترةُ بعده لا
 * تنتظر مالاً لن يأتي.
 *
 * **قارئوه ثلاثة، والشرطُ واحد:** بوّابةُ الإفراج ({@see InvestorBalances::ordersNotCollected()})،
 * وانتظارُ الفترة ({@see CloseInvestmentPeriod}), والمستحقُّ في القيمة ({@see FundDraws::uncollected()}).
 * نسخةٌ ثانيةٌ منه في أيٍّ منها كانت ستفرج عن ربح طلبيةٍ تعدّها القيمةُ ديناً قائماً.
 */
final class StillOwed
{
    /**
     * @param  string  $alias  اسمُ جدول الطلبيات في الاستعلام، أو فارغٌ حين لا اسمَ له
     */
    public static function sql(string $alias = ''): string
    {
        $c = $alias === '' ? '' : $alias.'.';

        return "({$c}paid_amount + {$c}written_off_amount + {$c}carrier_settled_amount) < {$c}grand_total";
    }
}
