<?php

declare(strict_types=1);

namespace App\Domain\Inventory\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Enums\MovementType;
use Database\Factories\StockMovementFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One entry in the stock ledger — a quantity, where it came from, where it went, and who moved it.
 *
 * **Nothing updates or deletes one.** There is no route that does, and a correction is a further
 * `adjustment` rather than an edit: a ledger you can rewrite explains nothing. The soft-delete
 * trait is here because every model in this schema carries it and a test enforces that, not
 * because anything removes a row — and if one ever were removed, the balance it explains would
 * stop adding up, which `StockLedgerTest` would notice.
 *
 * `quantity` is always positive; the direction lives in which end is filled. See the migration
 * for the four shapes.
 *
 * Nothing here is fillable but the fields a human genuinely supplies. The warehouse ids come
 * from the movement's type rather than from the payload, and `employee_id` is stamped from the
 * authenticated user, so no request can attribute stock it moved to somebody else.
 */
#[UseFactory(StockMovementFactory::class)]
#[Fillable(['quantity', 'notes'])]
class StockMovement extends Model
{
    /** @use HasFactory<StockMovementFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'movement_type' => MovementType::class,
            'quantity' => 'decimal:3',
        ];
    }

    /**
     * The size that moved.
     *
     * Read-only and for rendering only — see the note on {@see WarehouseStock::productVariant()}
     * for why Inventory holds this relation but asks `CatalogService` for anything it decides on.
     *
     * @return BelongsTo<ProductVariant, $this>
     */
    public function productVariant(): BelongsTo
    {
        return $this->belongsTo(ProductVariant::class);
    }

    /**
     * Where it left, or null if it entered the business here.
     *
     * @return BelongsTo<Warehouse, $this>
     */
    public function fromWarehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class, 'from_warehouse_id');
    }

    /**
     * Where it arrived, or null if it left the business here.
     *
     * @return BelongsTo<Warehouse, $this>
     */
    public function toWarehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class, 'to_warehouse_id');
    }

    /**
     * Who physically moved it.
     *
     * @return BelongsTo<User, $this>
     */
    public function employee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'employee_id');
    }
}
