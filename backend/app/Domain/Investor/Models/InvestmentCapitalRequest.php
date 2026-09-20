<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\CapitalRequestDirection;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use Database\Factories\InvestmentCapitalRequestFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One investor's capital waiting at a period boundary.
 *
 * **It holds no money.** A deposit sits in the wallet as it always has; what waits here is only the
 * `allocation` into the pool. So a pending request costs the investor nothing — he may cancel it
 * and take his money — and the ledger stays the single place capital actually is.
 *
 * `applied_entry_id` is the receipt, and the unique index behind it is what makes applying twice
 * impossible rather than merely unlikely.
 *
 * Nothing that decides an outcome is fillable. The direction, the pool, the investor and the status
 * are the action's to set; a payload that could post `status` could mark its own request applied.
 */
#[UseFactory(InvestmentCapitalRequestFactory::class)]
#[Fillable(['amount', 'notes'])]
class InvestmentCapitalRequest extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentCapitalRequestFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'direction' => CapitalRequestDirection::class,
            'status' => CapitalRequestStatus::class,
            'amount' => 'decimal:2',
            'requested_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Investor, $this>
     */
    public function investor(): BelongsTo
    {
        return $this->belongsTo(Investor::class);
    }

    /**
     * @return BelongsTo<InvestorDeal, $this>
     */
    public function pool(): BelongsTo
    {
        return $this->belongsTo(InvestorDeal::class, 'investor_deal_id');
    }

    /**
     * @return BelongsTo<InvestmentPeriod, $this>
     */
    public function effectivePeriod(): BelongsTo
    {
        return $this->belongsTo(InvestmentPeriod::class, 'effective_period_id');
    }

    /**
     * @return BelongsTo<InvestorWalletEntry, $this>
     */
    public function appliedEntry(): BelongsTo
    {
        return $this->belongsTo(InvestorWalletEntry::class, 'applied_entry_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function requestedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    public function isPending(): bool
    {
        return $this->status === CapitalRequestStatus::Pending;
    }

    /** Whether a person may still call it off — only before it has taken effect. */
    public function isCancellable(): bool
    {
        return $this->status->isCancellable();
    }
}
