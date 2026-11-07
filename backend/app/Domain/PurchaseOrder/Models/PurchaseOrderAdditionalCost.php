<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\PurchaseOrder\Support\Money;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Vendor\Models\StockArrival;
use Database\Factories\PurchaseOrderAdditionalCostFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One order-level cost that isn't tied to any single line — delivery, unloading, customs.
 *
 * No `/logs` route of its own — like {@see PurchaseOrderItem}, its history is read through the
 * document that owns it, via `PurchaseOrder::auditTrailSubjects()`.
 *
 * `amount` is what it costs, in full; there is no per-unit figure here — a delivery fee has no
 * unit to divide by. Its effect on a line's cost happens the other way around, via
 * {@see AllocatePurchaseOrderAdditionalCosts}, which spreads the sum of every row here across
 * the order's own lines.
 *
 * **Planned or arrival.** `stock_arrival_id` null is a cost typed on the order while it was `new`,
 * spread by that allocation. One set on it was added on the receive screen and is spread over
 * what that receipt brought instead — see {@see ReceivePurchaseOrder}.
 *
 * **Who was paid — `treasury_account_id`.** Null is the vendor's bill: the cost is in what the
 * vendor is owed. A drawer is money paid out now, and a manual payable money owed to somebody
 * else; either way the cost is outside the vendor's debt, and an `expense` movement on that
 * account stands for it. Assigned by the Actions, never mass-assigned.
 */
#[UseFactory(PurchaseOrderAdditionalCostFactory::class)]
#[Fillable(['name', 'amount'])]
class PurchaseOrderAdditionalCost extends Model
{
    /** @use HasFactory<PurchaseOrderAdditionalCostFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
        ];
    }

    /** Paid to somebody other than the vendor — a drawer or a manual payable. */
    public function isPaidElsewhere(): bool
    {
        return $this->treasury_account_id !== null;
    }

    /**
     * What can still come back: the expense standing on the treasury for this cost. Less than
     * `amount` when part was refunded, or when a deal carries part of it as its own expense.
     */
    public function refundableAmount(): string
    {
        $standing = $this->relationLoaded('standingExpenses')
            ? $this->standingExpenses
            : $this->standingExpenses()->get();

        return Money::sum('0', ...$standing->map(fn (TreasuryMovement $movement) => (string) $movement->amount)->all());
    }

    /**
     * The money this cost has out of its account right now — nothing on the vendor's bill.
     *
     * @return MorphMany<TreasuryMovement, $this>
     */
    public function standingExpenses(): MorphMany
    {
        return $this->morphMany(TreasuryMovement::class, 'source')
            ->where('kind', MovementKind::Expense->value)
            ->whereNull('reverses_movement_id')
            ->whereDoesntHave('reversedBy');
    }

    /**
     * Every refund on this cost, the reversed ones too — newest first.
     *
     * @return HasMany<PurchaseOrderCostRefund, $this>
     */
    public function refunds(): HasMany
    {
        return $this->hasMany(PurchaseOrderCostRefund::class, 'additional_cost_id')->latest('id');
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function treasuryAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class);
    }

    /**
     * The receipt this cost was added on; null for a planned cost.
     *
     * @return BelongsTo<StockArrival, $this>
     */
    public function stockArrival(): BelongsTo
    {
        return $this->belongsTo(StockArrival::class);
    }

    /**
     * @return BelongsTo<PurchaseOrder, $this>
     */
    public function purchaseOrder(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrder::class);
    }
}
