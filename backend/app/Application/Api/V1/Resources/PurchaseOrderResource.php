<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\PurchaseOrder\Enums\PurchaseOrderStatus;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Vendor\Actions\ReverseStockArrival;
use App\Domain\Vendor\Models\StockArrival;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PurchaseOrder
 */
class PurchaseOrderResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            'vendor_id' => $this->vendor_id,
            'vendor' => $this->whenLoaded('vendor', fn (): array => [
                'id' => $this->vendor->id,
                'name' => $this->vendor->name,
            ]),

            'warehouse_id' => $this->warehouse_id,
            'warehouse' => $this->whenLoaded(
                'warehouse',
                fn (): ?array => $this->warehouse === null ? null : [
                    'id' => $this->warehouse->id,
                    'name' => $this->warehouse->name,
                ],
            ),

            'status' => $this->status->value,
            'status_label' => $this->status->label(),

            // Every amount below is in it — USD-ACCOUNTS.md §٤.
            'currency' => $this->currency->value,
            // Dinars per dollar the stock was priced at, once received (§٥); null otherwise.
            'arrival_rate' => $this->arrival_rate === null ? null : (string) $this->arrival_rate,
            // Dinars per dollar the funded lines were bought at; null until it is funded.
            'funding_rate' => $this->funding_rate === null ? null : (string) $this->funding_rate,
            // The two rates disagree — said on the order, and nothing else is written (the owner's
            // decision, 2026-11-10). Null when they agree or either is missing.
            'rate_difference' => $this->rateDifference(),
            // «سعر النظام», which the receive screen opens its rate field on — a dollar order's
            // alone, and null until the owner writes one.
            'system_usd_rate' => $this->when(
                $this->isDollar(),
                fn (): ?string => ($rate = app(TreasuryService::class)->settings()->usd_rate) === null ? null : (string) $rate,
            ),

            'order_date' => $this->order_date?->toDateString(),
            'expected_date' => $this->expected_date?->toDateString(),
            'notes' => $this->notes,

            // Null on an order raised before cost tracking existed — see RecalculatePurchaseOrderTotal.
            // Already inclusive of total_additional_cost: each line's final_total_cost (summed
            // into this figure) already carries its allocated share.
            'total_amount' => $this->total_amount !== null ? (string) $this->total_amount : null,
            'total_additional_cost' => $this->total_additional_cost !== null ? (string) $this->total_additional_cost : null,
            // What the vendor is owed — the total less the costs paid to somebody else.
            'vendor_amount' => $this->vendor_amount !== null ? (string) $this->vendor_amount : null,

            // The deals financing this order, each with the lines it claims and the partners in
            // it — the money each put in beside the percentage it produced. Present on the single
            // order only, and an empty list on the ordinary one the company paid for itself.
            // `isset` rather than a read: strict mode throws on an attribute that was never
            // set, and this one is attached by the show endpoint alone — the list never carries
            // it. Same shape as `InvestorDealResource::$balances`.
            'investor_funding' => $this->when(
                isset($this->investor_funding),
                fn (): array => $this->investor_funding,
            ),

            // The share a deal struck on this order would be born with — the company default,
            // published so the funding screen can show it rather than imply it.
            'default_investor_profit_share_percent' => $this->when(
                isset($this->default_investor_profit_share_percent),
                fn (): string => $this->default_investor_profit_share_percent,
            ),

            // **When the receipt on this order stops being undoable, and whether this caller may
            // still undo it.** Published so the screen can show or hide «تراجع عن الاستلام»
            // rather than let somebody discover the answer by getting a 422 — and computed
            // against the *asking* user's grants, so the manager who may step past the window
            // sees the button on the third day and the storekeeper does not.
            //
            // Both null/false on every order with no live receipt behind it, which is every
            // order that is not `completed`. Only present where `stockArrivals` was loaded: the
            // list does not carry it, the same rule `investor_funding` above follows.
            'receipt_reversible_until' => $this->whenLoaded(
                'stockArrivals',
                fn (): ?string => $this->reversalDeadline(),
            ),

            'can_reverse_receipt' => $this->whenLoaded(
                'stockArrivals',
                fn (): bool => $this->canReverseReceipt($request),
            ),

            'items' => PurchaseOrderItemResource::collection($this->whenLoaded('items')),
            'additional_costs' => PurchaseOrderAdditionalCostResource::collection($this->whenLoaded('additionalCosts')),

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /**
     * The receipt on this order that has not already been taken back, if there is one.
     *
     * The same question `ReversePurchaseOrderReceipt` asks, read off the loaded relation rather
     * than re-queried — this runs once per row of a list in the worst case.
     */
    private function reversibleArrival(): ?StockArrival
    {
        if ($this->status !== PurchaseOrderStatus::Completed) {
            return null;
        }

        return $this->stockArrivals
            ->reject(fn (StockArrival $arrival): bool => $arrival->isReversed())
            ->sortByDesc('id')
            ->first();
    }

    /** When the window on this order's live receipt closes, or null if it has none. */
    private function reversalDeadline(): ?string
    {
        $arrival = $this->reversibleArrival();

        return $arrival === null
            ? null
            : ReverseStockArrival::windowClosesAt($arrival)->toIso8601String();
    }

    /**
     * Whether *this* caller may undo it right now — the window, or the grant that waives it.
     *
     * Deliberately does not attempt the three guards a reversal also has to pass (nothing drawn
     * from the layers, nothing repriced, the receipt not already undone): answering those means
     * reading the cost layers behind every line, which is a query per order in a list to
     * pre-empt a refusal the domain gives clearly. The button being offered and the act being
     * refused is the honest failure here; the button being hidden on a receipt that is perfectly
     * reversible would not be.
     */
    private function canReverseReceipt(Request $request): bool
    {
        $arrival = $this->reversibleArrival();

        if ($arrival === null) {
            return false;
        }

        if (ReverseStockArrival::isWithinWindow($arrival)) {
            return true;
        }

        return $request->user()?->can(PermissionName::ReverseReceiptAnyTime->value) ?? false;
    }

    /**
     * A dollar order funded at one rate and received at another — USD-ACCOUNTS.md §٥.
     *
     * **Said, and nothing else.** The funded goods keep the funding rate and the company's own
     * the arrival rate; the owner chose to see the gap rather than book it (2026-11-10). So this
     * is the whole of it: the two rates, the gap per dollar, which way it went, and what it comes
     * to on the funded lines' dollars — the lines funding wrote a `funded_cost` on.
     *
     * @return array{funding_rate: string, arrival_rate: string, per_dollar: string, direction: string, funded_dollars: string, dinars: string}|null
     */
    private function rateDifference(): ?array
    {
        if ($this->funding_rate === null || $this->arrival_rate === null) {
            return null;
        }

        $funding = (string) $this->funding_rate;
        $arrival = (string) $this->arrival_rate;
        $gap = bcsub($arrival, $funding, 4);

        if (bccomp($gap, '0', 4) === 0) {
            return null;
        }

        $perDollar = ltrim($gap, '-');

        $fundedDollars = '0';

        foreach ($this->items()->whereNotNull('funded_cost')->get() as $item) {
            $fundedDollars = bcadd($fundedDollars, (string) ($item->final_total_cost ?? '0'), 2);
        }

        return [
            'funding_rate' => $funding,
            'arrival_rate' => $arrival,
            'per_dollar' => $perDollar,
            // The arrival rate against the funding rate: the dollars cost more when they came.
            'direction' => bccomp($gap, '0', 4) > 0 ? 'higher' : 'lower',
            'funded_dollars' => bcadd($fundedDollars, '0', 2),
            'dinars' => Money::round(bcmul($fundedDollars, $perDollar, 8)),
        ];
    }
}
