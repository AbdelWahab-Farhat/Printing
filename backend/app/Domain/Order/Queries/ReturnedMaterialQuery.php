<?php

declare(strict_types=1);

namespace App\Domain\Order\Queries;

use App\Domain\Order\Models\OrderItem;

/**
 * The lines of a cancelled order whose material went back to a shelf — and whether the press ran
 * each of them.
 *
 * A third seam beside {@see ProfitAttributionQuery} and {@see StockPurchaseAttributionQuery}, and a
 * separate one for the same reason they are separate: each answers for one thing a caller needs,
 * and a caller has no business reading the others' figures. This one carries no money at all.
 *
 * **`is_printed` is the field that matters**, and it is the line's own answer
 * ({@see OrderItem::isPrinted()}) rather than the order's. `ResolveOrderFlow` puts a whole order on
 * the printing road for one printed line among five plain ones — right for the road, wrong for this
 * question: a سادة line inside a printed order was still never printed, and its material comes back
 * exactly as it left.
 *
 * **The draw is still named even though the order is cancelled.** `fulfillment_stock_movement_id`
 * is deliberately not cleared by the reversal — the movement is history, and the credit-back points
 * at it — so this remains the way to find what each line actually took.
 */
final class ReturnedMaterialQuery
{
    /**
     * @return list<array{line_id: int, movement_id: int, stock_item_id: ?int, is_printed: bool}>
     */
    public function __invoke(int $orderId): array
    {
        return OrderItem::query()
            ->where('order_id', $orderId)
            ->whereNotNull('fulfillment_stock_movement_id')
            // `product.productCategory.parent` is what {@see OrderItem::isPrinted()} walks, and
            // strict mode turns a forgotten load into an exception rather than a query per line —
            // so the load is here, where the read is, and not left to a caller to remember.
            ->with(['variant', 'product.productCategory.parent'])
            ->orderBy('id')
            ->get()
            ->map(fn (OrderItem $item): array => [
                'line_id' => (int) $item->getKey(),
                'movement_id' => (int) $item->fulfillment_stock_movement_id,
                'stock_item_id' => $item->variant?->stock_item_id === null
                    ? null
                    : (int) $item->variant->stock_item_id,
                'is_printed' => $item->isPrinted(),
            ])
            ->filter(fn (array $line): bool => $line['stock_item_id'] !== null)
            ->values()
            ->all();
    }
}
