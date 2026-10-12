<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Whether the shop offers one EzonePay method, and how much one customer may top up with it per
 * day, month and year. Empty limit: no cap. Seeded for every method, active.
 */
#[Fillable(['is_active', 'daily_limit', 'monthly_limit', 'yearly_limit'])]
class OnlinePaymentMethod extends Model
{
    use Auditable, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'method' => OnlineMethod::class,
            'is_active' => 'boolean',
            'daily_limit' => 'decimal:2',
            'monthly_limit' => 'decimal:2',
            'yearly_limit' => 'decimal:2',
        ];
    }
}
