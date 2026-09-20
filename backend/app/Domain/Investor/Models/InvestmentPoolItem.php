<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Investor\Actions\SyncPoolItems;
use Database\Factories\InvestmentPoolItemFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One shelf a pool owns.
 *
 * **It carries no figures, and that is deliberate.** How much of this shelf the pool holds, what
 * it cost and what has been sold off it are all read from the cost layers carrying the pool's id
 * — the standing rule of this schema. A quantity here could only ever disagree with the layers.
 *
 * The row's whole job is the claim itself, and the unique index behind it: **a stock item belongs
 * to at most one pool**. That is what makes «which pool financed this shelf?» a question with one
 * answer, and it is enforced by the database rather than by this model, because a cost layer
 * holds one container id and a second claimant would be silently ignored rather than refused.
 *
 * Nothing here is fillable. Which pool owns which shelf is decided by
 * {@see SyncPoolItems} after Catalog has been asked whether the shelf
 * may be invested in at all, and a payload that could set either column could route an investor's
 * money to a heading he was never offered.
 */
#[UseFactory(InvestmentPoolItemFactory::class)]
#[Fillable([])]
class InvestmentPoolItem extends Model
{
    /** @use HasFactory<InvestmentPoolItemFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return BelongsTo<InvestorDeal, $this>
     */
    public function pool(): BelongsTo
    {
        return $this->belongsTo(InvestorDeal::class, 'investor_deal_id');
    }

    /**
     * @return BelongsTo<StockItem, $this>
     */
    public function stockItem(): BelongsTo
    {
        return $this->belongsTo(StockItem::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
