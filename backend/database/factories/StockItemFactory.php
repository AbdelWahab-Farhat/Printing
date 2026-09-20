<?php

namespace Database\Factories;

use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockItemGroup;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<StockItem>
 */
class StockItemFactory extends Factory
{
    /** @var class-string<StockItem> */
    protected $model = StockItem::class;

    /**
     * Sequence-generated, not random: `(name, width_cm, height_cm)` carries a unique index, and a
     * chance collision failing an unrelated test is a miserable bug to find. RULES.md §6.
     */
    private static int $sequence = 0;

    /**
     * The next free size, shared with {@see ProductVariantFactory}.
     *
     * **One counter, because there is one unique index.** A variant mints its own shelf at its own
     * label's size, so a second counter over there produced the same `(name, width, height)` pair
     * this one had already used — and any test that created a bare shelf *and* a variant died on
     * `stock_items_name_size_unique` with nothing in the message to say why. The two sequences were
     * independent; the constraint they both feed is not.
     *
     * Still wrapped at 40 so sizes stay legible in a failure message. That is safe now: within one
     * process the pair is drawn once and never reissued until the wrap, and a wrap needs 40 shelves
     * in a single test.
     *
     * @return array{int, int}
     */
    public static function nextSize(): array
    {
        $width = 20 + (++self::$sequence % 40);

        return [$width, $width + 10];
    }

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        [$width, $height] = self::nextSize();

        return [
            'name' => 'كيس شحن',
            'width_cm' => $width,
            'height_cm' => $height,
            'unit' => PricingUnit::Piece,
            'description' => null,
            'is_active' => true,
            'sort_order' => 0,
        ];
    }

    public function named(string $name): static
    {
        return $this->state(fn () => ['name' => $name]);
    }

    public function size(int $width, int $height): static
    {
        return $this->state(fn () => ['width_cm' => $width, 'height_cm' => $height]);
    }

    /** A shelf with no dimensions — a roll, an ink, anything counted without a size. */
    public function unsized(): static
    {
        return $this->state(fn () => ['width_cm' => null, 'height_cm' => null]);
    }

    public function unit(PricingUnit $unit): static
    {
        return $this->state(fn () => ['unit' => $unit]);
    }

    /** Weighed rather than counted, so fractional movements off it are legal. */
    public function weighed(): static
    {
        return $this->state(fn () => ['unit' => PricingUnit::Kilogram]);
    }

    /**
     * Filed under a material, taking its name — which is what a grouped item always does.
     *
     * The factory leaves items ungrouped by default: a standalone shelf is a real thing, and a
     * test that is not about materials should not have to invent one.
     */
    public function inGroup(StockItemGroup $group): static
    {
        return $this->state(fn () => [
            'stock_item_group_id' => $group->getKey(),
            'name' => $group->name,
        ]);
    }
}
