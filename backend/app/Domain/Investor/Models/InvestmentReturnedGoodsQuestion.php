<?php

declare(strict_types=1);

namespace App\Domain\Investor\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\Models\StockItem;
use App\Domain\Inventory\Models\StockMovement;
use App\Domain\Investor\Enums\ReturnedGoodsVerdict;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderItem;
use Database\Factories\InvestmentReturnedGoodsQuestionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * «بضاعة راجعة من طلبية ملغاة: صالحة أم تالفة؟»
 *
 * The one fact this system cannot work out for itself. When a printed order is cancelled, the
 * material is credited back to the shelf **as good stock** — and paper that has been through a
 * press is not good stock. The movement ledger records quantities, not whether there is ink on
 * them.
 *
 * So it is asked of a person, and **the period will not close until it is answered**. That friction
 * is deliberate: the alternative is a distribution computed on goods that do not exist, paid into
 * wallets it can be withdrawn from.
 *
 * `quantity` and `cost` are read off the credit-back when the question is raised, not when it is
 * answered — the shelf will have moved on by then, and the answer must be about what came back.
 */
#[UseFactory(InvestmentReturnedGoodsQuestionFactory::class)]
#[Fillable(['notes'])]
class InvestmentReturnedGoodsQuestion extends Model implements HasAuditTrail
{
    /** @use HasFactory<InvestmentReturnedGoodsQuestionFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'verdict' => ReturnedGoodsVerdict::class,
            'quantity' => 'decimal:3',
            'cost' => 'decimal:2',
            'answered_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<InvestorDeal, $this>
     */
    public function pool(): BelongsTo
    {
        return $this->belongsTo(InvestorDeal::class, 'investor_deal_id');
    }

    /**
     * @return BelongsTo<Order, $this>
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * @return BelongsTo<OrderItem, $this>
     */
    public function orderItem(): BelongsTo
    {
        return $this->belongsTo(OrderItem::class);
    }

    /**
     * @return BelongsTo<StockItem, $this>
     */
    public function stockItem(): BelongsTo
    {
        return $this->belongsTo(StockItem::class);
    }

    /**
     * The damage adjustment «تالفة» produced — a movement, not an expense.
     *
     * Ruined paper has to leave the shelf: booked as a cost alone, the pool would still be counted
     * as holding goods it does not have, and the next lorry would be bought with money that was
     * never there.
     *
     * @return BelongsTo<StockMovement, $this>
     */
    public function damageMovement(): BelongsTo
    {
        return $this->belongsTo(StockMovement::class, 'damage_movement_id');
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function answeredBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'answered_by');
    }

    /** Whether this is still holding a close up. */
    public function isOpen(): bool
    {
        return $this->verdict === ReturnedGoodsVerdict::Open;
    }
}
