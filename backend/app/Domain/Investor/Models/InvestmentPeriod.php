<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Support\GraceWindow;
use Database\Factories\InvestmentPeriodFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * One accounting period of one pool — what repeats, now that the صفقة does not.
 *
 * **Two halves.** While it is open it carries nothing but its dates: every figure about it is
 * derived from the ledger and the cost layers, as everything in this feature is. When it closes it
 * is handed a snapshot of what it was divided on, and that snapshot never moves again — the money
 * was paid out on those numbers, so recomputing them from today's data would answer a different
 * question.
 *
 * **Nothing here decides when a period ends.** `ends_on` is written when it opens, from the company
 * calendar, and the admin may move it while the period is open. A closed period is immutable; there
 * is no path in this model that says otherwise.
 */
#[UseFactory(InvestmentPeriodFactory::class)]
#[Fillable(['ends_on', 'notes'])]
class InvestmentPeriod extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentPeriodFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => PeriodStatus::class,
            'starts_on' => 'date',
            'ends_on' => 'date',
            'closed_at' => 'datetime',
            'opening_cash' => 'decimal:2',
            'closing_cash' => 'decimal:2',
            'opening_stock_cost' => 'decimal:2',
            'closing_stock_cost' => 'decimal:2',
            'realized_margin' => 'decimal:2',
            'deductible_expenses' => 'decimal:2',
            'damage_cost' => 'decimal:2',
            'shortage_cost' => 'decimal:2',
            'net_profit' => 'decimal:2',
            'investor_share_percent_applied' => 'decimal:2',
            'investor_capital_weight_applied' => 'decimal:4',
            'total_pool_capital' => 'decimal:2',
            'total_investor_capital' => 'decimal:2',
        ];
    }

    /**
     * @return BelongsTo<InvestorDeal, $this>
     */
    public function pool(): BelongsTo
    {
        return $this->belongsTo(InvestorDeal::class, 'investor_deal_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function closedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'closed_by');
    }

    /**
     * The capital that joined or left at this boundary.
     *
     * @return HasMany<InvestmentCapitalRequest, $this>
     */
    public function capitalRequests(): HasMany
    {
        return $this->hasMany(InvestmentCapitalRequest::class, 'effective_period_id');
    }

    /**
     * What the close gave each participant — **frozen, and never recomputed**.
     *
     * The weights that were actually applied and the amounts that were actually paid. Empty while
     * the period is open, because nothing has been divided yet. This is what answers «لماذا أخذت
     * هذا المبلغ في سبتمبر؟» in December, when today's weights bear no relation to September's.
     *
     * @return HasMany<InvestmentPeriodShare, $this>
     */
    public function shares(): HasMany
    {
        return $this->hasMany(InvestmentPeriodShare::class, 'investment_period_id');
    }

    public function isOpen(): bool
    {
        return $this->status === PeriodStatus::Open;
    }

    /**
     * Still open after the day it was meant to end.
     *
     * **Nothing closes a period but a person.** A close divides profit, writes losses against
     * capital and releases money into wallets it can be withdrawn from that afternoon — and it is
     * legitimately refused while a returned-goods question is unanswered. A schedule doing that at
     * three in the morning, or failing silently every night because of one question, is worse than
     * a mark on a screen somebody looks at.
     *
     * So the date is not a deadline the system enforces; it is one it **reports**. A period that
     * runs long keeps accruing perfectly correctly — what goes wrong is only that its dates stop
     * describing its contents, and this is what says so.
     */
    public function isOverdue(): bool
    {
        return $this->isOpen()
            && $this->ends_on !== null
            && $this->ends_on->isBefore(Carbon::today());
    }

    /** How many days past its end it has run, or zero when it has not. */
    public function daysOverdue(): int
    {
        return $this->isOverdue()
            ? (int) $this->ends_on->diffInDays(Carbon::today())
            : 0;
    }

    /**
     * The last day capital may still join **this** period.
     *
     * The grace window, measured from the day the period began. Read by
     * {@see GraceWindow}, which is the only place the comparison
     * against today is made — a second caller doing its own date arithmetic is how two screens come
     * to disagree about a boundary day.
     */
    public function graceWindowEndsOn(int $graceDays): Carbon
    {
        return $this->starts_on->copy()->addDays(max(0, $graceDays));
    }

    /** Whether a date falls inside this period at all. */
    public function covers(Carbon $date): bool
    {
        return $date->betweenIncluded($this->starts_on, $this->ends_on);
    }
}
