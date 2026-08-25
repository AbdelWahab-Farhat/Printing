<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Inventory\Actions\ApplyStockChange;
use App\Domain\Inventory\Actions\ConsumeStockBatchesFifo;
use App\Domain\Inventory\Actions\SetStockUnit;
use App\Domain\Inventory\Enums\StockBatchSourceType;
use App\Domain\Vendor\Models\StockArrivalItem;
use Database\Factories\StockBatchFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One cost layer of one size in one warehouse — what a quantity of stock cost, and how much of
 * that quantity is still on the shelf.
 *
 * **Nothing here is fillable.** Every column is either written once by
 * {@see ApplyStockChange::increase()}/`relocateBatches()` when the layer is created, or drawn
 * down by {@see ConsumeStockBatchesFifo} under the same row lock
 * `WarehouseStock` uses — the same treatment `WarehouseStock::quantity` gets, for the same
 * reason: a payload that could move cost without leaving a `stock_batch_consumptions` row behind
 * would be exactly the gap this design exists to close.
 *
 * `unit` is the one column with a second writer: a snapshot of `product.stock_unit` on the way
 * in, like every other column here, but also changed — alongside every other batch and balance
 * for the same product's variants, in one transaction — by
 * {@see SetStockUnit}. Still never reachable from a payload; the
 * one endpoint that writes it validates against {@see PricingUnit} and
 * nothing else.
 *
 * `quantity_remaining` for a given (warehouse, variant) must always sum to that pair's
 * `WarehouseStock::quantity`. See `StockBatchLedgerTest`.
 */
#[UseFactory(StockBatchFactory::class)]
#[Fillable([])]
class StockBatch extends Model
{
    /** @use HasFactory<StockBatchFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source_type' => StockBatchSourceType::class,
            'unit_cost' => 'decimal:3',
            'quantity_received' => 'decimal:3',
            'quantity_remaining' => 'decimal:3',
            'unit' => PricingUnit::class,
            'received_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Warehouse, $this>
     */
    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    /**
     * The shelf this cost layer belongs to — see the note on {@see WarehouseStock::stockItem()}.
     *
     * @return BelongsTo<StockItem, $this>
     */
    public function stockItem(): BelongsTo
    {
        return $this->belongsTo(StockItem::class);
    }

    /**
     * The costed arrival line this layer traces back to. Null for an adjustment or opening-balance
     * layer, and — for now — also null for a plain purchase arrival; see the migration's docblock.
     *
     * @return BelongsTo<StockArrivalItem, $this>
     */
    public function stockArrivalItem(): BelongsTo
    {
        return $this->belongsTo(StockArrivalItem::class);
    }

    /**
     * Every draw ever made against this layer.
     *
     * @return HasMany<StockBatchConsumption, $this>
     */
    public function consumptions(): HasMany
    {
        return $this->hasMany(StockBatchConsumption::class);
    }
}
