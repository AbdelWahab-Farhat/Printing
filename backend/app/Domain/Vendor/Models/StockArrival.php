<?php

declare(strict_types=1);

namespace App\Domain\Vendor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\Warehouse;
use App\Domain\Vendor\Actions\RecordStockArrival;
use Database\Factories\StockArrivalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A shipment received from a vendor — the paperwork behind one or more `StockMovement` rows.
 *
 * **Nothing updates or deletes one, and there is no route that does.** Editing it after the
 * balances it produced have already moved would let a warehouse's count and its own paperwork
 * disagree — the same reason `StockMovement` itself is append-only.
 *
 * `vendor_id`, `warehouse_id` and `received_by` are deliberately absent from the fillable list.
 * They come from the route and the authenticated user, never from the payload, the same rule
 * `StockMovement::employee_id` follows — see {@see RecordStockArrival}.
 */
#[UseFactory(StockArrivalFactory::class)]
#[Fillable(['invoice_number', 'notes'])]
class StockArrival extends Model implements HasAuditTrail
{
    /** @use HasFactory<StockArrivalFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return BelongsTo<Vendor, $this>
     */
    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    /**
     * Where the shipment was put away.
     *
     * Read-only and for rendering only — the same shape `WarehouseStock::productVariant()` and
     * `StockMovement::employee()` already use for a cross-context relation. Actually moving stock
     * goes through `InventoryService::recordMovement()`, never through this relation.
     *
     * @return BelongsTo<Warehouse, $this>
     */
    public function warehouse(): BelongsTo
    {
        return $this->belongsTo(Warehouse::class);
    }

    /**
     * Who physically received it. Read-only, for rendering — see the note on {@see self::warehouse()}.
     *
     * @return BelongsTo<User, $this>
     */
    public function receivedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'received_by');
    }

    /**
     * @return HasMany<StockArrivalItem, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(StockArrivalItem::class);
    }

    /**
     * An arrival's history includes its lines — a document with three sizes on it is one story,
     * not four, and a line has no screen of its own to carry its own history.
     *
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [
            $this->getMorphClass() => [$this->getKey()],
            (new StockArrivalItem)->getMorphClass() => $this->items()->withTrashed()->pluck('id')->all(),
        ];
    }
}
