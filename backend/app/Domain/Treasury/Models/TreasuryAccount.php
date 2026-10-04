<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Treasury\Enums\AccountKind;
use Database\Factories\TreasuryAccountFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A place money is: الكاش الرئيسي, المصرف, مصرف علي, ليبيانا, النورس.
 *
 * **No balance column.** The balance is the sum of {@see TreasuryMovement} rows — ask
 * `AccountBalances` for it. `kind`, `system_code` and `created_by` are stamped by the Action and
 * never fillable: a payload that could set `system_code` could redirect the Nawris webhook.
 *
 * @property ?int $pickup_city_id the «استلام مكتب» branch whose cash lands here — §١٩
 * @property ?int $vendor_id the vendor a payable is the debt to — §٢٠. Never fillable: only the
 *                           purchase-order context opens one, through `TreasuryService`
 */
#[UseFactory(TreasuryAccountFactory::class)]
#[Fillable(['name', 'holder_user_id', 'is_default', 'is_active', 'is_collected', 'notes'])]
class TreasuryAccount extends Model implements HasAuditTrail
{
    /** @use HasFactory<TreasuryAccountFactory> */
    use Auditable, HasFactory, SoftDeletes;

    public const NAWRIS = 'nawris';

    /**
     * «مبالغ زائدة للزبائن» — the payable holding what customers paid beyond their orders, until
     * each excess is refunded or kept. Opened the first time one is taken; moved by the orders'
     * ledger alone, like a vendor's payable by its purchase orders.
     */
    public const CUSTOMER_EXCESS = 'customer_excess';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'kind' => AccountKind::class,
            'is_default' => 'boolean',
            'is_active' => 'boolean',
            // «يُجمَع عند التسوية» — false keeps this account's order money where it landed.
            'is_collected' => 'boolean',
        ];
    }

    /**
     * @param  Builder<self>  $query
     */
    public function scopeActive(Builder $query): void
    {
        $query->where('is_active', true);
    }

    /** Whether code depends on this account by its system code — the Nawris account. */
    public function isSystem(): bool
    {
        return $this->system_code !== null;
    }

    /**
     * A vendor's payable: purchase orders and vendor payments move it, and nothing by hand —
     * the vendor's own screens hold the reasons, and a hand transfer would leave them behind.
     */
    public function isVendorPayable(): bool
    {
        return $this->vendor_id !== null;
    }

    /**
     * «مبالغ زائدة للزبائن»: the orders' payments and refunds move it, and nothing by hand — the
     * same line a vendor's payable holds. A hand transfer would part it from what the orders say
     * their customers are owed.
     */
    public function isCustomerExcessPayable(): bool
    {
        return $this->system_code === self::CUSTOMER_EXCESS;
    }

    /** Whether this person may read the account without `treasury.view` — it is in their name. */
    public function isHeldBy(?User $user): bool
    {
        return $user !== null && (int) $this->holder_user_id === (int) $user->getKey();
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function holder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'holder_user_id');
    }

    /**
     * Where this custody's money goes at «تم التسوية» when nobody picks. Custody only.
     *
     * @return BelongsTo<self, $this>
     */
    public function settlesInto(): BelongsTo
    {
        return $this->belongsTo(self::class, 'settles_into_account_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * @return HasMany<TreasuryMovement, $this>
     */
    public function movements(): HasMany
    {
        return $this->hasMany(TreasuryMovement::class, 'account_id');
    }
}
