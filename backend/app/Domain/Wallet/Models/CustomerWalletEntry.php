<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Wallet\Enums\TopUpMethod;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Exceptions\WalletEntryIsImmutable;
use Database\Factories\CustomerWalletEntryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * One movement of one customer's wallet. Docs/payments/CUSTOMER-WALLET.md §٤.
 *
 * The amount is **always positive**; {@see signedAmount()} is the only place a sign is applied.
 * Nothing is edited or deleted — a mistake is a `reversal` row carrying the original amount — and
 * the model refuses both, as a treasury movement does.
 *
 * `order_id` and `order_payment_id` are plain columns here, not relations: the wallet never
 * reaches into the order context. The order's side names this row through its own query.
 */
#[UseFactory(CustomerWalletEntryFactory::class)]
#[Fillable(['amount', 'reference', 'occurred_at', 'notes'])]
class CustomerWalletEntry extends Model
{
    /** @use HasFactory<CustomerWalletEntryFactory> */
    use Auditable, HasFactory, SoftDeletes;

    protected static function booted(): void
    {
        // An edited row is a balance changed with no record of why.
        static::updating(function (): never {
            throw WalletEntryIsImmutable::make();
        });

        static::deleting(function (): never {
            throw WalletEntryIsImmutable::cannotBeDeleted();
        });
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => WalletEntryType::class,
            'method' => TopUpMethod::class,
            'amount' => 'decimal:2',
            'occurred_at' => 'datetime',
        ];
    }

    /**
     * Whether this row adds to the balance. A reversal is the opposite of the row it undoes.
     */
    public function isCredit(): bool
    {
        if ($this->type === WalletEntryType::Reversal) {
            $original = $this->reversedEntry;

            return $original !== null && ! $original->type->isCredit();
        }

        return $this->type->isCredit();
    }

    /** What this row adds to the balance. */
    public function signedAmount(): string
    {
        return $this->isCredit() ? (string) $this->amount : bcmul((string) $this->amount, '-1', 2);
    }

    /**
     * Whether something has undone this row. Reads what was loaded before it asks the database —
     * a statement asks it of every row.
     */
    public function isReversed(): bool
    {
        if ($this->relationLoaded('reversal')) {
            return $this->reversal !== null;
        }

        return $this->reversal()->exists();
    }

    public function hasReceipt(): bool
    {
        return $this->receipt_path !== null;
    }

    /** See `OrderPayment::receiptIsImage()` — the same answer from the same stored path. */
    public function receiptIsImage(): bool
    {
        if (! $this->hasReceipt()) {
            return false;
        }

        $extension = strtolower(pathinfo((string) $this->receipt_path, PATHINFO_EXTENSION));

        return in_array($extension, ['jpg', 'jpeg', 'png', 'webp'], true);
    }

    /** See `OrderPayment::receiptUrl()` — built per request, a signed link where the disk has one. */
    public function receiptUrl(): ?string
    {
        if (! $this->hasReceipt()) {
            return null;
        }

        $disk = Storage::disk($this->receipt_disk);

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl($this->receipt_path, now()->addMinutes(config('media.temporary_url_minutes')))
            : $disk->url($this->receipt_path);
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function treasuryAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class)->withTrashed();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    /**
     * The row this one undoes. Set on a reversal and null on everything else.
     *
     * @return BelongsTo<self, $this>
     */
    public function reversedEntry(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_entry_id');
    }

    /**
     * The row that undoes this one, if any.
     *
     * @return HasOne<self, $this>
     */
    public function reversal(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_entry_id');
    }
}
