<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use Database\Factories\ShippingCompanyFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * A company that carries our parcels.
 *
 * A record rather than a name typed onto each order: one company, one spelling, one phone
 * number, and a way to stop offering it without erasing the orders it already carried.
 *
 * **Orders keep a snapshot of the name beside the key**, exactly as they do for the city. What
 * an order says carried it is a fact about that day, and renaming a row here must not rewrite it.
 */
#[UseFactory(ShippingCompanyFactory::class)]
#[Fillable(['name', 'phone', 'notes', 'is_active'])]
class ShippingCompany extends Model implements HasAuditTrail
{
    /** @use HasFactory<ShippingCompanyFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
