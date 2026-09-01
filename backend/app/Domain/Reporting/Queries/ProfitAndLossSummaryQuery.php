<?php

declare(strict_types=1);

namespace App\Domain\Reporting\Queries;

use App\Domain\Order\Actions\RecalculateOrderTotals;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * [Total Revenue (product + service)] − [Total COGS (material + manufacturing)] = Gross Profit,
 * over a date range — plus cash actually collected in the same window, reported alongside rather
 * than netted against COGS.
 *
 * **Reads across `Order` directly rather than through `OrderService`** — a deliberate, documented
 * exception to RULES.md §3. This context's entire purpose is cross-cutting read aggregation over
 * figures three other contexts already compute and cache; routing each number through a service
 * method would not reduce coupling, only relocate it. What this query must **not** do is
 * re-derive any of those figures itself: every SUM below is over an already-cached column
 * (`items_total`, `design_fee`, `total_cogs`, `order_items.material_cost`/`labor_cost`/
 * `overhead_cost`, `order_payments.amount`), never a re-computation of a money rule that already
 * has one home. The one exception — which orders' `design_fee` actually counts as revenue — is
 * the same `design_source = 'in_house'` condition {@see RecalculateOrderTotals}
 * already states once; restating it here in SQL is the same trade-off
 * `Order\Support\PaymentStatusExpression` already makes for exactly this reason: a report reading
 * across every order cannot afford to load each one into PHP just to ask one boolean question of it.
 *
 * **Revenue is recognised on delivery or settlement, accrual-style — `total_cogs` has no cash-basis
 * counterpart.** Materials were already paid for separately, through purchase orders; gross profit
 * is therefore only ever computed against the accrual figures. `cash_collected` is reported
 * beside it as a reconciliation figure, at the caller's chosen basis (`order_payments.paid_at`),
 * never subtracted from anything — pairing it against COGS would imply a cash-basis margin this
 * model does not have.
 *
 * **`additional_cost` is deliberately absent from revenue here, as `delivery_price` and
 * `discount` already are.** All three sit inside `grand_total` and none of them is a product or
 * a service this statement recognises: they are charges and reliefs on the way to what the
 * customer pays. Folding the packaging charge into `revenue.service` would make this report
 * disagree with its own delivery line, which is the inconsistency the omission avoids. A
 * business that later wants «كم حصّلنا مقابل التغليف؟» answered has the column and its reason
 * code waiting — that is a new figure on this statement, not a redefinition of an existing one.
 *
 * `design_fee` carries no cost of its own anywhere in this codebase — see BUSINESS-FIELDS-DESIGN
 * and the plan's own note — so service revenue is, by construction, 100% margin here. Not a bug:
 * a deliberate, already-approved simplification.
 */
final class ProfitAndLossSummaryQuery
{
    /**
     * @return array<string, mixed>
     */
    public function __invoke(ProfitAndLossFilters $filters): array
    {
        $recognized = Order::query()
            ->whereIn('status', [OrderStatus::Delivered->value, OrderStatus::Settled->value])
            ->whereBetween(DB::raw('COALESCE(delivered_at, settled_at)'), [$filters->from, $filters->to]);

        $productRevenue = (string) (clone $recognized)->sum('items_total');

        $serviceRevenue = (string) (clone $recognized)
            ->selectRaw(
                'COALESCE(SUM(CASE WHEN design_source = ? THEN design_fee ELSE 0 END), 0) as total',
                [DesignSource::InHouse->value],
            )
            ->value('total');

        $cogs = (string) (clone $recognized)->sum('total_cogs');

        $orderIds = (clone $recognized)->pluck('id');

        $costBreakdown = OrderItem::query()
            ->whereIn('order_id', $orderIds)
            ->selectRaw(
                'COALESCE(SUM(material_cost), 0) as material, '.
                'COALESCE(SUM(labor_cost), 0) as labor, '.
                'COALESCE(SUM(overhead_cost), 0) as overhead',
            )
            ->first();

        $cashCollected = (string) OrderPayment::query()
            ->where('type', OrderPaymentType::Payment->value)
            ->whereBetween('paid_at', [$filters->from, $filters->to])
            ->sum('amount');

        // **Money the business decided it will never collect** — the difference on an order that
        // came back short, closed on the record rather than typed in as a payment nobody
        // received. See OrderPaymentType::WriteOff.
        //
        // Reported beside `cash_collected` and deliberately *not* subtracted from gross profit:
        // this statement recognises revenue when the order is delivered, and carries no expense
        // side at all — there is no opex line here to put a bad debt on. Netting it off the
        // gross would quietly mix an accrual figure with a collection one and leave neither
        // readable. It is the same reconciliation shelf `cash_collected` already sits on.
        //
        // A write-off that was undone is not a loss, so the reversed ones are left out. Note the
        // difference from `cash_collected` above, which counts every `payment` row in the period
        // whether or not it was later cancelled — that figure answers «كم دخل الدرج» and is left
        // exactly as it was rather than quietly redefined here.
        $writeOffs = (string) OrderPayment::query()
            ->where('type', OrderPaymentType::WriteOff->value)
            ->whereBetween('paid_at', [$filters->from, $filters->to])
            ->whereDoesntHave('reversal')
            ->sum('amount');

        $revenueTotal = Money::sum($productRevenue, $serviceRevenue);

        return [
            'period' => [
                'from' => $filters->from->toDateString(),
                'to' => $filters->to->toDateString(),
            ],
            'revenue' => [
                'product' => Money::round($productRevenue),
                'service' => Money::round($serviceRevenue),
                'total' => $revenueTotal,
            ],
            'cost_of_goods_sold' => [
                'material' => Money::round((string) $costBreakdown->material),
                'labor' => Money::round((string) $costBreakdown->labor),
                'overhead' => Money::round((string) $costBreakdown->overhead),
                'total' => Money::round($cogs),
            ],
            'gross_profit' => Money::round(bcsub($revenueTotal, $cogs, 8)),
            'cash_collected' => Money::round($cashCollected),
            'write_offs' => Money::round($writeOffs),
            'orders_recognized' => $orderIds->count(),
        ];
    }
}
