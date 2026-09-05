<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Catalog\Models\Product;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\FundPurchaseOrder;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Support\Money;
use Database\Factories\InvestorDealFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;

/**
 * صفقة — one financed purchase of stock.
 *
 * **It holds no money and no quantity.** Everything a screen shows about it is derived: the
 * stock from the cost layers that carry its id, the money from `investor_wallet_entries`. A
 * cached profit column could only ever disagree with the ledger, and the ledger is the truth.
 *
 * `investor_profit_share_percent` is the investors' half of *this* deal, seeded from the company
 * default and frozen the moment the deal opens. Renegotiating a live deal is a new deal.
 *
 * `investor_funded_percent` is the fraction of the goods their money actually bought, and
 * `company_stake` the dinars it did not — «الباقي على الشركة». Both are written once by
 * {@see FundPurchaseOrder} and frozen with the rest; a deal built by
 * hand keeps the defaults, 100 and 0, and behaves as every deal did before them.
 */
#[UseFactory(InvestorDealFactory::class)]
#[Fillable(['opened_on', 'notes'])]
class InvestorDeal extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestorDealFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => DealStatus::class,
            'investor_profit_share_percent' => 'decimal:2',
            'company_stake' => 'decimal:2',
            'investor_funded_percent' => 'decimal:4',
            'opened_on' => 'date',
            'opened_at' => 'datetime',
            'closed_at' => 'datetime',
        ];
    }

    /** «D25» — reserved before the insert, exactly as an order's number is. */
    protected static function booted(): void
    {
        static::creating(function (self $deal): void {
            if ($deal->code === null) {
                $id = (int) DB::scalar(
                    "select nextval(pg_get_serial_sequence('investor_deals', 'id'))"
                );

                $deal->id = $id;
                $deal->code = 'D'.$id;
            }
        });
    }

    /**
     * A label for the screen. **Never used to find this deal's stock** — that is always the cost
     * layers carrying its id, because a product does not own stock here and one shelf can stand
     * behind several products.
     *
     * @return BelongsTo<Product, $this>
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * The shelves this deal funds.
     *
     * @return HasMany<InvestorDealItem, $this>
     */
    public function items(): HasMany
    {
        return $this->hasMany(InvestorDealItem::class);
    }

    /**
     * Who is in it, and for what percentage.
     *
     * @return HasMany<InvestorDealShare, $this>
     */
    public function shares(): HasMany
    {
        return $this->hasMany(InvestorDealShare::class)->orderBy('id');
    }

    /**
     * @return HasMany<InvestorDealSupply, $this>
     */
    public function supplies(): HasMany
    {
        return $this->hasMany(InvestorDealSupply::class);
    }

    /**
     * @return HasMany<InvestorDealExpense, $this>
     */
    public function expenses(): HasMany
    {
        return $this->hasMany(InvestorDealExpense::class)->orderBy('incurred_on')->orderBy('id');
    }

    /**
     * @return HasMany<InvestorWalletEntry, $this>
     */
    public function walletEntries(): HasMany
    {
        return $this->hasMany(InvestorWalletEntry::class)->orderBy('occurred_at')->orderBy('id');
    }

    /** Whether the terms may still be rewritten. */
    public function isEditable(): bool
    {
        return $this->status->isEditable();
    }

    /**
     * Whether this deal is one purchase order's paperwork — and so has its ownership frozen.
     *
     * Such a deal fixed what fraction of the goods the partners bought when it was funded, so it
     * takes no more capital and its order takes no more edits. A deal assembled by hand has no
     * such basis and keeps behaving as before.
     */
    public function isBornFromPurchaseOrder(): bool
    {
        return $this->purchase_order_id !== null;
    }

    /**
     * The investors' cut of a figure earned or lost on this deal's goods.
     *
     * Two factors, both frozen when the deal opened — the fraction of the goods their money
     * bought, and the share of that fraction's result they keep:
     *
     * ```
     * cut = amount × investor_funded_percent ÷ 100 × investor_profit_share_percent ÷ 100
     * ```
     *
     * **One definition, called from everywhere a dinar reaches a wallet** — the order's profit,
     * its loss, and an expense typed on the deal — because two of them restating it is how a
     * 1,000 customs invoice comes to cost partners who own 750 of the profit 500 of it.
     *
     * The sign travels with the amount; the magnitude is rounded once at the end, and a result
     * that rounds to nothing is returned as plain zero rather than «-0.00».
     */
    public function investorsCutOf(string $amount): string
    {
        $negative = bccomp($amount, '0', Money::SCALE) < 0;
        $magnitude = $negative ? substr($amount, 1) : $amount;

        $cut = Money::round(bcdiv(
            bcmul(
                bcmul($magnitude, (string) $this->investor_funded_percent, 8),
                (string) $this->investor_profit_share_percent,
                8,
            ),
            '10000',
            8,
        ));

        return $negative && bccomp($cut, '0', Money::SCALE) !== 0 ? '-'.$cut : $cut;
    }

    /**
     * Whether any cost layer still carries this deal with stock left on it.
     *
     * Asked before closing, and read straight off `stock_batches` rather than off a column, for
     * the reason the whole model rests on: the layers are where the truth is.
     */
    public function stillHoldsStock(): bool
    {
        return DB::table('stock_batches')
            ->where('investor_deal_id', $this->getKey())
            ->whereNull('deleted_at')
            ->where('quantity_remaining', '>', 0)
            ->exists();
    }
}
