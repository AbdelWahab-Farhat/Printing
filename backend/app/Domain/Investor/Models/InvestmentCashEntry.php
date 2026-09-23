<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Investor\Enums\CashEntryType;
use Database\Factories\InvestmentCashEntryFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * صفٌّ في خزينة الصندوق — دفترٌ يُضاف إليه ولا يُعدَّل.
 *
 * تفصيلُ لماذا تتحرّك الخزينة عند **التحصيل** لا عند التسليم مكتوبٌ في
 * {@see CashEntryType}. وما يهمّ هنا: **المبلغُ موجبٌ دائماً والاتجاهُ من النوع**، على شكل
 * `order_payments` و`investor_wallet_entries` حرفياً — فلا صفَّ سالباً في أيّ دفترٍ في هذه
 * الميزة، ولا مجالَ لإشارةٍ تُقرأ خطأً.
 *
 * **ولا تُعدَّل صفوفُه.** التصحيحُ صفٌّ عكسيّ يشير للخلف، والعكسُ مرّةً واحدة بفهرسٍ في القاعدة.
 */
#[UseFactory(InvestmentCashEntryFactory::class)]
class InvestmentCashEntry extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentCashEntryFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => CashEntryType::class,
            'amount' => 'decimal:2',
            'occurred_at' => 'datetime',
        ];
    }

    /**
     * الصفُّ الذي يُبطله هذا — إن كان عكساً.
     *
     * @return BelongsTo<self, $this>
     */
    public function reversedEntry(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_entry_id');
    }

    /**
     * الصفُّ الذي أبطله، إن وُجد.
     *
     * `HasOne` لأن الفهرس الفريد خلف `reverses_entry_id` يجعل الثانيَ مستحيلاً. وهو الاتجاهُ
     * المفيد في تقرير: «كلُّ صفٍّ ما زال قائماً» هو `whereDoesntHave('reversedBy')`، بلا رايةٍ
     * على الأصل ينساها أحد.
     *
     * @return HasOne<self, $this>
     */
    public function reversedBy(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_entry_id');
    }

    /**
     * النوعُ الذي يُقرأ منه الاتجاه.
     *
     * العكسُ لا اتجاهَ له من نفسه — يأخذ نوعَ الصفّ الذي يُبطله ثم يُقلَب. وصفُّ عكسٍ يتيمٌ —
     * لا يقع، لأن العمود مقيَّد — يُقرأ محايداً بدل أن يرمي في منتصف حسابِ رصيد.
     */
    private function effectiveType(): ?CashEntryType
    {
        if ($this->type !== CashEntryType::Reversal) {
            return $this->type;
        }

        return $this->reversedEntry?->type;
    }

    /** المبلغُ بإشارته: موجبٌ لما يدخل، سالبٌ لما يخرج، ومقلوبٌ على العكس. */
    public function signedAmount(): string
    {
        $type = $this->effectiveType();

        if ($type === null) {
            return '0.00';
        }

        $amount = (string) $this->amount;
        $inflow = $type->isInflow();

        if ($this->type === CashEntryType::Reversal) {
            $inflow = ! $inflow;
        }

        return $inflow ? $amount : bcmul($amount, '-1', 2);
    }
}
