<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\PurchaseOrder\Enums\VendorPaymentType;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Vendor\Models\Vendor;
use Database\Factories\VendorPaymentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * Money paid to a vendor — optionally for one purchase order — or what was owed on opening day.
 *
 * **Lives beside the purchase order, not the vendor**, because it points at both and the
 * dependency runs PurchaseOrder → Vendor. Append-only like every ledger here: a mistake is a
 * `reversal` row naming the payment it undoes.
 *
 * وتاريخُها على بابها — `GET /vendors/{vendor}/payments/{payment}/logs`: من سجّلها ومتى.
 * و`client_token` يختمه الفعلُ الذي يكتبها، ويُكتب في السجلّ ولا يُرسم.
 */
#[UseFactory(VendorPaymentFactory::class)]
#[Fillable(['amount', 'method', 'reference', 'paid_at', 'notes'])]
class VendorPayment extends Model implements HasAuditTrail
{
    /** @use HasFactory<VendorPaymentFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => VendorPaymentType::class,
            'method' => PaymentMethod::class,
            'amount' => 'decimal:2',
            'paid_at' => 'datetime',
            'receipt_size_bytes' => 'integer',
        ];
    }

    public function isReversed(): bool
    {
        return $this->relationLoaded('reversal') ? $this->reversal !== null : $this->reversal()->exists();
    }

    public function isReversible(): bool
    {
        return $this->type !== VendorPaymentType::Reversal && ! $this->isReversed();
    }

    public function hasReceipt(): bool
    {
        return $this->receipt_path !== null;
    }

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
     * @return BelongsTo<Vendor, $this>
     */
    public function vendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class);
    }

    /**
     * @return BelongsTo<PurchaseOrder, $this>
     */
    public function purchaseOrder(): BelongsTo
    {
        return $this->belongsTo(PurchaseOrder::class);
    }

    /**
     * @return BelongsTo<TreasuryAccount, $this>
     */
    public function treasuryAccount(): BelongsTo
    {
        return $this->belongsTo(TreasuryAccount::class, 'treasury_account_id');
    }

    /**
     * @return BelongsTo<self, $this>
     */
    public function reversesPayment(): BelongsTo
    {
        return $this->belongsTo(self::class, 'reverses_payment_id');
    }

    /**
     * @return HasOne<self, $this>
     */
    public function reversal(): HasOne
    {
        return $this->hasOne(self::class, 'reverses_payment_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
