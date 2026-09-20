<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Enums\UnitEntryType;
use Database\Factories\InvestmentUnitFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * حركةٌ واحدة في وحدات مستثمر.
 *
 * العددُ **موجبٌ دائماً**؛ {@see UnitEntryType} يقول ما يعنيه الصفّ، و{@see signedUnits()} هو
 * الموضعُ الوحيد الذي تُطبَّق فيه إشارة. ولا شيء يُعدَّل ولا يُحذف: الخطأ صفٌّ عكسيّ يحمل عددَه
 * كما هو — الشكلُ نفسه الذي يمشي عليه {@see InvestorWalletEntry}.
 */
#[UseFactory(InvestmentUnitFactory::class)]
#[Fillable(['notes'])]
class InvestmentUnit extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentUnitFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => UnitEntryType::class,
            'units' => 'decimal:6',
            'unit_price' => 'decimal:6',
            'amount' => 'decimal:2',
            'locked_until' => 'date',
            'occurred_at' => 'datetime',
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
     * @return BelongsTo<InvestmentPeriod, $this>
     */
    public function period(): BelongsTo
    {
        return $this->belongsTo(InvestmentPeriod::class, 'investment_period_id');
    }

    /**
     * @return BelongsTo<self, $this>
     */
    public function reversedEntry(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_unit_entry_id');
    }

    /**
     * الصفُّ الذي أبطله، إن وُجد — والفهرسُ الفريد يجعل الثانيَ مستحيلاً.
     *
     * @return HasOne<self, $this>
     */
    public function reversedBy(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_unit_entry_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    /** النوعُ الذي يعمل به هذا الصفّ — نوعُه، أو نوعُ الصفّ الذي يعكسه. */
    public function effectiveType(): UnitEntryType
    {
        return $this->type === UnitEntryType::Reversal
            ? ($this->reversedEntry?->type ?? UnitEntryType::Reversal)
            : $this->type;
    }

    /** ما يفعله هذا الصفُّ بعدد الوحدات القائمة، بإشارته. */
    public function signedUnits(): string
    {
        $direction = $this->effectiveType()->direction();

        if ($this->type === UnitEntryType::Reversal) {
            $direction = -$direction;
        }

        return $direction === 0
            ? '0.000000'
            : bcmul((string) $this->units, (string) $direction, 6);
    }

    /** أما زال رأسُ المال الذي اشترى هذه الوحدات محبوساً في هذا اليوم؟ */
    public function isLockedOn(\DateTimeInterface $date): bool
    {
        return $this->locked_until !== null && $this->locked_until->endOfDay() >= $date;
    }
}
