<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One cancelled line's material, waiting for somebody to say whether it survived the press.
 *
 * **`cost` is what the answer is worth**, and the screen should show it: «تالفة» charges exactly
 * this to the pool and takes the goods off the shelf, so the person answering is deciding a figure
 * and not merely ticking a box.
 *
 * `quantity` and `cost` were read off the credit-back the day the question was raised, not now —
 * the shelf has moved on since, and the answer has to be about what actually came back.
 *
 * `damage_movement_id` is the difference between «we checked» and «something happened»: «صالحة»
 * leaves it null, because the goods really are back and really are usable.
 *
 * @mixin InvestmentReturnedGoodsQuestion
 */
class InvestmentReturnedGoodsQuestionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'investment_pool_id' => (int) $this->investor_deal_id,

            'order_id' => (int) $this->order_id,
            'order_item_id' => (int) $this->order_item_id,
            'order_code' => $this->whenLoaded('order', fn (): ?string => $this->order?->code),

            'stock_item_id' => (int) $this->stock_item_id,
            'stock_item_name' => $this->whenLoaded('stockItem', fn (): ?string => $this->stockItem?->name),

            'quantity' => (string) $this->quantity,
            'cost' => (string) $this->cost,

            'verdict' => $this->verdict->value,
            'verdict_label' => $this->verdict->label(),
            // What a list screen filters on and what a close screen counts. Both ask the same
            // question the period's guard asks, so all three agree by construction.
            'is_open' => $this->isOpen(),

            'answered_at' => $this->answered_at?->toIso8601String(),
            'answered_by' => $this->answered_by,
            'answered_by_name' => $this->whenLoaded('answeredBy', fn (): ?string => $this->answeredBy?->name),

            'damage_movement_id' => $this->damage_movement_id,

            'notes' => $this->notes,
        ];
    }
}
