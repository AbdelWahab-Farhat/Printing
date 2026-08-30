<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Catalog\Models\ProductCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProductCategory>
 */
class ProductCategoryFactory extends Factory
{
    protected $model = ProductCategory::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            // Unique per row: the partial index refuses two live categories with one name, and
            // a fixed value here would fail the second `create()` in any test making two.
            'name' => 'تصنيف '.$this->faker->unique()->numberBetween(1, 100_000),
            'description' => null,
            'is_active' => true,
            'sort_order' => 0,
            // The road every order took before flows existed, which is what an unremarkable
            // category should still mean.
            'skips_production' => false,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }

    /**
     * Goods that are already made — the catalogue's «سادة».
     *
     * An order made only of these walks جديدة → جاهزة; see `ResolveOrderFlow`.
     */
    public function skipsProduction(): static
    {
        return $this->state(fn () => ['skips_production' => true]);
    }
}
