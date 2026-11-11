<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Customer\Support\PrintColors;
use App\Domain\Order\Enums\DesignSource;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Exceptions\PrintOrderNeedsADesign;
use App\Domain\Order\Exceptions\PrintOrderNeedsColors;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;

/**
 * **No print order without its colours** (owner, 2026-11-11; PRINT-COLORS.md §9).
 *
 * Asked at three moments, each inside the transaction that would otherwise write the order:
 *
 * - {@see forIntake()} when a clerk creates an order, and when a customer's request is accepted.
 *   Every design on it must carry a complete colour list, and there must be a design unless we
 *   are drawing it ourselves (the colours are then asked for on the design ticket).
 * - {@see forPress()} on every move into «قيد الطباعة»: the version the press will print must
 *   carry a complete colour list. This is also what catches orders taken before the rule.
 *
 * Only for orders on the standard road. Plain goods are never printed, and outsourced work is
 * printed by the vendor from the file.
 */
final class GuardPrintColors
{
    /**
     * @throws PrintOrderNeedsADesign
     * @throws PrintOrderNeedsColors
     */
    public function forIntake(Order $order): void
    {
        if (! $order->isPrintedHere()) {
            return;
        }

        $versions = $order->load('designs.customerDesign')->designs
            ->filter(fn (OrderDesign $design) => $design->status !== OrderDesignStatus::Rejected)
            ->sortBy('version');

        if ($versions->isEmpty()) {
            if ($order->design_source === DesignSource::InHouse) {
                return;
            }

            throw PrintOrderNeedsADesign::make();
        }

        foreach ($versions as $version) {
            $this->assertComplete($version, atThePress: false);
        }
    }

    /**
     * @throws PrintOrderNeedsADesign
     * @throws PrintOrderNeedsColors
     */
    public function forPress(Order $order): void
    {
        if (! $order->isPrintedHere()) {
            return;
        }

        $order->unsetRelation('designs');
        $version = $order->designForPress();

        if ($version === null) {
            throw PrintOrderNeedsADesign::make();
        }

        $this->assertComplete($version, atThePress: true);
    }

    private function assertComplete(OrderDesign $version, bool $atThePress): void
    {
        if (PrintColors::isComplete($version->print_colors)) {
            return;
        }

        $version->loadMissing('customerDesign');

        $label = $version->customerDesign?->label;
        $designId = $version->customer_design_id === null ? null : (int) $version->customer_design_id;

        throw $atThePress
            ? PrintOrderNeedsColors::atThePress($label, $designId)
            : PrintOrderNeedsColors::forDesign($label, $designId);
    }
}
