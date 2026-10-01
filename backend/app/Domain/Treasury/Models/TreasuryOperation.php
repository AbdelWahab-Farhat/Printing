<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Actions\RecordOperation;
use App\Domain\Treasury\Enums\OperationType;
use Database\Factories\TreasuryOperationFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Something a person did to the treasury by hand — or that «تم التسوية» did for them.
 *
 * **Append-only, like the movements it writes.** Nothing is fillable: every column is stamped by
 * {@see RecordOperation}. A correction is a second operation pointing back at this one through
 * `reverses_operation_id`.
 */
#[UseFactory(TreasuryOperationFactory::class)]
class TreasuryOperation extends Model implements HasAuditTrail
{
    /** @use HasFactory<TreasuryOperationFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => OperationType::class,
            'amount' => 'decimal:2',
            'system_balance' => 'decimal:2',
            'counted_balance' => 'decimal:2',
            'occurred_at' => 'datetime',
        ];
    }

    public function isReversal(): bool
    {
        return $this->reverses_operation_id !== null;
    }

    public function isReversed(): bool
    {
        return $this->reversedBy()->exists();
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function fromAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class, 'from_account_id');
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function toAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class, 'to_account_id');
    }

    /**
     * @return BelongsTo<ExpenseCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ExpenseCategory::class, 'category_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function employee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'employee_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    /**
     * @return BelongsTo<self, $this>
     */
    public function reversesOperation(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_operation_id');
    }

    /**
     * @return HasOne<self, $this>
     */
    public function reversedBy(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_operation_id');
    }

    /**
     * @return HasMany<TreasuryMovement, $this>
     */
    public function movements(): HasMany
    {
        return $this->hasMany(TreasuryMovement::class, 'operation_id');
    }
}
