<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use Database\Factories\InvestmentRealizedEarningFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One figure a pool earned, before anybody's share of it is known.
 *
 * **The only undivided amount in this feature.** A صفقة split an order's profit into per-investor
 * rows the moment it landed, because its percentages were frozen at funding. A صندوق recomputes
 * ownership from capital at the close, so on the day a sale is realized nobody knows yet who gets
 * what — the margin is earned into the period and divided at its end.
 *
 * `amount` is **signed**, unlike the wallet ledger: this is one party's P&L, where a lorry that
 * landed dearer than the price agreed for it makes a genuinely negative margin.
 *
 * A correction is a further row carrying the **difference**, in whichever period is open when the
 * correction happens — never an edit to a period that has already been divided and paid.
 */
#[UseFactory(InvestmentRealizedEarningFactory::class)]
#[Fillable([])]
class InvestmentRealizedEarning extends Model
{
    /** @use HasFactory<InvestmentRealizedEarningFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'occurred_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<InvestmentPeriod, $this>
     */
    public function period(): BelongsTo
    {
        return $this->belongsTo(InvestmentPeriod::class, 'investment_period_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
