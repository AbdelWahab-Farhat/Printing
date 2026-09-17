<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Catalog\Actions\DeleteProductImage;
use App\Support\Media\HasStoredFile;
use Database\Factories\ProductImageFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * One photo of a product.
 *
 * Soft deleted like everything else, with one asymmetry worth knowing: the *file* is deleted for
 * real. Object storage has no `deleted_at`, and keeping every replaced photo forever would grow
 * without bound. So a restored image row would point at a missing object — which is why
 * {@see DeleteProductImage} is the only place that removes one, and
 * why nothing offers to restore it.
 */
#[UseFactory(ProductImageFactory::class)]
#[Fillable([
    'disk', 'path', 'original_filename', 'mime_type', 'size_bytes',
    'width_px', 'height_px', 'alt_text', 'is_primary', 'sort_order',
])]
class ProductImage extends Model
{
    /** @use HasFactory<ProductImageFactory> */
    use Auditable, HasFactory, HasStoredFile, SoftDeletes;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'size_bytes' => 'integer',
            'width_px' => 'integer',
            'height_px' => 'integer',
            'is_primary' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<Product, $this>
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
