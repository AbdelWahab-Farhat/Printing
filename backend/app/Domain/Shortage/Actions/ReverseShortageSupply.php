<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Inventory\DTOs\StockMovementData;
use App\Domain\Inventory\InventoryService;
use App\Domain\Shortage\Enums\SupplyKind;
use App\Domain\Shortage\Exceptions\SupplyAlreadyReversed;
use App\Domain\Shortage\Exceptions\SupplyCannotBeReversed;
use App\Domain\Shortage\Exceptions\SupplyDoesNotBelongToShortage;
use App\Domain\Shortage\Exceptions\SupplyRequiresAnActor;
use App\Domain\Shortage\Models\Shortage;
use App\Domain\Shortage\Models\ShortageSupply;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * Undoes a supply entered in error, by writing the row that says so.
 *
 * **Nothing is edited and nothing is removed.** The mistaken entry stays exactly as it was and a
 * second row points back at it, carrying the same quantity and the same amount copied verbatim —
 * the `ReverseOrderPayment` shape, and the reason «منع تكرار الخصم المالي» holds: a ledger you
 * can rewrite explains nothing, and a ledger with two writers has two behaviours the day one of
 * them is fixed.
 *
 * `RecalculateShortageTotals` then restates the caches from what is left standing, which is what
 * reopens a shortage this reversal has un-completed — see its docblock for why it lands on «جاري
 * البحث».
 *
 * **It does take the goods back off the shelf.** A purchase that posted an arrival withdraws it
 * again, through the same `arrivalReversal` the vendor screen uses — so the layer it opened is
 * closed and the warehouse stops holding stock nobody bought. The ledger's own guards apply
 * unchanged and are the reason this can be refused: a layer already drawn on by an order, or
 * repriced by hand, cannot be withdrawn, and Inventory says so in its own words. Nothing in that
 * behaviour was altered to accommodate shortages.
 *
 * **What this deliberately does not do is take the goods back off the customer's invoice.**
 * `RecordShortageSupply` credits the order line when a purchase is recorded; reversing does not
 * debit it again. A reversal here means the *entry* was wrong — typed twice, wrong shortage,
 * wrong amount — not that sacks were taken back off a customer, and quietly re-cutting an invoice
 * from a bookkeeping correction is exactly the kind of silent second effect
 * ORDER-DELETE-AND-ARCHIVE §٢٫١ argues against. An order whose goods really did not arrive is
 * corrected on the order screen, where the person doing it can see the invoice change.
 */
final class ReverseShortageSupply
{
    public function __construct(
        private readonly RecalculateShortageTotals $recalculate,
        private readonly InventoryService $inventory,
        private readonly TreasuryService $treasury,
    ) {}

    /**
     * @throws SupplyDoesNotBelongToShortage
     * @throws SupplyCannotBeReversed
     * @throws SupplyAlreadyReversed
     */
    public function __invoke(
        Shortage $shortage,
        ShortageSupply $supply,
        ?string $reason = null,
        ?User $actor = null,
    ): ShortageSupply {
        if ((int) $supply->shortage_id !== (int) $shortage->getKey()) {
            throw SupplyDoesNotBelongToShortage::make();
        }

        return DB::transaction(function () use ($shortage, $supply, $reason, $actor): ShortageSupply {
            $locked = Shortage::query()
                ->whereKey($shortage->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            // Re-read under the lock: two clerks reversing the same entry otherwise both find it
            // un-reversed and both write a row, and the unique index turns the loser into a raw
            // 500 instead of the readable refusal below.
            $original = ShortageSupply::query()
                ->whereKey($supply->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if ($original->kind !== SupplyKind::Purchased) {
                throw SupplyCannotBeReversed::externalArrival();
            }

            if ($original->isReversal()) {
                throw SupplyCannotBeReversed::itIsAReversal();
            }

            if ($original->isReversed()) {
                throw SupplyAlreadyReversed::make();
            }

            // **Before the reversing row, mirroring how the purchase posted before its own.**
            // A withdrawal the ledger refuses — the sacks are already in a customer's order —
            // takes the whole transaction with it, leaving the money row standing rather than a
            // reversal that claims goods came back when they did not.
            $this->withdrawArrival($original, $actor);

            $reversal = $locked->supplies()->make();

            $reversal->forceFill([
                // A reversal of a purchase is itself a purchase-shaped row: it carries the same
                // amount so the pair nets to zero in any sum that ignores the pairing, and the
                // CHECK that demands money on a purchase is satisfied by the copy rather than
                // worked around.
                'kind' => SupplyKind::Purchased,
                'quantity' => $original->quantity,
                'amount' => $original->amount,
                'method' => $original->method,
                'reference' => $original->reference,
                // Today, not the day of the entry being undone: a correction is an event that
                // happened now, and back-dating it would hide it from «ماذا جرى هذا الأسبوع؟».
                'occurred_on' => now()->toDateString(),
                'notes' => $reason,
                'reverses_supply_id' => $original->getKey(),
                'recorded_by_user_id' => $actor?->getKey(),
                // The drawer the purchase came out of, which the money goes back into. A purchase
                // from before the treasury names none; it was counted into the opening, so it
                // returns to the method's default (TREASURY-DESIGN §١١).
                'treasury_account_id' => $original->treasury_account_id
                    ?? $this->treasury->accountFor($original->method->value, null, incoming: false)->getKey(),
            ])->save();

            $this->returnTheMoney($original, $reversal, $reason, $actor);

            ($this->recalculate)($locked->refresh());

            return $reversal;
        });
    }

    /**
     * Puts the money back into the drawer it was paid from — the mirror of the purchase's own
     * movement, or, for a purchase from before the treasury, a fresh one into the default.
     */
    private function returnTheMoney(
        ShortageSupply $original,
        ShortageSupply $reversal,
        ?string $reason,
        ?User $actor,
    ): void {
        $actorId = $actor?->getKey() === null ? null : (int) $actor->getKey();

        $mirrored = $this->treasury->reverseSource($original->getMorphClass(), (int) $original->getKey(), $reason, $actorId);

        if ($mirrored !== [] || $original->treasury_account_id !== null) {
            return;
        }

        $this->treasury->post(new MovementData(
            accountId: (int) $reversal->treasury_account_id,
            direction: MovementDirection::In,
            kind: MovementKind::SupplyPurchase,
            amount: (string) $reversal->amount,
            occurredAt: now(),
            sourceType: $reversal->getMorphClass(),
            sourceId: (int) $reversal->getKey(),
            notes: $reason,
            recordedBy: $actorId,
        ));
    }

    /**
     * Takes the sacks back off the shelf, when the entry put them there.
     *
     * Nothing to do for a purchase that moved no stock — a free-text shortage — which is most of
     * what this returns early on.
     *
     * @throws SupplyRequiresAnActor
     */
    private function withdrawArrival(ShortageSupply $supply, ?User $actor): void
    {
        if (! $supply->movedStock()) {
            return;
        }

        if ($actor === null) {
            throw SupplyRequiresAnActor::make();
        }

        $supply->loadMissing('stockMovement');
        $movement = $supply->stockMovement;

        if ($movement === null) {
            return;
        }

        $this->inventory->recordMovement(StockMovementData::arrivalReversal(
            stockItemId: (int) $movement->stock_item_id,
            warehouseId: (int) $movement->to_warehouse_id,
            quantity: (string) $movement->quantity,
            reversedMovementId: (int) $movement->getKey(),
            // The same reference the arrival carried, so both halves of the pair answer «أي
            // طلبية؟» alike. Zero where there is none: the column is unconstrained, and the
            // vendor path passes an arrival id here for the same positional reason.
            referenceId: (int) ($movement->reference_id ?? 0),
            employeeId: (int) $actor->getKey(),
        ));
    }
}
