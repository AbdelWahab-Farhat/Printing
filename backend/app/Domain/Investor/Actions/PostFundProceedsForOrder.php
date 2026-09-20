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
 */
final class PostFundProceedsForOrder
{
    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
        private readonly FundDeal $fund,
        private readonly RecordCashEntry $cash,
    ) {}

    public function __invoke(int $orderId): ?InvestmentCashEntry
    {
        $fundId = $this->fund->idOrNull();

        if ($fundId === null) {
            return null;
        }

        return DB::transaction(function () use ($orderId, $fundId): ?InvestmentCashEntry {
            $target = $this->targetFor($orderId, $fundId);

            $standing = InvestmentCashEntry::query()
                ->where('source_type', AuditSubject::Order->value)
                ->where('source_id', $orderId)
                ->whereDoesntHave('reversedBy')
                ->where('type', CashEntryType::SaleProceeds)
                ->get();

            $current = '0';

            foreach ($standing as $entry) {
                $current = bcadd($current, (string) $entry->amount, 8);
            }

            if (bccomp($current, $target, 2) === 0) {
                return null;
            }

            foreach ($standing as $entry) {
                $this->cash->reverse($entry, null, 'تصحيح تحصيل الصندوق من الطلبية');
            }

            if (bccomp($target, '0', 2) <= 0) {
                return null;
            }

            $sequence = 1 + (int) InvestmentCashEntry::query()
                ->where('source_type', AuditSubject::Order->value)
                ->where('source_id', $orderId)
                ->max('source_sequence');

            return ($this->cash)(
                type: CashEntryType::SaleProceeds,
                amount: $target,
                sourceType: AuditSubject::Order->value,
                sourceId: $orderId,
                sourceSequence: $sequence,
            );
        });
    }

    /** ما ينبغي أن يكون في الخزينة عن هذه الطلبية اليوم. */
    private function targetFor(int $orderId, int $fundId): string
    {
        $order = $this->orders->profitAttributionFor($orderId);

        if ($order === null || $order['lines'] === [] || $order['status'] === OrderStatus::Cancelled->value) {
            return '0.00';
        }

        $grandTotal = (string) ($order['grand_total'] ?? '0');
        $paid = (string) ($order['paid_amount'] ?? '0');

        if (bccomp($grandTotal, '0', 2) <= 0 || bccomp($paid, '0', 2) <= 0) {
            return '0.00';
        }

        $slices = OrderDealSlices::forOrder(
            $order,
            $this->inventory->consumptionBreakdownFor(
                array_map(fn (array $line) => $line['movement_id'], $order['lines']),
            ),
        );

        $revenue = (string) ($slices[$fundId]['revenue'] ?? '0');

        if (bccomp($revenue, '0', 2) <= 0) {
            return '0.00';
        }

        // المحصَّلُ قد يتجاوز الإجمالي بدفعةٍ زائدة تُردّ لاحقاً؛ النسبةُ تُقصّ عند الواحد فلا
        // يقبض الصندوقُ أكثر ممّا باع.
        $ratio = bccomp($paid, $grandTotal, 2) >= 0 ? '1' : bcdiv($paid, $grandTotal, 8);

        return Money::round(bcmul($revenue, $ratio, 8));
    }
}
