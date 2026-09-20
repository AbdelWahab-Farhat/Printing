<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Order\OrderService;
use App\Domain\Order\Support\MaterialCost;
use Illuminate\Support\Facades\DB;

/**
 * Asks, of a cancelled order, whether the material that came back is still usable.
 *
 * ## The gap this closes
 *
 * `ReverseOrderStockDeduction` credits a cancelled line's material back to the shelf **as good
 * stock**. Paper that has been through a press is not good stock, and nothing in the system can
 * tell the difference: a movement records a quantity, not whether there is ink on it.
 *
 * Until now the ruin had to be noticed and written off by somebody who happened to remember.
 * Unremembered, the pool's period shows profit it did not earn on goods it does not have — and
 * under the old model that error surfaced only when somebody counted the shelf.
 *
 * So a question is raised here, and {@see CloseInvestmentPeriod} refuses to proceed while one is
 * unanswered.
 *
 * ## Only where the question is real
 *
 * Two conditions, both read off facts the line already carries:
 *
 * - **the line was printed** — `isPrinted()`, the same predicate
 *   {@see MaterialCost} uses to decide whether a draw is priced at all. A
 *   سادة line is sold off the shelf as it stands and comes back untouched; a وسيط line never had a
 *   shelf of ours to come back to.
 * - **the material was unpriced** — a priced draw was paid for the day it left, and its
 *   cancellation hands those goods to the **company** rather than back to the pool, so the pool has
 *   nothing to inspect.
 *
 * And only for a **pool**. A legacy صفقة is closed and read-only; raising a question against it
 * would block nothing and mean nothing.
 *
 * **A prompt with one possible answer is noise**, and noise is what teaches people to click through
 * the prompts that matter.
 */
final class RaiseReturnedGoodsQuestions
{
    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @return list<InvestmentReturnedGoodsQuestion>
     */
    public function __invoke(int $orderId): array
    {
        $lines = $this->orders->returnedMaterialFor($orderId);

        if ($lines === []) {
            return [];
        }

        $breakdown = $this->inventory->consumptionBreakdownFor(
            array_map(fn (array $line) => $line['movement_id'], $lines),
        );

        return DB::transaction(function () use ($lines, $breakdown, $orderId): array {
            $raised = [];

            foreach ($lines as $line) {
                foreach ($this->questionsFor($line, $breakdown, $orderId) as $question) {
                    $raised[] = $question;
                }
            }

            return $raised;
        });
    }

    /**
     * One line's draws, grouped into the one question that line deserves.
     *
     * @param  array<string, mixed>  $line
     * @param  array<int, list<array<string, mixed>>>  $breakdown
     * @return list<InvestmentReturnedGoodsQuestion>
     */
    private function questionsFor(array $line, array $breakdown, int $orderId): array
    {
        // A line the press never ran cannot have ruined anything.
        if ($line['is_printed'] !== true) {
            return [];
        }

        $byPool = [];

        foreach ($breakdown[$line['movement_id']] ?? [] as $draw) {
            // Priced: the investor was paid the day it left, and the cancellation gave those goods
            // to the company. Nothing of the pool's came back, so there is nothing to ask about.
            if ($draw['investor_deal_id'] === null || $draw['printing_sale_price'] !== null) {
                continue;
            }

            $poolId = (int) $draw['investor_deal_id'];
            $byPool[$poolId] ??= ['quantity' => '0.000', 'cost' => '0.00'];
            $byPool[$poolId]['quantity'] = bcadd($byPool[$poolId]['quantity'], (string) $draw['quantity'], 3);
            $byPool[$poolId]['cost'] = bcadd($byPool[$poolId]['cost'], (string) $draw['total_cost'], 2);
        }

        $raised = [];

        foreach ($byPool as $poolId => $totals) {
            $pool = InvestorDeal::query()->whereKey($poolId)->first();

            // A legacy صفقة is closed and read-only: a question against it would block nothing.
            if ($pool === null || ! $pool->isPool()) {
                continue;
            }

            // One question per line **and pool**, by unique index. A cancellation walked twice must
            // not ask twice, and an already-answered question must not be reopened by a retry.
            //
            // The pool is part of the key because a shelf may move between pools while its old cost
            // layers stay behind: one line can then draw straight through the boundary, and both
            // pools have ruined paper to account for. Keyed on the line alone, the second pool's
            // question could never be raised and its period would close over goods it no longer
            // has.
            $existing = InvestmentReturnedGoodsQuestion::query()
                ->where('order_item_id', $line['line_id'])
                ->where('investor_deal_id', $poolId)
                ->first();

            if ($existing !== null) {
                continue;
            }

            $question = new InvestmentReturnedGoodsQuestion;
            $question->investor_deal_id = $poolId;
            $question->order_id = $orderId;
            $question->order_item_id = (int) $line['line_id'];
            $question->stock_item_id = (int) $line['stock_item_id'];
            // Read now, not when it is answered: the shelf will have moved on by then, and the
            // answer has to be about what actually came back.
            $question->quantity = $totals['quantity'];
            $question->cost = $totals['cost'];
            $question->verdict = ReturnedGoodsVerdict::Open;
            $question->save();

            $raised[] = $question;
        }

        return $raised;
    }
}
