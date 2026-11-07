<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Carrier\Enums\NawrisSettlementOutcome;
use Database\Factories\NawrisSettlementImportItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * قرار طلبية واحدة في دفعة، بالقيم الخام كما وردت — كي يجاب بعد أشهر: لماذا لم تتحرك هذه؟
 */
#[UseFactory(NawrisSettlementImportItemFactory::class)]
#[Fillable([])]
class NawrisSettlementImportItem extends Model
{
    /** @use HasFactory<NawrisSettlementImportItemFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'row_number' => 'integer',
            'outcome' => NawrisSettlementOutcome::class,
            'warnings' => 'array',
            'held_amount' => 'decimal:2',
            'fee_amount' => 'decimal:2',
        ];
    }

    /**
     * @return BelongsTo<NawrisSettlementImport, $this>
     */
    public function settlementImport(): BelongsTo
    {
        return $this->belongsTo(NawrisSettlementImport::class, 'nawris_settlement_import_id');
    }
}
