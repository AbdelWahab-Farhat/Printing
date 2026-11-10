<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Support;

use App\Domain\PurchaseOrder\Actions\AllocatePurchaseOrderAdditionalCosts;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\PurchaseOrder\Models\PurchaseOrderItem;
use Illuminate\Support\Collection;

/**
 * Each line's whole share of the dinar costs planned on a dollar order — customs out of a dinar
 * drawer, typed before the goods arrived (USD-ACCOUNTS.md §٧).
 *
 * Spread as {@see AllocatePurchaseOrderAdditionalCosts} spreads the order's own costs: by each
 * line's base cost over what was ordered, in cents. The dollar costs are already on the lines;
 * these are not, because a dinar cannot join a dollar line — so the receipt adds them to the
 * stock, and the funding screen to what a funded line costs in dinars. One place, so the two
 * always agree.
 */
final class PlannedDinarShares
{
    /**
     * @param  Collection<int, PurchaseOrderItem>  $items
     * @return array<int, string> Cents per line id — empty on a dinar order.
     */
    public static function of(PurchaseOrder $order, Collection $items): array
    {
        if (! $order->isDollar() || $items->isEmpty()) {
            return [];
        }

        $amounts = $order->additionalCosts()
            ->whereNull('stock_arrival_id')
            ->where('currency', '<>', $order->currency->value)
            ->get()
            ->map(fn (PurchaseOrderAdditionalCost $cost) => (string) $cost->amount)
            ->all();

        if ($amounts === []) {
            return [];
        }

        return LargestRemainder::split(
            LargestRemainder::toCents(Money::sum(...$amounts)),
            $items->mapWithKeys(fn (PurchaseOrderItem $item) => [
                $item->getKey() => LargestRemainder::toCents((string) ($item->base_total_cost ?? '0')),
            ])->all(),
        );
    }

    /**
     * What a funded dollar line cost in dinars at the funding rate: its dollars times the rate,
     * and its share of the dinar costs as it is. Unrounded — the callers round to their own
     * precision.
     *
     * @param  string  $dinarShareCents  From {@see of()}.
     */
    public static function fundedLineCost(PurchaseOrderItem $item, string $rate, string $dinarShareCents): string
    {
        return bcadd(
            bcmul((string) ($item->final_total_cost ?? '0'), $rate, 10),
            LargestRemainder::fromCents($dinarShareCents),
            10,
        );
    }
}
