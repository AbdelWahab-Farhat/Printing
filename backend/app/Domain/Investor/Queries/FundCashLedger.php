<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Actions\PostFundProceedsForOrder;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Models\InvestmentCashEntry;
use App\Domain\Investor\Support\Money;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * سجلُّ خزينة الصندوق — «من أين أتى هذا النقد»، داخلاً وخارجاً.
 *
 * طلبُ المالك 2026-09-24: «النقد في الخزينة أريد سجلّ عملياته عند الضغط عليه، بحيث أعرف من أين
 * أتى، سجلٌّ كامل حتى للاستهلاك». كلُّ صفٍّ باسم ما جاء منه أو ذهب إليه — إيداعُ فلان، أمرُ شراءٍ
 * من مورّد، تحصيلُ طلبيةٍ من عميل — وبما بقي في الخزينة بعده.
 *
 * ## ما يقف، لا خطواتُ الحساب
 *
 * التصحيحُ هنا صفٌّ عكسيّ يُبطل صفّاً — وأكثرُه ليس خطأ أحد: {@see PostFundProceedsForOrder}
 * يعكس تحصيلَ الطلبية ويكتبه من جديد بالمجموع كلّما دفع العميلُ دفعة. فطلبيةٌ على ثلاث دفعاتٍ
 * كانت ستملأ السجلَّ بخمسة صفوفٍ يُلغي بعضُها بعضاً ليقول رقماً واحداً.
 *
 * فالسجلُّ يعرض **الصفوفَ القائمة**: ما ليس عكساً ولم يُعكس. والعكسُ يساوي أصلَه تماماً، فمجموعُ
 * القائم هو مجموعُ الدفتر كلِّه — أي {@see FundCash} بعينه، ورصيدُ آخر صفٍّ هو نقدُ اللوحة.
 *
 * ## والرصيدُ الجاري يُحسب على الدفتر كلِّه ثم يُقطَّع
 *
 * رصيدُ الصفّ هو ما كان في الخزينة بعده، وهو لا يُعرف إلا بمشي كلِّ ما قبله. فالصفحةُ الثانية
 * لا تبدأ من صفر — تُحسب الأرصدةُ للكلّ من الأقدم، ثم تُقطع الصفحةُ من الأحدث. مشيٌ في PHP
 * كـ{@see FundCash}، لأن الاتجاهَ يسكن النوعَ ({@see CashEntryType::isInflow()})، وكتابتُه
 * `CASE` في SQL نسخةٌ ثانية تفترق عنه أوّلَ ما يُضاف نوع.
 */
final class FundCashLedger
{
    public const PER_PAGE = 30;

    /**
     * @return array{
     *     rows: list<array<string, mixed>>,
     *     balance: string,
     *     current_page: int,
     *     per_page: int,
     *     last_page: int,
     *     total: int
     * }
     */
    public function page(int $page, int $perPage = self::PER_PAGE): array
    {
        $standing = InvestmentCashEntry::query()
            ->where('type', '<>', CashEntryType::Reversal->value)
            ->whereDoesntHave('reversedBy')
            ->orderBy('occurred_at')
            ->orderBy('id')
            ->get();

        $balance = '0';
        $after = [];

        foreach ($standing as $entry) {
            $balance = bcadd($balance, $entry->signedAmount(), 8);
            $after[(int) $entry->getKey()] = Money::round($balance);
        }

        $total = $standing->count();
        $lastPage = max(1, (int) ceil($total / $perPage));

        /** @var Collection<int, InvestmentCashEntry> $slice */
        $slice = $standing->reverse()->values()->slice(($page - 1) * $perPage, $perPage)->values();

        $sources = $this->sourcesOf($slice);

        $rows = [];

        foreach ($slice as $entry) {
            $source = $sources[(string) $entry->source_type][(int) $entry->source_id] ?? [];

            $rows[] = [
                'id' => (int) $entry->getKey(),
                'type' => $entry->type->value,
                'type_label' => $entry->type->label(),
                'is_inflow' => $entry->type->isInflow(),
                'amount' => (string) $entry->amount,
                'signed_amount' => $entry->signedAmount(),
                'balance_after' => $after[(int) $entry->getKey()],
                'occurred_at' => $entry->occurred_at?->toIso8601String(),
                'description' => $source['description'] ?? null,
                'order_id' => $source['order_id'] ?? null,
                'purchase_order_id' => $source['purchase_order_id'] ?? null,
                'investor_id' => $source['investor_id'] ?? null,
                'notes' => $entry->notes,
            ];
        }

        return [
            'rows' => $rows,
            'balance' => Money::round($balance),
            'current_page' => $page,
            'per_page' => $perPage,
            'last_page' => $lastPage,
            'total' => $total,
        ];
    }

    /**
     * ما يسمّيه مصدرُ كلِّ صفٍّ في الصفحة — استعلامٌ لكل نوعِ مصدر، لا لكل صفّ.
     *
     * **ولا تُصفّى المحذوفةُ ناعماً هنا.** صفُّ الخزينة قائمٌ ومالُه تحرّك؛ مصدرٌ حُذف بعده ما زال
     * هو ما جاء منه المال، واسمُه أصدقُ من سطرٍ فارغ.
     *
     * @param  Collection<int, InvestmentCashEntry>  $entries
     * @return array<string, array<int, array{description: ?string, order_id?: int, purchase_order_id?: int, investor_id?: int}>>
     */
    private function sourcesOf(Collection $entries): array
    {
        $ids = [];

        foreach ($entries as $entry) {
            if ($entry->source_type !== null && $entry->source_id !== null) {
                $ids[(string) $entry->source_type][(int) $entry->source_id] = (int) $entry->source_id;
            }
        }

        $described = [];

        // إيداعٌ وسحبٌ وتحويلُ صفقة: صفُّ محفظةٍ يسمّي صاحبَه.
        if ($walletIds = array_values($ids[AuditSubject::InvestorWalletEntry->value] ?? [])) {
            $rows = DB::table('investor_wallet_entries as w')
                ->join('investors as i', 'i.id', '=', 'w.investor_id')
                ->whereIn('w.id', $walletIds)
                ->get(['w.id', 'i.id as investor_id', 'i.name']);

            foreach ($rows as $row) {
                $described[AuditSubject::InvestorWalletEntry->value][(int) $row->id] = [
                    'description' => (string) $row->name,
                    'investor_id' => (int) $row->investor_id,
                ];
            }
        }

        if ($purchaseIds = array_values($ids[AuditSubject::PurchaseOrder->value] ?? [])) {
            $rows = DB::table('purchase_orders as po')
                ->leftJoin('vendors as v', 'v.id', '=', 'po.vendor_id')
                ->whereIn('po.id', $purchaseIds)
                ->get(['po.id', 'v.name as vendor_name']);

            foreach ($rows as $row) {
                $described[AuditSubject::PurchaseOrder->value][(int) $row->id] = [
                    'description' => $this->joined('أمر شراء #'.$row->id, $row->vendor_name),
                    'purchase_order_id' => (int) $row->id,
                ];
            }
        }

        if ($orderIds = array_values($ids[AuditSubject::Order->value] ?? [])) {
            foreach ($this->orders(DB::table('orders as o')->whereIn('o.id', $orderIds), 'o.id') as $id => $order) {
                $described[AuditSubject::Order->value][$id] = $order;
            }
        }

        // ثمنُ سادةٍ اشترتها المطبعة: مصدرُه سطرُ الطلبية التي سحبتها.
        if ($lineIds = array_values($ids[AuditSubject::OrderItem->value] ?? [])) {
            $query = DB::table('order_items as oi')
                ->join('orders as o', 'o.id', '=', 'oi.order_id')
                ->whereIn('oi.id', $lineIds);

            foreach ($this->orders($query, 'oi.id') as $id => $order) {
                $described[AuditSubject::OrderItem->value][$id] = $order;
            }
        }

        // …أو حركةُ تالفٍ خرج لطلبية. `reference_id` آمنٌ على `scrap_loss` وحدها: كاتبُها واحد
        // (`RecordScrapLoss`) ويختم الطلبيةَ دائماً — القاعدةُ نفسُها في {@see PeriodOrdersQuery}.
        if ($movementIds = array_values($ids[AuditSubject::StockMovement->value] ?? [])) {
            $query = DB::table('stock_movements as m')
                ->join('orders as o', 'o.id', '=', 'm.reference_id')
                ->where('m.movement_type', 'scrap_loss')
                ->whereIn('m.id', $movementIds);

            foreach ($this->orders($query, 'm.id') as $id => $order) {
                $described[AuditSubject::StockMovement->value][$id] = $order;
            }
        }

        if ($expenseIds = array_values($ids[AuditSubject::InvestorDealExpense->value] ?? [])) {
            foreach (DB::table('investor_deal_expenses')->whereIn('id', $expenseIds)->pluck('name', 'id') as $id => $name) {
                $described[AuditSubject::InvestorDealExpense->value][(int) $id] = ['description' => (string) $name];
            }
        }

        if ($periodIds = array_values($ids[AuditSubject::InvestmentPeriod->value] ?? [])) {
            foreach (DB::table('investment_periods')->whereIn('id', $periodIds)->pluck('code', 'id') as $id => $code) {
                $described[AuditSubject::InvestmentPeriod->value][(int) $id] = ['description' => 'الفترة '.$code];
            }
        }

        return $described;
    }

    /**
     * «طلبية ORD-12 · محمد» لكلّ مفتاحٍ في الاستعلام — المفتاحُ عمودُ المصدر لا عمودُ الطلبية.
     *
     * @return array<int, array{description: string, order_id: int}>
     */
    private function orders(Builder $query, string $key): array
    {
        $rows = $query
            ->leftJoin('customers as cu', 'cu.id', '=', 'o.customer_id')
            ->get([$key.' as source_id', 'o.id as order_id', 'o.code', 'cu.name as customer_name']);

        $out = [];

        foreach ($rows as $row) {
            $out[(int) $row->source_id] = [
                'description' => $this->joined('طلبية '.$row->code, $row->customer_name),
                'order_id' => (int) $row->order_id,
            ];
        }

        return $out;
    }

    /** الشيءُ ثم صاحبُه إن عُرف — «أمر شراء #3 · مصنع الأكياس». */
    private function joined(string $what, ?string $who): string
    {
        return $who === null || $who === '' ? $what : $what.' · '.$who;
    }
}
