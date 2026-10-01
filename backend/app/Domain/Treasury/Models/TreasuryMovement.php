<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Actions\PostMovement;
use App\Domain\Treasury\Enums\MovementDirection;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Exceptions\MovementIsImmutable;
use Database\Factories\TreasuryMovementFactory;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One effect on one account: +50 into المصرف, −300 out of الخزنة.
 *
 * **The ledger itself.** Only {@see PostMovement} writes one, nothing updates one, and a mistake
 * is a second row pointing back through `reverses_movement_id` — with the same kind and the
 * opposite direction, so every per-kind total is already net.
 */
#[UseFactory(TreasuryMovementFactory::class)]
class TreasuryMovement extends Model
{
    /** @use HasFactory<TreasuryMovementFactory> */
    use Auditable, HasFactory, SoftDeletes;

    protected static function booted(): void
    {
        // An edited movement is a balance changed with no record of why — the one thing this
        // table exists to make impossible.
        static::updating(function (): never {
            throw MovementIsImmutable::make();
        });

        // والحذفُ — ولو ناعماً — يُسقط الحركة من كل رصيد كما يُسقطها التعديل، بلا سطرٍ يقول لماذا.
        // وهو يمرّ بـ`deleting` في الحالين: الناعمُ والنهائيّ.
        static::deleting(function (): never {
            throw MovementIsImmutable::cannotBeDeleted();
        });
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'direction' => MovementDirection::class,
            'kind' => MovementKind::class,
            'amount' => 'decimal:2',
            'occurred_at' => 'datetime',
        ];
    }

    /** The amount with its sign: what this row adds to its account's balance. */
    public function signedAmount(): string
    {
        return $this->direction === MovementDirection::In
            ? (string) $this->amount
            : bcmul((string) $this->amount, '-1', 2);
    }

    public function isReversal(): bool
    {
        return $this->reverses_movement_id !== null;
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function account(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class, 'account_id');
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function counterpartAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class, 'counterpart_account_id');
    }

    /**
     * @return BelongsTo<TreasuryOperation, $this>
     */
    public function operation(): BelongsTo
    {
        return $this->belongsTo(TreasuryOperation::class, 'operation_id');
    }

    /**
     * @return BelongsTo<self, $this>
     */
    public function reversesMovement(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_movement_id');
    }

    /**
     * @return HasOne<self, $this>
     */
    public function reversedBy(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_movement_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
