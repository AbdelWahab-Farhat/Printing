<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductPriceTier;
use App\Domain\Catalog\Models\ProductVariant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A product as the instant-order picker shows it: its eligible sizes, their price tiers, and how
 * much the branch's warehouse holds of each (INSTANT-ORDERS-PLAN.md §3).
 *
 * No cost, no images, no category: a branch employee does not hold `products.view`, and the
 * picker needs only what it shows. The tiers let the app show a line's price as it is typed; the
 * server prices the order itself when it is taken.
 *
 * @mixin Product
 */
class InstantProductResource extends JsonResource
{
    /** @var array<int, string> */
    private array $available = [];

    /**
     * @param  array<int, string>  $available  per stock item id
     */
    public function withAvailability(array $available): self
    {
        $this->available = $available;

        return $this;
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => (int) $this->id,
            'name' => (string) $this->name,
            'pricing_unit' => $this->pricing_unit->value,
            'unit_label' => $this->pricing_unit->label(),
            'min_order_quantity' => (string) $this->min_order_quantity,
            'variants' => $this->variants->map(fn (ProductVariant $variant): array => [
                'id' => (int) $variant->id,
                'label' => (string) $variant->label,
                'stock_item_id' => (int) $variant->stock_item_id,
                'available_quantity' => $this->available[(int) $variant->stock_item_id] ?? '0.000',
                'price_tiers' => $variant->priceTiers->map(fn (ProductPriceTier $tier): array => [
                    'min_quantity' => (string) $tier->min_quantity,
                    'unit_price' => (string) $tier->unit_price,
                ])->values()->all(),
            ])->values()->all(),
        ];
    }
}
