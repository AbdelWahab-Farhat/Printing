<?php

declare(strict_types=1);

namespace App\Domain\Order\Support;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\InventoryService;
use App\Domain\Order\DTOs\OrderItemData;
use App\Domain\Order\Exceptions\InstantOrderRefused;
use Illuminate\Support\Collection;

/**
 * «هل يكفي ما على الرف؟» for an instant sale — asked under a lock, inside the transaction that
 * then takes the stock (INSTANT-ORDERS-PLAN.md §4).
 *
 * - Lines asking for the same shelf are added together before comparing: two lines of 6 kg
 *   against a shelf of 10 kg is a shortfall, not two sales that each fit.
 * - Every short product is named in one refusal, in the plan's own form:
 *   «أكياس شحن 35×40 — مخزن بريمولا: المطلوب 10 كجم، المتاح 7 كجم».
 * - The balance rows stay locked until the caller's transaction ends, so a second counter selling
 *   the same last bags waits and then reads what this sale left.
 */
final class InstantOrderStock
{
    public function __construct(private readonly InventoryService $inventory) {}

    /**
     * @param  list<OrderItemData>  $items
     * @param  Collection<int, Product>  $products  keyed by id, loaded with
     *                                              {@see InstantSaleEligibility::RELATIONS}
     * @param  array<int, string>  $credit  stock already drawn by this same order, per stock
     *                                      item — what an edit gets back before it draws again
     *
     * @throws InstantOrderRefused
     */
    public function assertAvailable(
        array $items,
        Collection $products,
        int $warehouseId,
        array $credit = [],
    ): void {
        /** @var array<int, array{required: string, product: Product, variant: ProductVariant}> $needs */
        $needs = [];

        foreach ($items as $item) {
            $product = $products->get($item->productId);
            $variant = $product?->variants->firstWhere('id', $item->productVariantId);
            $stockItemId = $variant?->stock_item_id;

            if ($product === null || $variant === null || $stockItemId === null) {
                continue;
            }

            $stockItemId = (int) $stockItemId;
            $needs[$stockItemId] ??= ['required' => '0', 'product' => $product, 'variant' => $variant];
            $needs[$stockItemId]['required'] = bcadd($needs[$stockItemId]['required'], $item->quantity, 3);
        }

        $ids = array_keys($needs);
        sort($ids);

        $balances = $this->inventory->lockedBalancesFor($warehouseId, $ids);
        $warehouse = $this->inventory->warehouseName($warehouseId) ?? 'المخزن';

        $short = [];

        foreach ($ids as $stockItemId) {
            $need = $needs[$stockItemId];
            $available = bcadd($balances[$stockItemId] ?? '0', $credit[$stockItemId] ?? '0', 3);

            if (bccomp($need['required'], $available, 3) > 0) {
                $unit = $need['product']->pricing_unit->label();
                $name = trim($need['product']->name.' '.$need['variant']->label);

                $short[] = sprintf(
                    '%s — %s: المطلوب %s %s، المتاح %s %s',
                    $name,
                    $warehouse,
                    self::figure($need['required']),
                    $unit,
                    self::figure($available),
                    $unit,
                );
            }
        }

        if ($short !== []) {
            throw InstantOrderRefused::shortfall($short);
        }
    }

    /** «10.000» → «10», «7.500» → «7.5». */
    public static function figure(string $quantity): string
    {
        $fixed = bcadd($quantity, '0', 3);

        return str_contains($fixed, '.') ? rtrim(rtrim($fixed, '0'), '.') : $fixed;
    }
}
