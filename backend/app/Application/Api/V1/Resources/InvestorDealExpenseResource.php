<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestorDealExpense;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One cost charged to a صندوق or a صفقة.
 *
 * **`is_deducted` is the field a screen must lead with**, not `amount`. Shipping and customs typed
 * on a purchase order are already inside the cost of the layers that arrived — they are recorded
 * here and **not subtracted**, because subtracting them again would charge the partners for one
 * customs invoice twice. A list that prints every amount the same way invites somebody to add them
 * up and get a number the close does not use.
 *
 * `investment_period_id` is which period actually bore it, and it is not always the period the date
 * falls in: a closed period is immutable, so an invoice bearing last month's date is charged to the
 * one that is open now and keeps its true `incurred_on`.
 *
 * @mixin InvestorDealExpense
 */
class InvestorDealExpenseResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'investor_deal_id' => (int) $this->investor_deal_id,
            'investment_period_id' => $this->investment_period_id,

            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),

            'name' => $this->name,
            'amount' => (string) $this->amount,

            /** Recorded and **not** subtracted — «محسوبة مسبقاً». */
            'is_landed' => (bool) $this->is_landed,

            /** Whether the close actually takes this off the period's profit. */
            'is_deducted' => $this->isDeducted(),

            'incurred_on' => $this->incurred_on?->toDateString(),

            /** A correction undoes by a further row; neither side is deducted afterwards. */
            'reverses_expense_id' => $this->reverses_expense_id,
            'is_reversed' => $this->isReversed(),

            'notes' => $this->notes,
            'recorded_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
