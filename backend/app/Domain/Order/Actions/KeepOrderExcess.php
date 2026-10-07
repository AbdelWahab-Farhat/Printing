<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Exceptions\NoExcessToKeep;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\DTOs\MovementData;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Support\Facades\DB;

/**
 * «اعتبار الزائد إيراداً» — what the customer paid beyond the order is the shop's now.
 *
 * **All of it, in one entry.** The excess an order holds is one figure owed to one customer, and
 * keeping part of it while owing the rest is a distinction nobody asked for: whoever wants to hand
 * some back refunds that much first, which the refund takes out of the excess before anything else.
 *
 * **No cash moves, so nothing in the drawer changes.** The money has been there since the payment
 * — what changes is whose it is: «علينا» comes down by the excess, and the shop's own share rises
 * by it. `paid_amount` is untouched, so the order's sales stay what it cost, and the figure stays
 * findable later as what it is — an `excess_kept` entry, not part of a sale.
 *
 * Undone by reversing the entry, which puts the excess back as owed to the customer.
 */
final class KeepOrderExcess
{
    public function __construct(
        private readonly RecalculateOrderPayments $recalculate,
        private readonly TreasuryService $treasury,
    ) {}

    public function __invoke(Order $order, ?string $notes = null, ?User $actor = null): OrderPayment
    {
        return DB::transaction(function () use ($order, $notes, $actor): OrderPayment {
            // Locked for the reason every money write here is: two people keeping the same
            // excess at once would both read it and both write it.
            $locked = Order::query()->whereKey($order->getKey())->lockForUpdate()->firstOrFail();

            $excess = Money::round((string) $locked->excess_amount);

            if (bccomp($excess, '0', Money::SCALE) <= 0) {
                throw NoExcessToKeep::make();
            }

            $entry = new OrderPayment([
                'amount' => $excess,
                // No method: no money moved. The table's shape CHECK refuses one that names it.
                'method' => null,
                'reference' => null,
                // Dated when it is decided, like a write-off — a hand-typed date here would be a
                // door for moving the income into a month that is already closed.
                'paid_at' => now(),
                'notes' => $notes,
            ]);

            $entry->order_id = $locked->getKey();
            $entry->type = OrderPaymentType::ExcessKept;
            $entry->recorded_by = $actor?->getKey();
            $entry->save();

            $this->treasury->post(new MovementData(
                accountId: (int) $this->treasury->customerExcessPayable()->getKey(),
                direction: MovementDirection::In,
                kind: MovementKind::ExcessKept,
                amount: $excess,
                occurredAt: $entry->paid_at,
                sourceType: $entry->getMorphClass(),
                sourceId: (int) $entry->getKey(),
                orderId: (int) $locked->getKey(),
                notes: "زائد الطلبية {$locked->code} اعتُبر إيراداً",
                recordedBy: $actor?->getKey() === null ? null : (int) $actor->getKey(),
            ));

            ($this->recalculate)($locked);

            return $entry;
        });
    }
}
