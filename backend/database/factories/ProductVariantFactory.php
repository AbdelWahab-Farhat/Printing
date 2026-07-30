<?php

namespace Database\Factories;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProductVariant>
 */
class ProductVariantFactory extends Factory
{
    /** @var class-string<ProductVariant> */
    protected $model = ProductVariant::class;

    /** A label is unique per product; a counter keeps generated ones from colliding. */
    private static int $labelSequence = 0;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $width = 20 + (++self::$labelSequence % 40);
        $height = $width + 10;

        return [
            'product_id' => Product::factory(),
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
}
