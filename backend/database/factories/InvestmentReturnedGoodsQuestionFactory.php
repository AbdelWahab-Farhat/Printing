<?php

namespace Database\Factories;

use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InvestmentReturnedGoodsQuestion>
 */
class InvestmentReturnedGoodsQuestionFactory extends Factory
{
    /** @var class-string<InvestmentReturnedGoodsQuestion> */
    protected $model = InvestmentReturnedGoodsQuestion::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'investor_deal_id' => InvestorDeal::factory()->pool(),
            'order_id' => Order::factory(),
            'order_item_id' => OrderItem::factory(),
            'stock_item_id' => StockItem::factory(),
            'quantity' => '100.000',
            'cost' => '1000.00',
            'verdict' => ReturnedGoodsVerdict::Open,
        ];
    }
}
