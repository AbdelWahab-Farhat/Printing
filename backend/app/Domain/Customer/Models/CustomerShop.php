<?php

declare(strict_types=1);

namespace App\Domain\Customer\Models;

use Database\Factories\CustomerShopFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * A place where a customer sells — اسم المكان / الموقع (إحداثيات) / رابط الصفحة.
 *
 * Owned entirely by its customer; it has no independent lifecycle and is managed
 * through the customer's own endpoints.
 */
#[UseFactory(CustomerShopFactory::class)]
#[Fillable(['name', 'latitude', 'longitude', 'page_url'])]
class CustomerShop extends Model
{
    /** @use HasFactory<CustomerShopFactory> */
    use HasFactory;

    /**
     * Cast to float, not the default decimal-as-string: a map SDK expects numbers, and the
     * API should hand it numbers rather than "32.8872000".
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'latitude' => 'float',
            'longitude' => 'float',
        ];
    }

    /**
     * @return BelongsTo<Customer, $this>
     */
    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class);
    }
}
