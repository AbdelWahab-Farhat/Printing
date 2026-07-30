<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use Database\Factories\ProductImageFactory;
use Illuminate\Contracts\Filesystem\Filesystem;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

/**
 * One photo of a product.
 */
#[UseFactory(ProductImageFactory::class)]
#[Fillable([
    'disk', 'path', 'original_filename', 'mime_type', 'size_bytes',
    'width_px', 'height_px', 'alt_text', 'is_primary', 'sort_order',
])]
class ProductImage extends Model
{
    /** @use HasFactory<ProductImageFactory> */
    use HasFactory;

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

    public function storage(): Filesystem
    {
        return Storage::disk($this->disk);
    }

    /**
     * Built on demand from the disk this file actually lives on.
     *
     * A disk that signs its URLs (a private S3 bucket) returns a link that expires; a public
     * disk returns a plain one. Chosen by asking the disk what it supports rather than by
     * catching a failure — the capability is knowable up front.
     */
    public function url(): string
    {
        $disk = $this->storage();

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl($this->path, now()->addMinutes(config('media.temporary_url_minutes')))
            : $disk->url($this->path);
    }
}
