<?php

namespace Database\Factories;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Models\StockItem;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProductVariant>
 */
class ProductVariantFactory extends Factory
{
    /** @var class-string<ProductVariant> */
    protected $model = ProductVariant::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        // Drawn from {@see StockItemFactory} rather than from a counter of its own. A label is
        // unique per product, which a local counter handled; the **shelf** this then mints at the
        // same size is unique across the whole table, which it did not — two independent sequences
        // issued the same `(name, width, height)` pair, and a test that created a bare shelf beside
        // a variant died on `stock_items_name_size_unique` for no reason it could see.
        [$width, $height] = StockItemFactory::nextSize();

        return [
            'product_id' => Product::factory(),
            // Its own shelf by default, at the same size. Tests about *sharing* — two products
            // drawing on one pile — pass an explicit item with `drawingFrom()`, which is the
            // whole point of making that state say so out loud.
            'stock_item_id' => StockItem::factory()->size($width, $height),
            'label' => "{$width}*{$height}",
            'width_cm' => $width,
            'height_cm' => $height,
            'is_active' => true,
            'sort_order' => 0,
        ];
    }

    public function size(int $width, int $height): static
    {
        return $this->state(fn () => [
            'label' => "{$width}*{$height}",
            'width_cm' => $width,
            'height_cm' => $height,
        ]);
    }

    /**
     * Point this size at a shelf that already exists.
     *
     * How a test says «كيس شحن سادة 25*35 و كيس شحن مطبوع 25*35 نفس الكومة»: two variants of two
     * different products, one stock item, one balance between them.
     */
    public function drawingFrom(StockItem $item): static
    {
        return $this->state(fn () => ['stock_item_id' => $item->getKey()]);
    }

    /** A size that is never stocked — a quote-only product's. Every stock path refuses it. */
    public function unstocked(): static
    {
        return $this->state(fn () => ['stock_item_id' => null]);
    }
}
