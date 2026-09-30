<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use App\Domain\Investor\Support\OrderDealSlices;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\OrderService;
use Illuminate\Support\Facades\DB;

/**
 * ما حصّله الصندوقُ فعلاً من طلبيةٍ باعت بضاعتَه — نقداً في الخزينة.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٤.
 *
 * ## النقدُ ليس القيمة، وهذا نصفُ الميزة
 *
 * الصندوق يعترف بالربح عند **التسليم**، والعميلُ يدفع بعده بأسابيع. فلو تحرّكت الخزينةُ عند
 * التسليم لسمحنا بالشراء والسحب من مالٍ لم يصل. فالخزينةُ تتحرّك عند **التحصيل**، والمستحقُّ —
 * ما سُلِّم ولم يُحصَّل — يدخل **قيمة** الصندوق ولا يدخل نقدَه.
 *
 * ```
 * نصيبُ الصندوق من هذه الطلبية = إيرادُ طبقاته فيها × (المحصَّل ÷ إجمالي الطلبية)
 * ```
 *
 * `OrderDealSlices` هي من يقسم إيرادَ الطلبية على الأرفف التي سحبت منها — **الحسابُ نفسه** الذي
 * تُقسَّم به أرباحُها، فلا تعريفان يفترقان. والنسبةُ من المحصَّل لأن العميل يدفع على دفعات:
 * الصندوقُ يقبض نصيبَه منها بنسبتها، لا أوّلَها كلَّه ولا آخرَها.
 *
 * ## وهدفٌ يُقارَن لا صفٌّ يُضاف
 *
 * يُحسب **ما ينبغي أن يكون** ثم يُقارَن بما هو قائم: مساوٍ فلا شيء، مختلفٌ فتُعكس الصفوفُ القائمة
 * ويُكتب الجديدُ بتسلسلٍ تالٍ. وهو ما يجعل هذا الفعل يصحّح نفسه في كل طريق — دفعةٌ تُعكَس،
 * ومبلغٌ يُشطب، وطلبيةٌ تُلغى بعد قبضها — بلا أن يعرف شيئاً عن أيٍّ منها. الشكلُ نفسه الذي يمشي
 * عليه {@see PostDealShare}، ولنفس السبب.
 *
 * **والطلبيةُ الملغاة هدفُها صفر**: بضاعتُها رجعت إلى الرفّ، والمالُ المقبوض يُردّ للعميل بدفعةٍ
 * عكسية تمرّ من هنا مرّةً أخرى.
 *
 * ## والشطبُ تدفعه الشركة — هدفٌ ثانٍ بجانب الأوّل
 *
 * قرارُ المالك: خطرُ العميل على المطبعة لا على المستثمر. فما شُطب من دَين الطلبية يدفع الشركةُ
 * نصيبَ الصندوق منه، بصفٍّ من نوعه ({@see CashEntryType::WriteOffCoveredByCompany}):
 *
 * ```
 * ما دفعه العميل   = إيرادُ الصندوق × min(1, (النقد + ما قبضه الناقل) ÷ الإجمالي)
 * ما دفعته الشركة  = إيرادُ الصندوق × min(1, (النقد + الناقل + المشطوب) ÷ الإجمالي) − ما دفعه العميل
 * ```
 *
 * **وما قبضه الناقلُ عند الباب محسوبٌ للعميل** — دفعه كاملاً، وذهب جزءٌ منه أجرةَ توصيلٍ باتّفاق،
 * والمالُ الذي بقي عندنا يغطّي البضاعة. والثاني فرقٌ من الأوّل لا نسبةٌ مستقلّة، فلا يضيع قرشٌ
 * بين تقريبين. **وقبل هذا كان الصندوقُ لا يُقيَّد له شيءٌ أصلاً**: كان يقرأ `paid_amount` من مصفوفةٍ
 * لا تحمله، فيصير الهدفُ صفراً في كلّ طلبية.
 */
final class PostFundProceedsForOrder
{
    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
        private readonly FundDeal $fund,
        private readonly RecordCashEntry $cash,
    ) {}

    public function __invoke(int $orderId): void
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return;
        }

        DB::transaction(function () use ($orderId, $fundId): void {
            [$fromCustomer, $fromCompany] = $this->targetsFor($orderId, $fundId);

            $this->reconcile($orderId, CashEntryType::SaleProceeds, $fromCustomer, 'تصحيح تحصيل الصندوق من الطلبية');
            $this->reconcile($orderId, CashEntryType::WriteOffCoveredByCompany, $fromCompany, 'تصحيح ما تحمّلته الشركة من شطب الطلبية');
        });
    }

    /**
     * يجعل صفوفَ نوعٍ واحدٍ لهذه الطلبية تساوي هدفَها: مساوٍ فلا شيء، وإلا عُكس القائمُ كلُّه
     * وكُتب الجديدُ بتسلسلٍ تالٍ.
     *
     * **والتسلسلُ مشتركٌ بين النوعين** — المفتاحُ الفريد `(source_type, source_id, source_sequence)`
     * لا يحمل النوع، فأكبرُ تسلسلٍ يُقرأ على صفوف الطلبية كلِّها.
     */
    private function reconcile(int $orderId, CashEntryType $type, string $target, string $reason): void
    {
        $standing = InvestmentCashEntry::query()
            ->where('source_type', AuditSubject::Order->value)
            ->where('source_id', $orderId)
            ->whereDoesntHave('reversedBy')
            ->where('type', $type)
            ->get();

        $current = '0';

        foreach ($standing as $entry) {
            $current = bcadd($current, (string) $entry->amount, 8);
        }

        if (bccomp($current, $target, 2) === 0) {
            return;
        }

        foreach ($standing as $entry) {
            $this->cash->reverse($entry, null, $reason);
        }

        if (bccomp($target, '0', 2) <= 0) {
            return;
        }

        $sequence = 1 + (int) InvestmentCashEntry::query()
            ->where('source_type', AuditSubject::Order->value)
            ->where('source_id', $orderId)
            ->max('source_sequence');

        ($this->cash)(
            type: $type,
            amount: $target,
            sourceType: AuditSubject::Order->value,
            sourceId: $orderId,
            sourceSequence: $sequence,
        );
    }

    /**
     * ما ينبغي أن يكون في الخزينة عن هذه الطلبية اليوم — من العميل، ومن الشركة عن المشطوب.
     *
     * @return array{0: string, 1: string}
     */
    private function targetsFor(int $orderId, int $fundId): array
    {
        $none = ['0.00', '0.00'];
        $order = $this->orders->profitAttributionFor($orderId);

        if ($order === null || $order['lines'] === [] || $order['status'] === OrderStatus::Cancelled->value) {
            return $none;
        }

        $grandTotal = (string) $order['grand_total'];

        if (bccomp($grandTotal, '0', 2) <= 0) {
            return $none;
        }

        $byCustomer = bcadd((string) $order['paid_amount'], (string) $order['carrier_settled_amount'], 8);
        $covered = bcadd($byCustomer, (string) $order['written_off_amount'], 8);

        if (bccomp($covered, '0', 2) <= 0) {
            return $none;
        }

        $slices = OrderDealSlices::forOrder(
            $order,
            $this->inventory->consumptionBreakdownFor(
                array_map(fn (array $line) => $line['movement_id'], $order['lines']),
            ),
        );

        $revenue = (string) ($slices[$fundId]['revenue'] ?? '0');

        if (bccomp($revenue, '0', 2) <= 0) {
            return $none;
        }

        $fromCustomer = Money::round(bcmul($revenue, $this->ratio($byCustomer, $grandTotal), 8));
        $inAll = Money::round(bcmul($revenue, $this->ratio($covered, $grandTotal), 8));

        return [$fromCustomer, Money::round(bcsub($inAll, $fromCustomer, 8))];
    }

    /**
     * جزءُ الإجمالي الذي غطّاه هذا المبلغ، مقصوصاً عند الواحد: دفعةٌ زائدة تُردّ لاحقاً لا تجعل
     * الصندوقَ يقبض أكثر ممّا باع.
     */
    private function ratio(string $amount, string $grandTotal): string
    {
        if (bccomp($amount, '0', 2) <= 0) {
            return '0';
        }

        return bccomp($amount, $grandTotal, 2) >= 0 ? '1' : bcdiv($amount, $grandTotal, 8);
    }
}
