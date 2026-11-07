<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Carrier\Models\NawrisSettlementImport;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<NawrisSettlementImport>
 */
class NawrisSettlementImportFactory extends Factory
{
    protected $model = NawrisSettlementImport::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'file_name' => 'report.xlsx',
            'client_token' => (string) Str::uuid(),
            'imported_by' => User::factory(),
            'rows_count' => 1,
            'orders_count' => 1,
            'settled_count' => 1,
            'skipped_count' => 0,
            'rejected_count' => 0,
            'left_out_count' => 0,
            'warnings_count' => 0,
            'total_held' => '100.00',
            'received_amount' => '100.00',
            'fee_total' => '0.00',
        ];
    }
}
