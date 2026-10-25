<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Investor\Actions\PurchaseFromFund;
use App\Domain\Investor\Support\Money;
use App\Domain\PurchaseOrder\Actions\ReceivePurchaseOrder;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;

/**
 * بضاعةٌ اشتراها الصندوقُ ولم تصل الرفَّ بعد — «بضاعة مشتراة لم تصل».
 *
 * طلبُ المالك 2026-09-24: «تقدر تعرض القيمة الموجودة في عمليات الشراء التي لم تصل بعد واشتُريت
 * بمال الصندوق حتى أعرف إجماليها».
 *
 * ## بندٌ في القيمة — قرارُ المالك 2026-10-13
 *
 * {@see PurchaseFromFund} يُخرج التكلفةَ الواصلة من الخزينة **يومَ الشراء**، والبضاعةُ لا تصير
 * طبقاتٍ على الرفّ إلا **يومَ تُستلم**. كان هذا الرقمُ يُعرض بجانب القيمة لا فيها (2026-09-24: «عرض
 * لأن المال استُعمل بالفعل»)، فكانت القيمةُ وسعرُ الوحدة ينقصان بثمن اللوري ما دام في الطريق — ومن
 * يكتتب في تلك الأيام يشتري الوحدةَ بأقلّ من قيمتها ثم يقاسم البضاعةَ حين تصل، ومن يسحب يخرج بأقلّ
 * من حقّه. كشفته بياناتُ المالك التجريبية، فنُقض القرار: **المالُ لم يضِع، صار بضاعةً في الطريق**،
 * و{@see FundValuation} يعدّها بتكلفتها كبضاعة الرفّ.
 *
 * ## ما يُعدّ — أمرٌ لم تُسجَّل عليه شحنةٌ بعد، لا غير
 *
 * كلُّ سطرِ أمرِ شراءٍ طالب به مستثمرون (`investor_deal_supplies`) في أمرٍ ما زال `new` أو
 * `arrived`، بما لم يصل منه:
 *
 * ```
 * القيمة = التكلفة الواصلة للسطر × (المطلوب − المستلَم) ÷ المطلوب
 * ```
 *
 * لم يصل شيءٌ فالقيمةُ التكلفةُ الواصلة كلُّها — المبلغُ الذي خرج من الخزينة بعينه.
 *
 * **والأمرُ المكتمل لا يُعدّ وإن بقي في سطوره نقص** — قرارُ المالك 2026-10-03: «خليها complete
 * ينحّي أنه في بضاعة لم تصل». {@see ReceivePurchaseOrder} يختم الأمرَ `completed` بأوّل شحنةٍ
 * مهما كانت ناقصة (قرارُ المالك 2026-09-06)، والمصنعُ لا يرسل الباقي بعدها: «النواقص خلاص تعتبر
 * خسائر ولن تصل من مصنع». فعدُّه هنا يجعل اللوحةَ تَعِد ببضاعةٍ في الطريق لا طريقَ لها، إلى
 * الأبد.
 *
 * **وسقوطُه من هنا يُنقص القيمةَ بثمنه** — وهو الصحيح: ما لن يصل خسارةٌ يحملها حمَلةُ الوحدات
 * يومَ يُقفل الأمر. وما يُسمّي الخسارةَ على فترتها بندٌ في `Docs/BACKLOG.md`.
 *
 * **والأمرُ الملغى لا يُعدّ** كذلك: لن يصل منه شيء. وما خرج له من الخزينة لا يعود بالإلغاء وحده —
 * `CancelPurchaseOrder` لا يعرف الصندوق — وهو سؤالٌ للمالك لا يُحسم هنا بعدِّ ما لن يأتي.
 */
final class FundGoodsOnOrder
{
    /**
     * ما يساويه المطلوبُ الذي لم يصل — بندُ اللوحة.
     *
     * @param  int|null  $dealId  صفقةٌ بعينها، أو كلُّ ما موّله مستثمرون
     */
    public function value(?int $dealId = null): string
    {
        return (string) ($this->lines($dealId)->sum(DB::raw($this->valueSql())) ?? '0');
    }

    /**
     * الأوامرُ واحداً واحداً، الأقدمُ أوّلاً، وتحت كلٍّ ما بقي من سطوره.
     *
     * @return array{total: string, orders: list<array<string, mixed>>}
     */
    public function __invoke(): array
    {
        $rows = $this->lines(null)
            ->leftJoin('vendors as v', 'v.id', '=', 'po.vendor_id')
            ->leftJoin('stock_items as si', 'si.id', '=', 'poi.stock_item_id')
            ->orderBy('po.order_date')
            ->orderBy('po.id')
            ->orderBy('si.name')
            ->get([
                'po.id as purchase_order_id',
                'po.status',
                'po.order_date',
                'po.expected_date',
                'v.name as vendor_name',
                'poi.stock_item_id',
                'si.code',
                'si.name',
                'si.width_cm',
                'si.height_cm',
                'si.unit',
                'poi.quantity_ordered',
                'poi.quantity_received',
                DB::raw('(poi.quantity_ordered - poi.quantity_received) as quantity_remaining'),
                DB::raw($this->valueSql().' as value'),
            ]);

        $orders = [];

        foreach ($rows as $row) {
            $id = (int) $row->purchase_order_id;
            $unit = PricingUnit::tryFrom((string) $row->unit);
            $status = PurchaseOrderStatus::tryFrom((string) $row->status);

            $orders[$id] ??= [
                'purchase_order_id' => $id,
                'vendor_name' => $row->vendor_name === null ? null : (string) $row->vendor_name,
                'status' => (string) $row->status,
                'status_label' => $status?->label() ?? (string) $row->status,
                'order_date' => $this->day($row->order_date),
                'expected_date' => $this->day($row->expected_date),
                'value' => '0',
                'lines' => [],
            ];

            $value = Money::round((string) $row->value);

            $orders[$id]['value'] = bcadd($orders[$id]['value'], $value, 2);
            $orders[$id]['lines'][] = [
                'stock_item_id' => $row->stock_item_id === null ? null : (int) $row->stock_item_id,
                'code' => $row->code === null ? null : (string) $row->code,
                'name' => $row->name === null ? null : (string) $row->name,
                'width_cm' => $row->width_cm === null ? null : (int) $row->width_cm,
                'height_cm' => $row->height_cm === null ? null : (int) $row->height_cm,
                'unit' => $unit?->value,
                'unit_label' => $unit?->label(),
                'quantity_ordered' => (string) $row->quantity_ordered,
                'quantity_received' => (string) $row->quantity_received,
                'quantity_remaining' => (string) $row->quantity_remaining,
                'value' => $value,
            ];
        }

        foreach ($orders as $id => $order) {
            $orders[$id]['value'] = Money::round($order['value']);
        }

        return [
            'total' => Money::round($this->value()),
            'orders' => array_values($orders),
        ];
    }

    /**
     * سطورُ أوامر الشراء التي طالب بها مستثمرون، في أمرٍ لم تُسجَّل عليه شحنةٌ بعد.
     *
     * بالمطالبة لا بصفّ الخزينة: المطالبةُ هي ما يختم الطبقةَ باسم الصندوق يوم تصل
     * (`InvestorService::dealForSupply`)، فهي وحدها تقول أيَّ سطرٍ ماله — أمرٌ اشترى الصندوقُ سطراً
     * واحداً من سطريه لا يُعدّ الآخرُ فيه.
     */
    private function lines(?int $dealId): Builder
    {
        return DB::table('investor_deal_supplies as s')
            ->join('purchase_orders as po', 'po.id', '=', 's.source_id')
            ->join('purchase_order_items as poi', function ($join): void {
                $join->on('poi.purchase_order_id', '=', 'po.id')
                    ->on('poi.stock_item_id', '=', 's.stock_item_id');
            })
            ->where('s.source_type', AuditSubject::PurchaseOrder->value)
            ->when($dealId !== null, fn ($q) => $q->where('s.investor_deal_id', $dealId))
            ->whereNull('s.deleted_at')
            ->whereNull('po.deleted_at')
            ->whereNull('poi.deleted_at')
            ->whereIn('po.status', [
                PurchaseOrderStatus::New->value,
                PurchaseOrderStatus::Arrived->value,
            ])
            ->where('poi.quantity_ordered', '>', 0)
            ->whereColumn('poi.quantity_received', '<', 'poi.quantity_ordered');
    }

    /** التكلفةُ الواصلة للسطر بنسبة ما لم يصل منه — التعريفُ الواحد للرقم والقائمة. */
    private function valueSql(): string
    {
        return 'coalesce(poi.final_total_cost, 0) * (poi.quantity_ordered - poi.quantity_received) / poi.quantity_ordered';
    }

    private function day(mixed $value): ?string
    {
        return $value === null ? null : substr((string) $value, 0, 10);
    }
}
