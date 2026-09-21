<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Queries\FundValuation;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Investor\Support\StockPurchaseMargins;

/**
 * ثمنُ السادة يدخل خزينةَ الصندوق — لأن المطبعة اشترت، لا لأن العميل دفع.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٤.
 *
 * ## الثقبُ الذي يسدّه
 *
 * {@see PostDealStockPurchases} يقيّد للمستثمرين **الهامشَ** لحظةَ خروج البضاعة، وهو صحيحٌ
 * ونصفُ الحكاية. والنصفُ الآخر أنّ **رأس المال الذي اشترى تلك البضاعة يجب أن يعود**: الكيلو
 * غادر الرفّ، فسقط من {@see FundValuation}، وما دفعته المطبعةُ
 * ثمنَه ليس في الخزينة ولا في الطريق إليها — {@see PostFundProceedsForOrder} يقرأ
 * {@see OrderDealSlices}، وهي تُسقِط السحبَ المسعَّر عمداً لأن
 * المستثمر قُبض عنه مرّة. فبلا هذا الصفّ ينكمش الصندوقُ بتكلفة كلِّ كيلو تشتريه مطبعتُه.
 *
 * ## والمبلغُ الثمنُ كاملاً لا الهامش
 *
 * ```
 * الوارد = Σ (سعر السادة × الكمية)   على سحوب الصندوق المسعَّرة في هذا المصدر
 * ```
 *
 * التكلفةُ خرجت من هذه الخزينة يوم الشراء فتعود إليها مع ربحها، والهامشُ يخرج بعدُ إلى المحافظ
 * بـ`profit_payout` كأيّ ربحٍ آخر. ولو دخل الهامشُ وحدَه لبقي رأسُ المال ضائعاً في منتصف الطريق.
 *
 * ## ولا علاقةَ له بالعميل
 *
 * «استلم الزبون ما استلمش، المطبعة تتحمّل» — فالمبلغُ لا يُضرب في نسبة المحصَّل كما يُضرب
 * {@see PostFundProceedsForOrder}، والطلبيةُ الملغاة لا تردّه: `ReverseOrderStockDeduction`
 * يسلّم البضاعةَ المسعَّرة إلى **الشركة** لا إلى الصندوق، فالبيعُ تمَّ وانتهى. وذلك بعينه سببُ
 * أنّ {@see PostDealStockPurchases} لا يُستدعى على طريق الإلغاء أصلاً.
 *
 * ## وهدفٌ يُقارَن لا صفٌّ يُضاف
 *
 * الشكلُ نفسه الذي يمشي عليه {@see PostFundProceedsForOrder} ولنفس السبب: تصحيحُ سطرٍ يعيد
 * حساب سحبه، فيتغيّر الثمن. يُحسب ما ينبغي أن يكون، فإن ساواه القائمُ فلا شيء، وإلا عُكس
 * القائمُ كلُّه وكُتب الجديدُ بتسلسلٍ تالٍ.
 */
final class PostPressPurchaseProceeds
{
    public function __construct(
        private readonly FundDeal $fund,
        private readonly RecordCashEntry $cash,
    ) {}

    /**
     * @param  list<array<string, mixed>>  $draws  سحوبُ هذا المصدر كما تقرؤها المخزون
     * @param  string  $sourceType  من خريطة التدقيق — سطرُ الطلبية أو الحركة
     */
    public function __invoke(array $draws, string $sourceType, int $sourceId): ?InvestmentCashEntry
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return null;
        }

        $target = Money::round((string) (StockPurchaseMargins::paidByDeal($draws)[$fundId] ?? '0.00'));

        $standing = InvestmentCashEntry::query()
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->where('type', CashEntryType::StockSoldToPress)
            ->whereDoesntHave('reversedBy')
            ->get();

        $current = '0';

        foreach ($standing as $entry) {
            $current = bcadd($current, (string) $entry->amount, 8);
        }

        if (bccomp($current, $target, 2) === 0) {
            return null;
        }

        foreach ($standing as $entry) {
            $this->cash->reverse($entry, null, 'تصحيح ثمن السادة المباع للمطبعة');
        }

        if (bccomp($target, '0', 2) <= 0) {
            return null;
        }

        $sequence = 1 + (int) InvestmentCashEntry::query()
            ->where('source_type', $sourceType)
            ->where('source_id', $sourceId)
            ->max('source_sequence');

        return ($this->cash)(
            type: CashEntryType::StockSoldToPress,
            amount: $target,
            sourceType: $sourceType,
            sourceId: $sourceId,
            sourceSequence: $sequence,
        );
    }
}
