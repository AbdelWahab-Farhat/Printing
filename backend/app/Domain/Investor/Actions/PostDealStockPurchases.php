<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\StockPurchaseMargins;
use App\Domain\Order\OrderService;
use Illuminate\Support\Facades\DB;

/**
 * Pays the deals whose plain stock the press has just bought off the shelf.
 *
 * **The second road a deal can earn on, and the whole of سعر السادة.** The owner's framing, on
 * 2026-09-06: «الشركة نفسها مطبعة — يعني كأننا بنشروه من المستثمر… أي حاجة تطلع من المخزون
 * الكيلو يمشي بسعر السادة بالوزن، كأنه باعها بيع ليّا… استلم الزبون ما استلمش، المطبعة تتحمّل».
 * The investor is not a partner in the printing job; he is a merchant of plain bags whose sale
 * completes at the warehouse door.
 *
 * ```
 * per priced draw   margin = printing_sale_price × quantity − total_cost
 * deal margin       = Σ over that deal's priced draws on this order's printed lines
 * owners' share     = margin × investor_funded_percent ÷ 100      ← ownership ALONE
 * each investor     = largest-remainder split of that over share_percent
 * ```
 *
 * **Ownership alone — no `investor_profit_share_percent` here**, and that is the one number that
 * separates this from {@see PostDealEarningsForOrder}. The owner settled it when asked how the
 * 32 should reach a man's pocket: «بينهم وبين شركة — أكيد للشركة نسبة فيها، فنسبة فيها أعطيها
 * للشركة بشكل طبيعي وانتهينا، وباقي يتوزع بينهم». Nothing was sold to anybody outside the
 * company and no work was done to earn a cut of it; the goods simply changed hands at an agreed
 * price, so the margin follows the goods. See {@see InvestorDeal::ownersCutOf()}.
 *
 * **Keyed on the order line, not on the draw.** A restatement — the press correcting what the run
 * actually used — replaces the line's movement and keeps the line, so keying here on
 * `order_items.id` lets {@see PostDealShare} recognise the corrected figure as the same source,
 * reverse what it wrote before and post the new one. Keyed on the movement, the first payment
 * would stand beside the second forever.
 *
 * **And a cancellation is deliberately not undone.** Nothing calls this on the way to «ملغاة»;
 * the entries stay, and `ReverseOrderStockDeduction` hands the goods back to the company rather
 * than to the deal. That is «المطبعة تتحمّل» in the ledger.
 */
final class PostDealStockPurchases
{
    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
        private readonly PostDealShare $postShare,
    ) {}

    /**
     * @return list<InvestorWalletEntry> the rows written, empty when nothing was bought
     */
    public function __invoke(int $orderId): array
    {
        $lines = $this->orders->stockPurchaseAttributionFor($orderId);

        if ($lines === []) {
            return [];
        }

        $breakdown = $this->inventory->consumptionBreakdownFor(
            array_map(fn (array $line) => $line['movement_id'], $lines),
        );

        $written = [];

        foreach ($lines as $line) {
            foreach ($this->rowsForLine($line, $breakdown) as $row) {
                $written[] = $row;
            }
        }

        return $written;
    }

    /**
     * One further draw against an order that was already fulfilled — bags spoiled at the press.
     *
     * **Keyed on the movement, not on the line**, and that is the whole reason it is a second
     * entry point rather than a re-run of `__invoke()`. The line's own draw has not changed; this
     * is an extra one beside it, so posting it under the line id would make {@see PostDealShare}
     * read the first payment as a figure to correct and replace it with the second. A spoiled
     * run is its own event and is paid for on its own row.
     *
     * @return list<InvestorWalletEntry>
     */
    public function forMovement(int $stockMovementId): array
    {
        return $this->post(
            $this->inventory->consumptionBreakdownFor([$stockMovementId])[$stockMovementId] ?? [],
            AuditSubject::StockMovement->value,
            $stockMovementId,
            'تصحيح بيع سادة الهالك للمطبعة',
        );
    }

    /**
     * One line's purchase, deal by deal.
     *
     * A transaction per line rather than one around the whole order: each line is its own source
     * in the ledger and its own idempotent unit, and a second line failing must not unwrite the
     * first line's payment. The caller — `ChangeOrderStatus` — already holds a transaction around
     * the entire status move, so in practice this nests and commits with it; standing alone it
     * still cannot leave one line half paid.
     *
     * @param  array{line_id: int, movement_id: int}  $line
     * @param  array<int, list<array<string, mixed>>>  $breakdown
     * @return list<InvestorWalletEntry>
     */
    private function rowsForLine(array $line, array $breakdown): array
    {
        return $this->post(
            $breakdown[$line['movement_id']] ?? [],
            AuditSubject::OrderItem->value,
            $line['line_id'],
            'تصحيح بيع السادة للمطبعة',
        );
    }

    /**
     * Turns one movement's priced draws into wallet rows, under one source.
     *
     * @param  list<array<string, mixed>>  $draws
     * @return list<InvestorWalletEntry>
     */
    private function post(array $draws, string $sourceType, int $sourceId, string $correctionNote): array
    {
        $margins = StockPurchaseMargins::byDeal($draws);

        if ($margins === []) {
            return [];
        }

        // Ascending by id, always — the deadlock discipline this whole context shares with
        // CreditBackStockBatches.
        ksort($margins);

        return DB::transaction(function () use ($margins, $sourceType, $sourceId, $correctionNote): array {
            $written = [];

            foreach ($margins as $dealId => $margin) {
                $deal = InvestorDeal::query()->whereKey($dealId)->lockForUpdate()->first();

                if ($deal === null) {
                    continue;
                }

                $rows = ($this->postShare)(
                    $deal,
                    $deal->ownersCutOf($margin),
                    $sourceType,
                    $sourceId,
                    $correctionNote,
                );

                foreach ($rows as $row) {
                    $written[] = $row;
                }
            }

            return $written;
        });
    }
}
