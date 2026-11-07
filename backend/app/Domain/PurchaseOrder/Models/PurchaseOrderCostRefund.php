<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use App\Domain\PurchaseOrder\Actions\RefundAdditionalCost;
use App\Domain\PurchaseOrder\Actions\ReverseCostRefund;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Money that came back on a purchase order's cost, and why — see {@see RefundAdditionalCost}.
 *
 * **The record, not the money.** What moved is the cost's own `expense` movement, reposted at
 * what is left. This row says how much, who and why, which a repost cannot.
 *
 * **Undone by stamping, never by deleting** — {@see ReverseCostRefund}. A reversed refund stays
 * on the order's history and stops counting.
 *
 * `recorded_by` and the three `reversed*` columns are assigned by the Actions, never
 * mass-assigned.
 */
#[Fillable(['amount', 'reason'])]
class PurchaseOrderCostRefund extends Model
{
    use Auditable, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'reversed_at' => 'datetime',
        ];
    }

    public function isReversed(): bool
    {
        return $this->reversed_at !== null;
    }

    /**
     * @return BelongsTo<PurchaseOrderAdditionalCost, $this>
     */
    public function additionalCost(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrderAdditionalCost::class, 'additional_cost_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
