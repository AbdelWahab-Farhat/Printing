<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Investor\Support\Money;
use App\Domain\Investor\Support\StillOwed;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * بضاعةُ الصندوق خارج الرفّ — طلبيةً طلبية، وما أخذته كلٌّ منها.
 *
 * «بضاعة خرجت ولم تُسلَّم أريد معرفة ماهي هذه البضاعة أو الطلبات المرتبطة بها، وسُلِّمت ولم
 * تُحصَّل كذلك» — طلبُ المالك 2026-09-24. البندان في اللوحة رقمان بلا اسم، وخلف كلٍّ منهما
 * طلبياتٌ بعينها: عالقةٌ في الطريق، أو عند عميلٍ لم يدفع.
 *
 * **والصفوفُ صفوفُ {@see FundDraws} نفسِها** التي يجمعها بندُ {@see FundValuation} — فمجموعُ
 * القائمة هو رقمُ اللوحة بالبناء لا بالمصادفة.
 *
 * **والأقدمُ أوّلاً**، عكسَ السجلّات. هذه ليست حكايةً تُقرأ من آخرها، بل ما بقي معلّقاً: طلبيةٌ
 * في الطريق منذ أسبوعين، أو دَينٌ عمرُه شهر، هو ما فُتحت الشاشةُ لأجله.
 */
final class FundGoodsOut
{
    public function __construct(private readonly FundDraws $draws) {}

    /**
     * خرجت ولم تُسلَّم — بتاريخ كتابة الطلبية.
     *
     * @return array{total: string, orders: list<array<string, mixed>>}
     */
    public function inFlight(): array
    {
        return $this->listing($this->draws->inFlight(), 'placed_at');
    }

    /**
     * سُلِّمت ولم تُحصَّل — بتاريخ تسليمها، وبما بقي على العميل.
     *
     * @return array{total: string, orders: list<array<string, mixed>>}
     */
    public function uncollected(): array
    {
        return $this->listing($this->draws->uncollected(), 'delivered_at');
    }

    /**
     * @param  'placed_at'|'delivered_at'  $agedBy  اليومُ الذي يُقاس منه طولُ الانتظار
     * @return array{total: string, orders: list<array<string, mixed>>}
     */
    private function listing(Builder $draws, string $agedBy): array
    {
        $total = Money::round((string) ((clone $draws)->sum('c.total_cost') ?? '0'));

        $lines = (clone $draws)
            ->leftJoin('stock_items as si', 'si.id', '=', 'b.stock_item_id')
            ->groupBy('o.id', 'b.stock_item_id', 'si.code', 'si.name', 'si.unit')
            ->orderBy('si.name')
            ->get([
                'o.id as order_id',
                'b.stock_item_id',
                'si.code',
                'si.name',
                'si.unit',
                DB::raw('sum(c.quantity) as quantity'),
                DB::raw('sum(c.total_cost) as cost'),
            ]);

        if ($lines->isEmpty()) {
            return ['total' => $total, 'orders' => []];
        }

        $goods = [];

        foreach ($lines as $line) {
            $unit = PricingUnit::tryFrom((string) $line->unit);

            $goods[(int) $line->order_id][] = [
                'stock_item_id' => $line->stock_item_id === null ? null : (int) $line->stock_item_id,
                'code' => $line->code === null ? null : (string) $line->code,
                'name' => $line->name === null ? null : (string) $line->name,
                'unit' => $unit?->value,
                'unit_label' => $unit?->label(),
                'quantity' => (string) $line->quantity,
                'cost' => Money::round((string) $line->cost),
            ];
        }

        $orders = DB::table('orders as o')
            ->leftJoin('customers as cu', 'cu.id', '=', 'o.customer_id')
            ->whereIn('o.id', array_keys($goods))
            ->get([
                'o.id',
                'o.code',
                'o.status',
                'o.grand_total',
                'o.paid_amount',
                'o.written_off_amount',
                'o.carrier_settled_amount',
                'o.placed_at',
                'o.delivered_at',
                'o.created_at',
                'cu.name as customer_name',
            ]);

        $rows = [];

        foreach ($orders as $order) {
            $cost = '0';

            foreach ($goods[(int) $order->id] as $line) {
                $cost = bcadd($cost, $line['cost'], 2);
            }

            // ما بقي على العميل، لا أقلَّ من صفر: دفعةٌ زائدة تُردّ لاحقاً ليست ديناً سالباً.
            // وبالثلاثة التي تُغلق الدَّين لا بالنقد وحده — {@see StillOwed}: فرقٌ شُطب لم يعد
            // على أحد، دفعت الشركةُ نصيبَ الصندوق منه.
            $covered = bcadd(
                bcadd((string) $order->paid_amount, (string) $order->written_off_amount, 2),
                (string) $order->carrier_settled_amount,
                2,
            );
            $remaining = bcsub((string) $order->grand_total, $covered, 2);

            $rows[] = [
                'order_id' => (int) $order->id,
                'code' => (string) $order->code,
                'status' => (string) $order->status,
                'status_label' => OrderStatus::tryFrom((string) $order->status)?->label() ?? (string) $order->status,
                'customer_name' => $order->customer_name === null ? null : (string) $order->customer_name,
                'placed_at' => $this->iso($order->placed_at ?? $order->created_at),
                'delivered_at' => $this->iso($order->delivered_at),
                'grand_total' => (string) $order->grand_total,
                'paid_amount' => (string) $order->paid_amount,
                'remaining' => bccomp($remaining, '0', 2) > 0 ? $remaining : '0.00',
                'cost' => Money::round($cost),
                'goods' => $goods[(int) $order->id],
            ];
        }

        // الأقدمُ أوّلاً، وما لا تاريخَ له في الآخر.
        usort($rows, fn (array $a, array $b): int => [$a[$agedBy] === null, $a[$agedBy], $a['order_id']]
            <=> [$b[$agedBy] === null, $b[$agedBy], $b['order_id']]);

        return ['total' => $total, 'orders' => $rows];
    }

    /** تاريخُ القاعدة بتوقيت التطبيق، مكتوباً بإزاحته فلا يُقرأ على الهاتف بتوقيتٍ آخر. */
    private function iso(?string $value): ?string
    {
        return $value === null ? null : Carbon::parse($value, config('app.timezone'))->toIso8601String();
    }
}
