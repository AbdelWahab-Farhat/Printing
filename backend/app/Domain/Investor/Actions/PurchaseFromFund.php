<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Exceptions\FundHasNotGotTheCash;
use App\Domain\Investor\Exceptions\PurchaseOrderCannotBeFunded;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Queries\FundCash;
use App\Domain\Investor\Support\FundDeal;
use App\Domain\Investor\Support\Money;
use App\Domain\PurchaseOrder\Queries\FundingSnapshotQuery;
use Illuminate\Support\Facades\DB;

/**
 * الصندوقُ يشتري لورياً — ثم آخرَ، ثم آخرَ، إلى الأبد.
 *
 * المواصفة: {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — الشريحة ٥.
 *
 * ## ما الذي يختلف عن {@see FundPurchaseOrder}
 *
 * ذاك يُنشئ **صفقةً جديدة** من أمر الشراء: يجمع ممولين، ويأخذ من محافظهم، ويحسب نصيبَ الشركة
 * فيما لم تغطّه أموالُهم، ويجمّد النسب. وهو صحيحٌ تماماً في نظامٍ كلُّ شراءٍ فيه شراكةٌ مستقلّة.
 *
 * وهنا لا شيء من ذلك يقع:
 *
 * | | صفقةٌ من أمر شراء | الصندوق |
 * | --- | --- | --- |
 * | الصفقة | تُولد في كل شراء | **واحدةٌ أبداً** |
 * | المال | `allocation` من كل محفظة | **في الخزينة منذ الإيداع** |
 * | النسب | تُجمَّد من المبالغ | **وحداتٌ تُقرأ لكل فترة** |
 * | نصيبُ الشركة | ما لم تغطِّه أموالُهم | **صفر** — الصندوقُ يدفع الثمن كلَّه |
 *
 * فالذي يبقى ثلاثة: **الرفوفُ تُضاف** إلى مواد الصندوق، و**السطورُ تُطالَب** فيعرف الاستلامُ
 * لمن يُنسب الوارد، و**النقدُ يخرج** من الخزينة.
 *
 * ## والسقفُ على النقد لا على القيمة
 *
 * صندوقٌ يساوي مئةَ ألفٍ قد لا يملك في درجه عشرة: الباقي بضاعةٌ ومستحقّات. فالشراءُ يُقاس
 * بـ{@see FundCash} ({@see FundHasNotGotTheCash}) — وهذا بالضبط هو «إعادةُ التدوير» التي طلبها
 * المالك: يُشترى بما رجع من البيع، لا بما يُظنّ أنه موجود.
 *
 * ## ولا «أمرٌ مموَّل لا يُعدَّل»
 *
 * `DealTakesNoMoreCapital` يحرس صفقةً وُلدت من أمر شراء وجُمّدت نسبُها يومَ تمويلها. والصندوقُ
 * لا يُولد من أمر شراء، فلا يمسّه الحارسُ ويبقى قائماً على الصفقات القديمة حقّاً —
 * {@see FundDeal}.
 */
final class PurchaseFromFund
{
    public function __construct(
        private readonly FundingSnapshotQuery $snapshot,
        private readonly FundDeal $fund,
        private readonly SyncDealItems $items,
        private readonly ClaimDealSupply $claimSupply,
        private readonly FundCash $cash,
        private readonly RecordCashEntry $treasury,
    ) {}

    /**
     * @param  list<int>|null  $stockItemIds  الرفوفُ المختارة، أو الكلُّ حين تُترك فارغة
     *
     * @throws PurchaseOrderCannotBeFunded
     * @throws FundHasNotGotTheCash
     */
    public function __invoke(int $purchaseOrderId, ?array $stockItemIds, ?int $actorId): InvestorDeal
    {
        return DB::transaction(function () use ($purchaseOrderId, $stockItemIds, $actorId): InvestorDeal {
            $order = ($this->snapshot)($purchaseOrderId, lock: true);

            $this->guardOrder($order);

            $shelves = $this->shelvesToFund($order, $purchaseOrderId, $stockItemIds);
            $cost = $this->costOf($order, $shelves);

            $available = ($this->cash)();

            if (bccomp($cost, $available, 2) > 0) {
                throw FundHasNotGotTheCash::make($cost, $available);
            }

            $deal = ($this->fund)();

            $this->items->append($deal, $shelves);

            foreach ($shelves as $stockItemId) {
                ($this->claimSupply)($deal, $purchaseOrderId, $stockItemId, $actorId);
            }

            // **بالتكلفة الواصلة لا بالمدفوع.** الصندوقُ يملك ما على الرفّ بتكلفته، وهي ما
            // تقرؤه `FundValuation` من `stock_batches.unit_cost` — فلو خرج من الخزينة رقمٌ آخر
            // لخلق الشراءُ الواحد فرقاً في قيمة الصندوق بلا سبب.
            ($this->treasury)(
                type: CashEntryType::Purchase,
                amount: $cost,
                sourceType: AuditSubject::PurchaseOrder->value,
                sourceId: $purchaseOrderId,
                actorId: $actorId,
            );

            return $deal->load('items.stockItem');
        });
    }

    /**
     * @param  array<string, mixed>|null  $order
     */
    private function guardOrder(?array $order): void
    {
        if ($order === null) {
            throw PurchaseOrderCannotBeFunded::notFound();
        }

        if ($order['stock_item_ids'] === []) {
            throw PurchaseOrderCannotBeFunded::hasNoLines();
        }

        if (! $order['is_fundable']) {
            throw PurchaseOrderCannotBeFunded::alreadyArriving();
        }
    }

    /**
     * الرفوفُ التي لم يطالب بها أحدٌ بعد على هذا الأمر.
     *
     * والمنطقُ نفسُه في {@see FundPurchaseOrder::shelvesToFund()}: سطرٌ مُطالَبٌ به مرّتين يجعل
     * `dealForSupply` تجيب بأوّل ما تجد ويُهمَل الثاني في صمت.
     *
     * @param  array<string, mixed>  $order
     * @param  list<int>|null  $requested
     * @return list<int>
     */
    private function shelvesToFund(array $order, int $purchaseOrderId, ?array $requested): array
    {
        $claimed = InvestorDealSupply::query()
            ->where('source_type', AuditSubject::PurchaseOrder->value)
            ->where('source_id', $purchaseOrderId)
            ->pluck('investor_deal_id', 'stock_item_id')
            ->all();

        if ($requested === null) {
            $free = array_values(array_filter(
                $order['stock_item_ids'],
                fn (int $stockItemId) => ! array_key_exists($stockItemId, $claimed),
            ));

            if ($free === []) {
                throw PurchaseOrderCannotBeFunded::everyLineIsFunded();
            }

            return $free;
        }

        $shelves = array_values(array_unique(array_map('intval', $requested)));

        if ($shelves === []) {
            throw PurchaseOrderCannotBeFunded::noLinesChosen();
        }

        foreach ($shelves as $stockItemId) {
            if (! in_array($stockItemId, $order['stock_item_ids'], true)) {
                throw PurchaseOrderCannotBeFunded::lineIsNotOnTheOrder();
            }

            if (array_key_exists($stockItemId, $claimed)) {
                $deal = InvestorDeal::query()->whereKey($claimed[$stockItemId])->first();

                throw PurchaseOrderCannotBeFunded::lineAlreadyFunded((string) ($deal?->code ?? ''));
            }
        }

        return $shelves;
    }

    /**
     * @param  array<string, mixed>  $order
     * @param  list<int>  $shelves
     */
    private function costOf(array $order, array $shelves): string
    {
        $cost = '0.00';

        foreach ($shelves as $stockItemId) {
            $cost = bcadd($cost, $order['line_costs'][$stockItemId] ?? '0.00', 2);
        }

        return Money::round($cost);
    }
}
