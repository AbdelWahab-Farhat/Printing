<?php

namespace Database\Factories;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Inventory\Models\WarehouseStock;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<WarehouseStock>
 */
class WarehouseStockFactory extends Factory
{
    /** @var class-string<WarehouseStock> */
    protected $model = WarehouseStock::class;

    /**
     * Note this writes `quantity` directly, which nothing in `app/` may do.
     *
     * That is the point of a factory: a test arranging "a shelf with 500 on it" should say so in
     * one line rather than recording an arrival to get there. The tests that care whether the
     * ledger and the balance agree build their state through the API instead — see
     * `StockLedgerTest`.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'warehouse_id' => Warehouse::factory(),
            'product_variant_id' => ProductVariant::factory(),
            'quantity' => '100.000',
            'low_stock_threshold' => null,
            'unit' => PricingUnit::Piece,
        ];
    }

    public function quantity(string $quantity): static
    {
        return $this->state(fn () => ['quantity' => $quantity]);
    }

    public function unit(PricingUnit $unit): static
    {
        return $this->state(fn () => ['unit' => $unit]);
    }

    /** A size that was here and has all been used up — the line stays, at zero. */
    public function empty(): static
    {
        return $this->state(fn () => ['quantity' => '0.000']);
    }

    public function warnAt(string $threshold): static
    {
        return $this->state(fn () => ['low_stock_threshold' => $threshold]);
    }
}
