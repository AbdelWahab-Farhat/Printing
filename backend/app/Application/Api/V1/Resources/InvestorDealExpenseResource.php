<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Queries\GoodsExpenseCharges;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * مصروفٌ على صفقةٍ أو على الصندوق — أو عكسُه.
 *
 * `is_reversal` و`is_reversed` و`reverses_expense_id` يقولها الخادم، فيعرف التطبيقُ أيُّ صفٍّ
 * يُعرض له زرُّ العكس بدل أن يخمّن.
 *
 * @mixin InvestorDealExpense
 */
class InvestorDealExpenseResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'investor_deal_id' => $this->investor_deal_id,

            'kind' => $this->kind->value,
            'kind_label' => $this->kind->label(),
            'name' => $this->name,
            'amount' => (string) $this->amount,
            'is_landed' => (bool) $this->is_landed,
            'incurred_on' => $this->incurred_on?->toDateString(),
            'notes' => $this->notes,

            'treasury_account_id' => $this->treasury_account_id,
            'treasury_account' => $this->whenLoaded('treasuryAccount', fn () => $this->account()),

            'is_reversal' => $this->resource->isReversal(),
            'is_reversed' => $this->resource->isReversed(),
            'reverses_expense_id' => $this->reverses_expense_id,
            // A purchase order's arrival cost on a funded line: it follows its receipt and is not
            // reversed from here — the screen hides the button rather than meeting the refusal.
            'source_type' => $this->source_type,
            'source_id' => $this->source_id,

            // **مصروفٌ على البضاعة** — Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md: طلبُ الشراء
            // الذي تحمله بضاعتُه، وكيف انقسم يومَ سُجِّل.
            'purchase_order' => $this->purchase_order_id === null ? null : ['id' => (int) $this->purchase_order_id],
            'split' => $this->purchase_order_id === null
                ? null
                : (app(GoodsExpenseCharges::class)->splitOf([(int) $this->id])[(int) $this->id]
                    ?? ['on_goods' => '0.00', 'on_sales' => '0.00']),

            'recorded_by' => $this->recorded_by,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * @return array{id: int, name: string}|null
     */
    private function account(): ?array
    {
        $account = $this->treasuryAccount;

        if ($account === null) {
            return null;
        }

        return ['id' => (int) $account->id, 'name' => (string) $account->name];
    }
}
