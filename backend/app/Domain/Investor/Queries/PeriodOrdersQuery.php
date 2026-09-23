<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Support\Facades\DB;

/**
 * طلبياتُ فترةٍ واحدة — «أيُّ طلبيةٍ أعطت المستثمرين ربحاً، وكم أخذ كلُّ واحدٍ منها».
 *
 * شاشةُ الفترة الواحدة من {@see /Docs/investor-deals/CONTINUOUS-FUND-DESIGN.md} — §٤.٣.
 *
 * ## الدفترُ هو المصدر، لا حسابٌ ثانٍ
 *
 * {@see DealOrdersQuery} تُعيد اشتقاقَ ربح الطلبية من الـFIFO كلَّ مرّة، وهو الصواب هناك:
 * سؤالُها «كم تساوي هذه الطلبية للصفقة الآن». وسؤالُ الفترة غيرُه — **«ماذا قبض الناسُ فيها»** —
 * وجوابُه صفوفُ المحافظ نفسُها التي قُبض بها. فترةٌ أُقفلت وُزّع مالُها بأرقامٍ مُعلنة، ولو
 * أُعيد الحسابُ بعد سنةٍ بدفترٍ تحرّك — طبقةٌ أُعيد تقييمها، حركةٌ عُكست — لأظهرت الشاشةُ رقماً
 * غير الذي دخل الجيوب.
 *
 * **وهو السببُ نفسه الذي جعل `CloseInvestmentPeriod` يجمّد «ما أُفرِج عنه» لا «ما حُسب».**
 *
 * ## والعكسُ يُنسب إلى الطلبية التي عكسها
 *
 * صفُّ العكس لا يحمل مصدراً خاصّاً به ({@see PostDealShare::reverse()}): يُقرأ مصدرُه من الصفّ
 * الذي يُبطله، تماماً كما تفعل {@see InvestorWalletEntry::deltas()} بإشارته. وقد يقع في فترةٍ
 * **غير** فترة أصله — سبتمبر أُقفل وخرج مالُه، فتصحيحُه يقع على المفتوحة اليوم — فيظهر بسالبه
 * على أكتوبر، وتبقى سبتمبر على أرقامها التي قُبضت. وهو ما تفعله المحاسبةُ بتصحيح فترةٍ مُقفلة
 * في كل مكان.
 *
 * ## وثلاثةُ مصادرَ تردّ إلى طلبيةٍ واحدة
 *
 * المستثمر يُقبض من طلبيةٍ بأكثر من طريق، وكلُّ طريقٍ يختم صفَّه بمفتاحٍ آخر:
 *
 * | المصدر | الطريق | يردّ إلى الطلبية بـ |
 * | --- | --- | --- |
 * | `order` | ربحُ الطلبية عند التسليم | نفسه |
 * | `order_item` | هامشُ السادة، يُقبض على **سطرٍ** عند «جاهزة للطباعة» | `order_items.order_id` |
 * | `stock_movement` | هامشُ ما أتلفته طبعةٌ فاسدة | `stock_movements.reference_id` |
 *
 * ولولا الردُّ لاختفت من القائمة طلبيةٌ دفعت للمستثمرين فعلاً — ولظهر مجموعُ الفترة أكبرَ من
 * مجموع صفوفها بلا تفسير.
 *
 * وما لا مصدرَ له طلبيةٌ — `profit_release` و`capital_writedown` وما يشبههما — ليس صفَّ طلبية
 * فيسقط من القائمة: هو تحريكُ مالٍ بين جيبين لا ربحٌ صنعته بضاعة.
 */
final class PeriodOrdersQuery
{
    /**
     * @return array{
     *     orders: list<array<string, mixed>>,
     *     investors: list<array{investor_id: int, name: string, amount: string}>,
     *     totals: array{orders: int, investors_total: string}
     * }
     */
    public function __invoke(int $periodId): array
    {
        $entries = InvestorWalletEntry::query()
            ->with('reversedEntry')
            ->where('investment_period_id', $periodId)
            ->get();

        $sourced = [];

        foreach ($entries as $entry) {
            $origin = $entry->type === WalletEntryType::Reversal
                ? $entry->reversedEntry
                : $entry;

            if ($origin === null || $origin->source_type === null || $origin->source_id === null) {
                continue;
            }

            $sourced[] = [
                'type' => (string) $origin->source_type,
                'id' => (int) $origin->source_id,
                'investor_id' => (int) $entry->investor_id,
                'amount' => $entry->deltas()['profit_deal'],
            ];
        }

        if ($sourced === []) {
            return $this->nothing();
        }

        $orderOf = $this->ordersBehind($sourced);

        // المستثمر ← المبلغ، داخل الطلبية ← الخريطة. والمشيُ في PHP لا في SQL لأن `deltas()`
        // هي التعريفُ الواحد لما يفعله كلُّ نوعِ صفّ — وإعادةُ كتابته `CASE`ات هو ما يفترق عنه
        // يوم يُضاف نوع.
        $perOrder = [];

        foreach ($sourced as $row) {
            $orderId = $orderOf[$row['type']][$row['id']] ?? null;

            if ($orderId === null) {
                continue;
            }

            $perOrder[$orderId][$row['investor_id']] = bcadd(
                $perOrder[$orderId][$row['investor_id']] ?? '0',
                $row['amount'],
                8,
            );
        }

        return $this->rows($perOrder);
    }

    /**
     * أيُّ طلبيةٍ خلف كل مصدر — نداءٌ واحد لكل نوع، لا نداءٌ لكل صفّ.
     *
     * **ولا تُصفّى المحذوفةُ ناعماً هنا.** سطرٌ صُحّح وحُذف بقي مالُه في جيب صاحبه، وإسقاطُه
     * يجعل مجموعَ الصفوف أقلَّ من مجموع الفترة بلا سبب. والطلبيةُ نفسُها هي ما يُصفّى لاحقاً،
     * حين تُقرأ بياناتُها.
     *
     * @param  list<array{type: string, id: int, investor_id: int, amount: string}>  $sourced
     * @return array<string, array<int, int>> النوع ← المصدر ← الطلبية
     */
    private function ordersBehind(array $sourced): array
    {
        $ids = [];

        foreach ($sourced as $row) {
            $ids[$row['type']][$row['id']] = $row['id'];
        }

        $map = [];

        foreach ($ids[AuditSubject::Order->value] ?? [] as $orderId) {
            $map[AuditSubject::Order->value][$orderId] = $orderId;
        }

        $lineIds = array_values($ids[AuditSubject::OrderItem->value] ?? []);

        if ($lineIds !== []) {
            foreach (DB::table('order_items')->whereIn('id', $lineIds)->get(['id', 'order_id']) as $line) {
                $map[AuditSubject::OrderItem->value][(int) $line->id] = (int) $line->order_id;
            }
        }

        $movementIds = array_values($ids[AuditSubject::StockMovement->value] ?? []);

        if ($movementIds !== []) {
            // `reference_id` آمنٌ هنا وحده: صفوفُ `scrap_loss` لها كاتبٌ واحد
            // (`Order\Actions\RecordScrapLoss`) وهو يختم الطلبية دائماً — التحذيرُ على هذا
            // العمود يخصّ `order_fulfillment`، وهي ليست من مصادر هذا الدفتر.
            $movements = DB::table('stock_movements')
                ->whereIn('id', $movementIds)
                ->where('movement_type', 'scrap_loss')
                ->whereNotNull('reference_id')
                ->get(['id', 'reference_id']);

            foreach ($movements as $movement) {
                $map[AuditSubject::StockMovement->value][(int) $movement->id] = (int) $movement->reference_id;
            }
        }

        return $map;
    }

    /**
     * الصفوفُ كما تُرسم: الطلبيةُ ببياناتها، ومن أخذ منها، ومجموعُ الفترة.
     *
     * **والصفرُ ليس صفّاً.** طلبيةٌ قُيِّدت ثم أُبطلت في فترتها نفسِها لم تُعطِ أحداً شيئاً،
     * و«0.00» أمامها تقول إنها تعادلت — وهي جملةٌ أخرى تُقرأ خطأً.
     *
     * @param  array<int, array<int, string>>  $perOrder
     * @return array{
     *     orders: list<array<string, mixed>>,
     *     investors: list<array{investor_id: int, name: string, amount: string}>,
     *     totals: array{orders: int, investors_total: string}
     * }
     */
    private function rows(array $perOrder): array
    {
        $orders = DB::table('orders as o')
            ->leftJoin('customers as cu', 'cu.id', '=', 'o.customer_id')
            ->whereIn('o.id', array_keys($perOrder))
            ->whereNull('o.deleted_at')
            ->get([
                'o.id',
                'o.code',
                'o.status',
                'o.grand_total',
                'o.delivered_at',
                'o.placed_at',
                'o.created_at',
                'cu.name as customer_name',
            ])
            ->keyBy('id');

        $names = $this->namesOf($perOrder);

        $rows = [];
        $periodTotals = [];
        $grand = '0';

        foreach ($perOrder as $orderId => $amounts) {
            $order = $orders[$orderId] ?? null;

            if ($order === null) {
                continue;
            }

            $investors = [];
            $total = '0';

            foreach ($amounts as $investorId => $amount) {
                $rounded = Money::round($amount);

                if (bccomp($rounded, '0', 2) === 0) {
                    continue;
                }

                $investors[] = [
                    'investor_id' => $investorId,
                    'name' => $names[$investorId] ?? '',
                    'amount' => $rounded,
                ];

                $total = bcadd($total, $rounded, 8);
                $periodTotals[$investorId] = bcadd($periodTotals[$investorId] ?? '0', $rounded, 8);
            }

            if ($investors === []) {
                continue;
            }

            // الأكبرُ أوّلاً داخل الصفّ: من أخذ أكثرَ هو أوّلُ ما يُبحث عنه.
            usort($investors, fn (array $a, array $b): int => bccomp($b['amount'], $a['amount'], 2));

            $status = OrderStatus::tryFrom((string) $order->status);

            $rows[] = [
                'order_id' => (int) $order->id,
                'code' => (string) $order->code,
                'status' => (string) $order->status,
                'status_label' => $status?->label() ?? (string) $order->status,
                'customer_name' => $order->customer_name === null ? null : (string) $order->customer_name,

                // يومُ وصولها العميل — اللحظةُ التي صار فيها المالُ للصندوق — وتسقط إلى يوم
                // كتابتها لطلبيةٍ لم تصل بعد.
                'occurred_at' => $order->delivered_at ?? $order->placed_at ?? $order->created_at,

                'grand_total' => (string) $order->grand_total,
                'investors_total' => Money::round($total),
                'investors' => $investors,
            ];

            $grand = bcadd($grand, $total, 8);
        }

        usort($rows, fn (array $a, array $b): int => [$b['occurred_at'], $b['order_id']] <=> [$a['occurred_at'], $a['order_id']]);

        return [
            'orders' => $rows,
            'investors' => $this->perInvestor($periodTotals, $names),
            'totals' => ['orders' => count($rows), 'investors_total' => Money::round($grand)],
        ];
    }

    /**
     * @param  array<int, array<int, string>>  $perOrder
     * @return array<int, string>
     */
    private function namesOf(array $perOrder): array
    {
        $investorIds = [];

        foreach ($perOrder as $amounts) {
            foreach (array_keys($amounts) as $investorId) {
                $investorIds[$investorId] = $investorId;
            }
        }

        if ($investorIds === []) {
            return [];
        }

        return DB::table('investors')
            ->whereIn('id', array_values($investorIds))
            ->pluck('name', 'id')
            ->mapWithKeys(fn ($name, $id): array => [(int) $id => (string) $name])
            ->all();
    }

    /**
     * مجموعُ كلِّ مستثمرٍ في الفترة — **مشيُ الصفوف المرسومة نفسِها** لا استعلامٌ ثانٍ، فلا
     * يمكن أن يخالف المجموعُ ما يُجمَع بالإصبع تحته.
     *
     * @param  array<int, string>  $totals
     * @param  array<int, string>  $names
     * @return list<array{investor_id: int, name: string, amount: string}>
     */
    private function perInvestor(array $totals, array $names): array
    {
        $rows = [];

        foreach ($totals as $investorId => $amount) {
            $rounded = Money::round($amount);

            if (bccomp($rounded, '0', 2) === 0) {
                continue;
            }

            $rows[] = [
                'investor_id' => $investorId,
                'name' => $names[$investorId] ?? '',
                'amount' => $rounded,
            ];
        }

        usort($rows, fn (array $a, array $b): int => bccomp($b['amount'], $a['amount'], 2));

        return $rows;
    }

    /**
     * @return array{
     *     orders: list<array<string, mixed>>,
     *     investors: list<array{investor_id: int, name: string, amount: string}>,
     *     totals: array{orders: int, investors_total: string}
     * }
     */
    private function nothing(): array
    {
        return ['orders' => [], 'investors' => [], 'totals' => ['orders' => 0, 'investors_total' => '0.00']];
    }
}
