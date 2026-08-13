<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use App\Domain\Catalog\Enums\ProductType;
use Database\Factories\ProductCategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * التصنيف — a heading in the catalogue: أكياس, علب وكراتين التغليف, ستيكرات ومطبوعات أخرى.
 *
 * Reference data the business curates, exactly as {@see BusinessField} is: a short list, edited
 * from a screen, pointed at by every product. It is what the catalogue is organised by, and what
 * the products screen filters on.
 *
 * **Not {@see ProductType}.** That one — the `category` column, confusingly — says whether a bag
 * is printed or plain, which is a fact about how it is made. This says where a customer would
 * look for it. See PRODUCT-CATEGORIES.md.
 */
#[UseFactory(ProductCategoryFactory::class)]
#[Fillable(['name', 'description', 'is_active', 'sort_order'])]
class ProductCategory extends Model implements HasAuditTrail
{
    /** @use HasFactory<ProductCategoryFactory> */
    use Auditable, HasFactory, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    /**
     * @return HasMany<Product, $this>
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
     * Whether any product points at this category.
     *
     * Counts soft-deleted products too, deliberately: a deleted product can be restored, and a
     * category removed in the meantime would leave it pointing at nothing.
     */
    public function isInUse(): bool
    {
        return $this->products()->withTrashed()->exists();
    }

    /**
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [$this->getMorphClass() => [$this->getKey()]];
    }
}
