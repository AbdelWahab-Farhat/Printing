<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Inventory\Models\StockBatch;
use App\Domain\Investor\Enums\FundExpenseChargeKind;
use App\Domain\Order\Models\Order;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * جزءٌ من مصروفٍ على البضاعة — Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٤.
 *
 * **مجموعُ صفوف المصروف = مبلغُه بقرشه**: ما رفع تكلفةَ الرفّ، وما كُتب على المستهلكين، وفرقُ
 * التقريب. وصفُّ `consumer` أو `rounding` هو **مصدرٌ** لـ`PostDealShare`: صفوفُ المحفظة التي
 * يكتبها تحمل `source_type = fund_expense_charge` ورقمَه، وفترتُه فترةُ `charged_on`.
 *
 * **لا يُعدَّل.** التصحيحُ صفٌّ يشير إلى أصله بـ`reverses_charge_id` بمبلغٍ معاكس.
 */
class FundExpenseCharge extends Model implements HasAuditTrail
{
    use Auditable, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'kind' => FundExpenseChargeKind::class,
            'quantity' => 'decimal:3',
            'unit_amount' => 'decimal:3',
            'amount' => 'decimal:2',
            'charged_on' => 'date',
        ];
    }

    /**
     * @return BelongsTo<InvestorDealExpense, $this>
     */
    public function expense(): BelongsTo
    {
        return $this->belongsTo(InvestorDealExpense::class, 'investor_deal_expense_id');
    }

    /**
     * @return BelongsTo<StockBatch, $this>
     */
    public function batch(): BelongsTo
    {
        return $this->belongsTo(StockBatch::class, 'stock_batch_id');
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    /**
     * @return BelongsTo<InvestmentPeriod, $this>
     */
    public function period(): BelongsTo
    {
        return $this->belongsTo(InvestmentPeriod::class, 'investment_period_id');
    }

    /**
     * العكسُ الذي أبطله، إن وُجد — واحدٌ بحكم الفهرس الفريد.
     *
     * @return HasOne<self, $this>
     */
    public function reversedBy(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_charge_id');
    }
}
