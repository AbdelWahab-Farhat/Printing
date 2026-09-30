<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Queries;

use App\Domain\Inventory\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * What the goods on the shelves are worth at what they cost — Σ remaining × unit cost over every
 * live batch, the same FIFO layers orders are costed from. TREASURY-DESIGN §٩.
 *
 * **Not an account.** Stock has its own ledger and this is its total; a ledger account for it
 * would only ever copy this figure. Split three ways so the owner can read it: by warehouse,
 * between the company's own stock and the fund's (`investor_deal_id`), and the most valuable
 * items first.
 */
final class InventoryValueQuery
{
    /**
     * @return array{
     *     total: string,
     *     company: string,
     *     fund: string,
     *     by_warehouse: list<array{warehouse_id: int, name: string, value: string}>,
     *     top_items: list<array{stock_item_id: int, name: string, code: string, quantity: string, value: string}>
     * }
     */
    public function __invoke(int $topItems = 10): array
    {
        $live = fn () => DB::table('stock_batches as b')
            ->whereNull('b.deleted_at')
            ->where('b.quantity_remaining', '>', 0);

        $owners = $live()
            ->selectRaw('(b.investor_deal_id IS NOT NULL) AS for_fund, SUM(b.quantity_remaining * b.unit_cost) AS value')
            ->groupByRaw('(b.investor_deal_id IS NOT NULL)')
            ->get();

        $company = '0';
        $fund = '0';

        foreach ($owners as $row) {
            $row->for_fund ? $fund = (string) $row->value : $company = (string) $row->value;
        }

        $byWarehouse = $live()
            ->join('warehouses as w', 'w.id', '=', 'b.warehouse_id')
            ->selectRaw('w.id AS warehouse_id, w.name, SUM(b.quantity_remaining * b.unit_cost) AS value')
            ->groupBy('w.id', 'w.name')
            ->orderByDesc('value')
            ->get()
            ->map(fn ($row) => [
                'warehouse_id' => (int) $row->warehouse_id,
                'name' => (string) $row->name,
                'value' => Money::round((string) $row->value),
            ])
            ->values()
            ->all();

        $top = $live()
            ->join('stock_items as s', 's.id', '=', 'b.stock_item_id')
            ->selectRaw('s.id AS stock_item_id, s.name, s.code, SUM(b.quantity_remaining) AS quantity, SUM(b.quantity_remaining * b.unit_cost) AS value')
            ->groupBy('s.id', 's.name', 's.code')
            ->orderByDesc('value')
            ->limit($topItems)
            ->get()
            ->map(fn ($row) => [
                'stock_item_id' => (int) $row->stock_item_id,
                'name' => (string) $row->name,
                'code' => (string) $row->code,
                'quantity' => bcadd((string) $row->quantity, '0', 3),
                'value' => Money::round((string) $row->value),
            ])
            ->values()
            ->all();

        return [
            'total' => Money::round(bcadd($company, $fund, 8)),
            'company' => Money::round($company),
            'fund' => Money::round($fund),
            'by_warehouse' => $byWarehouse,
            'top_items' => $top,
        ];
    }
}
