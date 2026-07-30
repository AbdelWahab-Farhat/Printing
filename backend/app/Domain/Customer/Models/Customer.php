<?php

declare(strict_types=1);

namespace App\Domain\Customer\Models;

use App\Domain\Customer\Actions\AllocateCustomerIdentifier;
use Database\Factories\CustomerFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * A customer of the printing business.
 *
 * `code` is deliberately absent from the fillable list: it is allocated by
 * {@see AllocateCustomerIdentifier} and must never be
 * settable from a request.
 */
#[UseFactory(CustomerFactory::class)]
#[Fillable(['name', 'primary_phone', 'is_active'])]
class Customer extends Model
{
    /** @use HasFactory<CustomerFactory> */
    use HasFactory;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<CustomerShop, $this>
     */
    public function shops(): HasMany
    {
        return $this->hasMany(CustomerShop::class);
    }
}
