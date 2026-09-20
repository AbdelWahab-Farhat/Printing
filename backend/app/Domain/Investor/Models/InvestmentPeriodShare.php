<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use Database\Factories\InvestmentPeriodShareFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * How one period's profit was divided, per investor — written once, at the close.
 *
 * This is what `investor_deal_shares.share_percent` used to be, moved to where it belongs. A
 * percentage on a pool's roster would have to be rewritten every month and would be a second answer
 * to a question the ledger already answers; a percentage here is the **outcome** of one period and
 * never moves again, because the money was divided on it.
 *
 * `net_share` is signed — a losing period wrote a negative share down against his capital.
 */
#[UseFactory(InvestmentPeriodShareFactory::class)]
#[Fillable([])]
class InvestmentPeriodShare extends Model
{
    /** @use HasFactory<InvestmentPeriodShareFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'capital' => 'decimal:2',
            'share_percent' => 'decimal:4',
            'net_share' => 'decimal:2',
            'is_company' => 'boolean',
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
     * @return BelongsTo<Investor, $this>
     */
    public function investor(): BelongsTo
    {
        return $this->belongsTo(Investor::class);
    }
}
