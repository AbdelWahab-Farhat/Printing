<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Catalog\Models\Product;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\FundPurchaseOrder;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\PoolKind;
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
 * A container for investors' money — and since 2026-09-20 there are two kinds of it.
 *
 * **`kind = 'pool'`** is صندوق: one continuous pool for one material, which never closes. Its
 * **periods** close instead, and its ownership is recomputed from capital at each one. Everything
 * new is a pool. See INVESTMENT-FUND-DESIGN.md.
 *
 * **`kind = 'deal'`** is صفقة, described in full below: one financed purchase of stock, opened
 * against one purchase order and closed when its goods were gone. **Read-only from the day pools
 * arrived, and never rewritten** — the terms on these rows are what was actually agreed, and the
 * columns that freeze them (`investor_funded_percent`, `company_stake`, `printing_sale_price`,
 * the frozen `share_percent` on its shares) go on meaning exactly what they meant. A deal still
 * open at the migration was *folded into* a pool through the ordinary ledger and left closed
 * here, rather than converted in place.
 *
 * Everything from here down describes the صفقة. {@see isPool()} is the one predicate that tells
 * the two apart.
 *
 * ---
 *
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
 *
 * `printing_sale_price` is **سعر السادة**, and it puts a deal on one of two roads for its whole
 * life:
 *
 * - **Set** — the press buys this deal's plain stock off the shelf the moment a printed line
 *   takes it, at this price by weight. The margin is settled there and then, split by the one
 *   {@see investorsCutOf()} both roads share, and nothing that happens to the order afterwards
 *   reaches the investor: not the customer's price, not the press's wages, not a cancellation.
 * - **Null** — the road every deal walked before 2026-09-06: the investors ride the sale itself,
 *   and are paid a share of the delivered order's profit ({@see investorsCutOf()}).
 *
 * The owner's framing: «الشركة نفسها مطبعة — كأننا بنشروه من المستثمر… استلم الزبون ما استلمش،
 * المطبعة تتحمّل». A deal never has both: a draw is priced or it is not, and the two mechanisms
 * are kept apart by `order_items.stock_purchased_at`.
 */
#[UseFactory(InvestorDealFactory::class)]
#[Fillable(['name', 'opened_on', 'notes'])]
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
            'kind' => PoolKind::class,
            'status' => DealStatus::class,
            'investor_profit_share_percent' => 'decimal:2',
            'company_stake' => 'decimal:2',
            'investor_funded_percent' => 'decimal:4',
            // سعر السادة — what the press pays this deal for a unit of its plain stock. Null on
            // every deal that predates the term, and on one funded without it.
            'printing_sale_price' => 'decimal:3',
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
     * The shelves a **pool** owns — always empty on a legacy deal, which uses {@see items()}.
     *
     * Kept apart from `items()` because the two answer different questions: `investor_deal_items`
     * records what a deal was *written against*, quantities and expected prices included, while
     * this is a bare claim whose only content is the unique index behind it.
     *
     * @return HasMany<InvestmentPoolItem, $this>
     */
    public function poolItems(): HasMany
    {
        return $this->hasMany(InvestmentPoolItem::class, 'investor_deal_id');
    }

    /**
     * A **pool's** accounting periods, newest last. Always empty on a legacy deal, which had none:
     * what closed there was the صفقة itself.
     *
     * @return HasMany<InvestmentPeriod, $this>
     */
    public function periods(): HasMany
    {
        return $this->hasMany(InvestmentPeriod::class, 'investor_deal_id');
    }

    /**
     * Capital queued at this pool's boundaries, in both directions.
     *
     * @return HasMany<InvestmentCapitalRequest, $this>
     */
    public function capitalRequests(): HasMany
    {
        return $this->hasMany(InvestmentCapitalRequest::class, 'investor_deal_id');
    }

    /**
     * Material a cancelled printed order gave back, and whether anybody has looked at it yet.
     *
     * Hung off the **pool** rather than off the period, deliberately: a question raised in
     * September and still open in October blocks October's close too, because the goods are still
     * either on the shelf or not. Tying it to the period it happened in would let it expire.
     *
     * @return HasMany<InvestmentReturnedGoodsQuestion, $this>
     */
    public function returnedGoodsQuestions(): HasMany
    {
        return $this->hasMany(InvestmentReturnedGoodsQuestion::class, 'investor_deal_id');
    }

    /**
     * Signed statements of where this pool's money was, newest last.
     *
     * A settlement moves nothing and closes nothing — the pool trades on through it. What it leaves
     * is a dated position somebody approved, and the drift between the two ways of deriving it.
     *
     * @return HasMany<InvestmentSettlement, $this>
     */
    public function settlements(): HasMany
    {
        return $this->hasMany(InvestmentSettlement::class, 'investor_deal_id');
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

    /**
     * Whether this row is a continuous pool rather than one of the صفقات that came before.
     *
     * **The one predicate every «is this the old road or the new one?» question asks**, so that a
     * behaviour which must differ between the two differs in one place. A legacy deal is not a
     * pool that has been closed: it is a different arrangement, frozen as it was agreed.
     */
    public function isPool(): bool
    {
        return $this->kind === PoolKind::Pool;
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
     * its loss, an expense typed on the deal, and since 2026-09-11 the margin سعر السادة makes at
     * the shelf too — because two of them restating it is how a 1,000 customs invoice comes to
     * cost partners who own 750 of the profit 500 of it.
     *
     * **The shelf margin used to be split by ownership alone**, on the reading that a purchase at
     * an agreed price pays for no work and so owes the company no half. The owner settled it the
     * other way on 2026-09-11 — «نعم على اغلب حتى هو بيتوزع 5/5» — so the two roads differ now in
     * *when* a deal is paid and *what* it is paid on, never in how the result is divided.
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

    /** Whether this deal sells its plain stock to the press at an agreed price. */
    public function sellsToThePress(): bool
    {
        return $this->printing_sale_price !== null;
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
