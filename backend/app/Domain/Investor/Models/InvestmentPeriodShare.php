<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * نصيبُ مستثمرٍ واحد من فترةٍ واحدة، مجمّداً كما قُسِّم به مالُها.
 *
 * يُكتب مرّةً عند الإقفال ولا يُمسّ بعدها؛ تفصيلُ لماذا يُخزَّن ما يمكن حسابُه في ترحيله.
 */
class InvestmentPeriodShare extends Model
{
    use Auditable, SoftDeletes;

    protected $guarded = [];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'units' => 'decimal:6',
            'share_percent' => 'decimal:6',
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
