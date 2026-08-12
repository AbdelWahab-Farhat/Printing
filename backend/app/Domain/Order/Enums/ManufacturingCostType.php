<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\Order\Models\ProductionCostEntry;

/**
 * What kind of production cost a {@see ProductionCostEntry} records.
 *
 * `Labor` and `MachineRuntime` and `Overhead` are rate-driven — see `ApplyManufacturingRates`,
 * which looks up a {@see \App\Domain\Order\Models\ManufacturingCostRate} for each and applies it
 * automatically the moment an order enters printing. `ScrapLoss` is different in kind: its amount
 * is derived from FIFO batch cost when spoiled stock is written off, never from a rate — see the
 * plan's Inventory section for the endpoint that produces it (not part of this change).
 */
enum ManufacturingCostType: string
{
    case Labor = 'labor';
    case MachineRuntime = 'machine_runtime';
    case Overhead = 'overhead';
    case ScrapLoss = 'scrap_loss';

    public function label(): string
    {
        return match ($this) {
            self::Labor => 'عمالة',
            self::MachineRuntime => 'تشغيل آلة',
            self::Overhead => 'مصاريف عامة',
            self::ScrapLoss => 'خسارة تلف',
        };
    }

    /** Whether a {@see ManufacturingCostRate} drives this cost type. `ScrapLoss` never has one. */
    public function isRateDriven(): bool
    {
        return $this !== self::ScrapLoss;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }
}
