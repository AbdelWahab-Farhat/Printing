<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\Enums\StockAdjustmentReason;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Investor\Exceptions\ReturnedGoodsAlreadyAnswered;
use App\Domain\Investor\Models\InvestmentReturnedGoodsQuestion;
use Illuminate\Support\Facades\DB;

/**
 * «صالحة» or «تالفة» — and, for the second, the write-off that follows.
 *
 * **«تالفة» posts a real stock adjustment, not an expense**, and the difference is the whole point.
 * Booked as a cost alone, the pool's `stock_at_cost` would go on counting goods that do not exist:
 * its deployable cash would be overstated by exactly that amount, and the next lorry would be bought
 * with money that was never there. Written as a damage adjustment the goods leave the shelf, the
 * cost lands in the period's `damage_cost` by the ordinary road, and the two figures stay in step
 * without anybody reconciling them.
 *
 * **«صالحة» writes nothing**, deliberately. The goods really are back and really are usable; the
 * only thing that changed is that somebody has now looked. The answer is recorded so the close can
 * proceed, and `damage_movement_id` stays null — which is the difference between «we checked» and
 * «nothing happened».
 *
 * Answered once. A verdict is not a draft, and reopening it would mean unwinding a stock movement
 * that the shelf has already been counted against.
 */
final class RecordReturnedGoodsVerdict
{
    public function __construct(private readonly InventoryService $inventory) {}

    /**
     * @throws ReturnedGoodsAlreadyAnswered
     */
    public function __invoke(
        InvestmentReturnedGoodsQuestion $question,
        ReturnedGoodsVerdict $verdict,
        int $warehouseId,
        int $actorId,
        ?string $notes = null,
    ): InvestmentReturnedGoodsQuestion {
        return DB::transaction(function () use ($question, $verdict, $warehouseId, $actorId, $notes): InvestmentReturnedGoodsQuestion {
            $locked = InvestmentReturnedGoodsQuestion::query()
                ->whereKey($question->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if (! $locked->isOpen()) {
                throw ReturnedGoodsAlreadyAnswered::make($locked->verdict->label());
            }

            $locked->verdict = $verdict;
            $locked->answered_at = now();
            $locked->answered_by = $actorId;
            $locked->notes = $notes;

            if ($verdict === ReturnedGoodsVerdict::Damaged) {
                $movement = $this->inventory->recordMovement(StockMovementData::adjustment([
                    'stock_item_id' => (int) $locked->stock_item_id,
                    'warehouse_id' => $warehouseId,
                    'direction' => 'decrease',
                    'quantity' => (string) $locked->quantity,
                    'adjustment_reason' => StockAdjustmentReason::Damage->value,
                    'notes' => 'بضاعة تالفة راجعة من طلبية ملغاة',
                ], $actorId));

                $locked->damage_movement_id = $movement->getKey();
            }

            $locked->save();

            return $locked;
        });
    }
}
