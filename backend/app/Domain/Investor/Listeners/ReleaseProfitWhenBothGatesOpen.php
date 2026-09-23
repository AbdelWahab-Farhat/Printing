<?php

declare(strict_types=1);

namespace App\Domain\Investor\Listeners;

use App\Domain\Investor\Actions\CloseInvestmentPeriod;
use App\Domain\Order\Events\OrderPaymentsRecalculated;
use App\Domain\Order\Events\OrderProfitFinalised;
use App\Providers\AppServiceProvider;

/**
 * يُفرج عن ربح الطلبية حين تجتمع بوّابتاه — انقضاءُ فترتها، وتسليمُها وتحصيلُها.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٠.٨.
 *
 * ## لماذا حدثان لا واحد
 *
 * الشرطان لا ترتيبَ بينهما، فلا يكفي أن نستمع إلى آخرهما وقوعاً:
 *
 * | الطريق | آخرُ ما يقع | الحدث الذي يفتح الباب |
 * | --- | --- | --- |
 * | بيعٌ بالأجل | وصولُ المال | `OrderPaymentsRecalculated` |
 * | عربونٌ كامل قبل التسليم | تسليمُ الطلبية | `OrderProfitFinalised` |
 *
 * **والثاني ليس حالةً نادرة** — الدفعُ مقدَّماً طريقٌ قائمٌ في هذا النظام. ولو عُلِّق الإفراجُ
 * على حدث الدفع وحده لانتظر مالُ صاحبه كنسةَ الكرون بلا سبب، **ولبدا النظامُ سليماً**: الرقمُ
 * يصل في النهاية، والخللُ تأخيرٌ لا نقصان، فلا اختبارَ يسقط ولا مستخدمَ يشتكي بوضوح.
 *
 * ## وعلى كلٍّ منهما يأتي بعد من يكتب
 *
 * {@see PostEarningsWhenOrderIsFinalised} يُقيّد الربح، و{@see PostFundProceedsWhenPaymentsMove}
 * يُدخل النقد — وهذا مسجَّلٌ بعدهما في {@see AppServiceProvider}، فترتيبُ
 * التسجيل هو ترتيبُ التنفيذ. فحين يقرأ هذا الدفترَ يكون الصفُّ مكتوباً والمالُ في الدرج.
 *
 * ## وهو رخيصٌ حين لا يعني شيئاً
 *
 * يصل الحدثان عن كل طلبيةٍ في النظام، وأكثرُها لا يخصّ الصندوق.
 * و{@see CloseInvestmentPeriod::releaseWhatIsNowPayable()} يخرج عند أوّل سؤال: طلبيةٌ لا فترةَ
 * لها، أو فترةٌ ما زالت مفتوحة — وكلاهما استعلامٌ واحد.
 */
final class ReleaseProfitWhenBothGatesOpen
{
    public function __construct(private readonly CloseInvestmentPeriod $periods) {}

    public function handle(OrderPaymentsRecalculated|OrderProfitFinalised $event): void
    {
        $this->periods->releaseWhatIsNowPayable($event->orderId, null);
    }
}
