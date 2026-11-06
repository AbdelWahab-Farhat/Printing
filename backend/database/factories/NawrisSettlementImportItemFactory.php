<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use App\Domain\Carrier\Models\NawrisSettlementImport;
use App\Domain\Carrier\Models\NawrisSettlementImportItem;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<NawrisSettlementImportItem>
 */
class NawrisSettlementImportItemFactory extends Factory
{
    protected $model = NawrisSettlementImportItem::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nawris_settlement_import_id' => NawrisSettlementImport::factory(),
            'row_number' => 1,
            'outcome' => NawrisSettlementOutcome::Settled,
            'held_amount' => '100.00',
            'fee_amount' => '0.00',
        ];
    }
}
