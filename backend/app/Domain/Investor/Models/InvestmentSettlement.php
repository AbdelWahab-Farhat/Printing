<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Queries\SettlementSnapshot;
use Database\Factories\InvestmentSettlementFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;

/**
 * التسوية — a dated, signed statement of where one pool's money is.
 *
 * **A review point, not a close.** The pool goes on trading through it; no money moves, no stock is
 * liquidated, no period is touched. What it leaves behind is a snapshot somebody approved and the
 * **drift** — the gap between what the ledger says the pool is worth and what an independent walk
 * of its movements can account for.
 *
 * The figures are frozen here rather than derived on demand for the reason `investment_periods`
 * freezes its close columns: what somebody signed in March must still read in March's terms in
 * December. That is a historical record, not a cached balance.
 *
 * `drift` is the one figure that could not be derived on demand in any useful sense, because it is
 * a comparison **of two derivations** that never consult each other — see
 * {@see SettlementSnapshot}.
 */
#[UseFactory(InvestmentSettlementFactory::class)]
#[Fillable(['notes'])]
class InvestmentSettlement extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentSettlementFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'settled_on' => 'date',
            'total_capital' => 'decimal:2',
            'investor_capital' => 'decimal:2',
            'company_capital' => 'decimal:2',
            'deployable_cash' => 'decimal:2',
            'stock_at_cost' => 'decimal:2',
            'undeployed_current_profit' => 'decimal:2',
            'receivables' => 'decimal:2',
            'liabilities' => 'decimal:2',
            'distributed_profit_to_date' => 'decimal:2',
            'damage_to_date' => 'decimal:2',
            'shortage_to_date' => 'decimal:2',
            'reconstructed_cash' => 'decimal:2',
            'drift' => 'decimal:2',
        ];
    }

    /** «T25» — reserved before the insert, exactly as a deal's code is. */
    protected static function booted(): void
    {
        static::creating(function (self $settlement): void {
            if ($settlement->code === null) {
                $id = (int) DB::scalar(
                    "select nextval(pg_get_serial_sequence('investment_settlements', 'id'))"
                );

                $settlement->id = $id;
                $settlement->code = 'T'.$id;
            }
        });
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
    public function periodFrom(): BelongsTo
    {
        return $this->belongsTo(InvestmentPeriod::class, 'period_from_id');
    }

    /**
     * @return BelongsTo<InvestmentPeriod, $this>
     */
    public function periodTo(): BelongsTo
    {
        return $this->belongsTo(InvestmentPeriod::class, 'period_to_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Whether the two derivations disagreed.
     *
     * **A finding, not an error.** Nothing here corrects it, and nothing absorbs it: the figure
     * stands on the record until somebody explains it, which is the only treatment that does not
     * eventually teach people to ignore it.
     */
    public function hasDrift(): bool
    {
        return bccomp((string) $this->drift, '0', 2) !== 0;
    }
}
