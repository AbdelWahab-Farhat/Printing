<?php

declare(strict_types=1);

namespace App\Domain\EmployeeWallet\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletEntryType;
use App\Domain\EmployeeWallet\Enums\EmployeeWalletMethod;
use App\Domain\EmployeeWallet\Exceptions\EmployeeWalletEntryIsImmutable;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Models\ExpenseCategory;
use App\Domain\Treasury\Models\TreasuryAccount;
use Database\Factories\EmployeeWalletEntryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * حركةٌ واحدة من محفظة موظف. Docs/employees/EMPLOYEE-WALLET-DESIGN.md §٨.
 *
 * المبلغ **موجبٌ دائماً**، و{@see signedAmount()} وحدها تضع الإشارة. لا يُعدَّل شيء ولا يُحذف — الخطأ
 * سطر `reversal` بالمبلغ نفسه — والنموذج يرفض الاثنين، كما تفعل حركة الخزينة.
 */
#[UseFactory(EmployeeWalletEntryFactory::class)]
#[Fillable(['amount', 'reference', 'occurred_at', 'notes'])]
class EmployeeWalletEntry extends Model implements HasAuditTrail
{
    /** @use HasFactory<EmployeeWalletEntryFactory> */
    use Auditable, HasFactory, SoftDeletes;

    protected static function booted(): void
    {
        // سطرٌ مُعدَّل رصيدٌ تغيّر بلا سجلٍّ يقول لماذا.
        static::updating(function (): never {
            throw EmployeeWalletEntryIsImmutable::make();
        });

        static::deleting(function (): never {
            throw EmployeeWalletEntryIsImmutable::cannotBeDeleted();
        });
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => EmployeeWalletEntryType::class,
            'method' => EmployeeWalletMethod::class,
            'amount' => 'decimal:2',
            'occurred_at' => 'datetime',
        ];
    }

    /** أيزيد هذا السطرُ الرصيد. العكسُ ضدُّ السطر الذي يعكسه. */
    public function isCredit(): bool
    {
        if ($this->type === EmployeeWalletEntryType::Reversal) {
            $original = $this->reversedEntry;

            return $original !== null && ! $original->type->isCredit();
        }

        return $this->type->isCredit();
    }

    /** ما يضيفه هذا السطر إلى الرصيد. */
    public function signedAmount(): string
    {
        return $this->isCredit() ? (string) $this->amount : bcmul((string) $this->amount, '-1', 2);
    }

    /** أعكسَه شيء. يقرأ ما حُمّل قبل أن يسأل القاعدة — الكشفُ يسأله لكل سطر. */
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

    /** انظر `OrderPayment::receiptIsImage()` — الجوابُ نفسه من المسار المحفوظ نفسه. */
    public function receiptIsImage(): bool
    {
        if (! $this->hasReceipt()) {
            return false;
        }

        $extension = strtolower(pathinfo((string) $this->receipt_path, PATHINFO_EXTENSION));

        return in_array($extension, ['jpg', 'jpeg', 'png', 'webp'], true);
    }

    /** انظر `OrderPayment::receiptUrl()` — يُبنى لكل طلب، ورابطاً موقَّعاً حيث يوفّره القرص. */
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
     * صاحب المحفظة.
     *
     * @return BelongsTo<User, $this>
     */
    public function employee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id')->withTrashed();
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function treasuryAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class)->withTrashed();
    }

    /**
     * @return BelongsTo<ExpenseCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ExpenseCategory::class, 'expense_category_id')->withTrashed();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }

    /**
     * السطر الذي يعكسه هذا. على العكس وحده.
     *
     * @return BelongsTo<self, $this>
     */
    public function reversedEntry(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_entry_id');
    }

    /**
     * السطر الذي عكس هذا، إن وُجد.
     *
     * @return HasOne<self, $this>
     */
    public function reversal(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_entry_id');
    }
}
