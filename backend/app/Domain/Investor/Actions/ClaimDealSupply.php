<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Exceptions\DealIsNotEditable;
use App\Domain\Investor\Exceptions\StockItemIsNotInvestable;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealSupply;

/**
 * Declares, before the lorry arrives, that a purchase order's line is financed by this deal.
 *
 * The whole of «الموظف لا يختار الصفقة أبداً»: the decision is made here, by whoever runs the
 * deals, and the receiving screen never grows a field. `ReceivePurchaseOrder` asks one question
 * per line at receipt and stamps whatever comes back onto the cost layer it opens.
 */
final class ClaimDealSupply
{
    /**
     * @param  string|null  $printingSalePrice  سعر السادة لهذا السطر — أو null فيسقط إلى سعر صفقته
     */
    public function __invoke(
        InvestorDeal $deal,
        int $sourceId,
        int $stockItemId,
        ?int $actorId,
        ?string $printingSalePrice = null,
    ): InvestorDealSupply {
        if ($deal->status !== DealStatus::Open) {
            throw DealIsNotEditable::make((string) $deal->code);
        }

        // A shelf the deal does not fund is not a shelf it may claim goods for.
        $onTheDeal = $deal->items()->where('stock_item_id', $stockItemId)->exists();

        if (! $onTheDeal) {
            throw StockItemIsNotInvestable::make('هذه المادة ليست ضمن مواد الصفقة');
        }

        $supply = new InvestorDealSupply;

        $supply->investor_deal_id = $deal->getKey();
        $supply->source_type = AuditSubject::PurchaseOrder->value;
        $supply->source_id = $sourceId;
        $supply->stock_item_id = $stockItemId;
        // **Frozen here, on the row, and never read live afterwards.** A man puts his money in
        // knowing what his goods sell to the press at; a price looked up at the moment stock
        // left the shelf would move under goods already bought and paid for.
        $supply->printing_sale_price = $printingSalePrice;
        $supply->claimed_by = $actorId;
        $supply->save();

        return $supply;
    }
}
