<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\LineShortage;
use App\Domain\Order\Models\OrderItem;
use App\Domain\Order\OrderService;
use App\Domain\Shortage\Exceptions\ShortageNeedsNoWarehouseQuantity;
use App\Domain\Shortage\Models\Shortage;

/**
 * States how much the warehouse is short, from the shortage's own screen.
 *
 * **A second door onto one writer, not a second place to store the answer.** The figure belongs to
 * `order_items.shortage_warehouse_quantity`: `SyncShortagesFromOrder` recomputes an order-born
 * shortage's `required_quantity` from its line on every pass, so a number written onto this row
 * would be overwritten by the next sync. So this walks back through
 * {@see OrderService::setShortages()} — the same door the order screen uses — and lets the sync
 * convert the row as it always would.
 *
 * **It exists because the person who knows is standing here.** The weight cannot be asked for when
 * the shortage is declared: the bags are missing, so there is nothing to put on a scale and no
 * factor in the catalogue to derive one from. Whoever first knows is usually the buyer about to
 * record a purchase — and sending them to the order screen to unblock their own form was a detour
 * through a screen they had no other reason to open.
 *
 * **Only while the weight is still unknown.** The conversion is safe precisely because nothing can
 * have been supplied yet — `RecordShortageSupply` refuses every arrival until this is done — so a
 * row reaching here has an empty ledger and there is no history for the restatement to contradict.
 * Correcting a weight after purchases exist is a different and harder thing, and the order screen
 * keeps it.
 *
 * **The invoice is untouched.** `shortage_quantity` is carried through exactly as it stands; only
 * the warehouse's figure is written. That is what makes this the chaser's job rather than the
 * order clerk's.
 */
final class SetShortageWarehouseQuantity
{
    public function __construct(private readonly OrderService $orders) {}

    /**
     * @throws ShortageNeedsNoWarehouseQuantity
     */
    public function __invoke(Shortage $shortage, string $quantity, ?User $actor = null): Shortage
    {
        $item = $shortage->loadMissing('orderItem.variant.stockItem')->orderItem;

        if (! $item instanceof OrderItem) {
            throw ShortageNeedsNoWarehouseQuantity::manual();
        }

        if (! $item->isStockedInAnotherUnit()) {
            throw ShortageNeedsNoWarehouseQuantity::unitsAgree($item->pricing_unit->label());
        }

        if (! $item->shortageWeightIsUnknown()) {
            throw ShortageNeedsNoWarehouseQuantity::alreadyStated();
        }

        $order = $item->order;

        // **Every line of the order, because the set is replaced wholesale** — see
        // `SetOrderShortages`. A map naming only this one would clear the shortage off every other
        // line of the same order, which is a very quiet way to re-price an invoice.
        $shortages = [];

        foreach ($order->items()->get() as $line) {
            $isTheOne = (int) $line->getKey() === (int) $item->getKey();

            $shortages[(int) $line->getKey()] = $line->shortage_quantity === null
                ? LineShortage::none()
                : new LineShortage(
                    quantity: (string) $line->shortage_quantity,
                    warehouseQuantity: $isTheOne
                        ? $quantity
                        : ($line->shortage_warehouse_quantity === null
                            ? null
                            : (string) $line->shortage_warehouse_quantity),
                );
        }

        // Fires `OrderShortagesRecorded`, which runs the sync, which reads the line's new unit and
        // re-denominates this row from «٣٠ قطعة» to «١٢٫٥ كجم». Nothing here writes to the
        // shortage at all.
        $this->orders->setShortages($order, $shortages, $actor);

        return $shortage->refresh();
    }
}
