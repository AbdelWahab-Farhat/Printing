<?php

namespace Database\Factories;

use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\Models\InvestmentPoolItem;
use App\Domain\Investor\Models\InvestorDeal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentPoolItem>
 */
class InvestmentPoolItemFactory extends Factory
{
    /** @var class-string<InvestmentPoolItem> */
    protected $model = InvestmentPoolItem::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investor_deal_id' => InvestorDeal::factory()->pool(),
            'stock_item_id' => StockItem::factory(),
        ];
    }
}
