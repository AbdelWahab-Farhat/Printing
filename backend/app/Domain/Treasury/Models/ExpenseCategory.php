<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use Database\Factories\ExpenseCategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * What an expense was for — rent, salaries, what Nawris kept.
 *
 * A table rather than an enum because the owner adds to it. The ones code relies on carry a
 * `code` (`carrier_fee`, `advance`) and are found by it, never by a name somebody can retype.
 *
 * وله تاريخُه على بابه — `GET /treasury/expense-categories/{category}/logs`: من غيّر الاسم ومن
 * أطفأه.
 */
#[UseFactory(ExpenseCategoryFactory::class)]
#[Fillable(['name', 'requires_employee', 'is_active', 'sort_order'])]
class ExpenseCategory extends Model implements HasAuditTrail
{
    /** @use HasFactory<ExpenseCategoryFactory> */
    use Auditable, HasFactory, SoftDeletes;

    public const CARRIER_FEE = 'carrier_fee';

    public const ADVANCE = 'advance';

    protected $table = 'treasury_expense_categories';

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'requires_employee' => 'boolean',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function isSystem(): bool
    {
        return $this->code !== null;
    }
}
