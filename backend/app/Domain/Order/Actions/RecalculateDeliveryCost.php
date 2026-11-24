<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\TreasuryService;

/**
 * Works out what delivery costs us on one order and writes it to `orders.delivery_cost`.
 *
 * **The one place that column is written.** Docs/orders/DELIVERY-PAYER.md §3:
 *
 * ```
 * recipient pays                      → 0
 * we pay, the carrier kept something  → what it kept, across every standing settlement
 * we pay, nothing kept yet            → delivery_price, the city's rate
 * ```
 *
 * **The real fee wins** (owner's decision, 2026-11-13). The city's rate is our best guess until
 * the money comes back; what the carrier actually kept at «تم التسوية» replaces it, and undoing
 * that settlement puts the guess back.
 *
 * Answers whether the figure moved, so the caller knows to work the money out again — the
 * investors' share and the fund's cash were both computed from the old one.
 */
final class RecalculateDeliveryCost
{
    public function __construct(private readonly TreasuryService $treasury) {}

    public function __invoke(Order $order): bool
    {
        $cost = $this->costOf($order);

        if (bccomp($cost, (string) ($order->delivery_cost ?? '0.00'), Money::SCALE) === 0) {
            return false;
        }

        $order->forceFill(['delivery_cost' => $cost])->save();

        return true;
    }

    private function costOf(Order $order): string
    {
        if (! $order->wePayDelivery()) {
            return '0.00';
        }

        // A figure an administrator typed wins over both derivations: it is the reason the
        // override exists. See the migration that added `delivery_cost_override`.
        if ($order->delivery_cost_override !== null) {
            return Money::round((string) $order->delivery_cost_override);
        }

        $kept = $this->treasury->carrierFeeKeptFor((int) $order->getKey());

        return bccomp($kept, '0', Money::SCALE) > 0
            ? Money::round($kept)
            : Money::round((string) ($order->delivery_price ?? '0.00'));
    }
}
