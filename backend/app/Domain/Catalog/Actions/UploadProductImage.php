<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductImage;
use App\Support\Media\StoreUploadedFile;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

/**
 * Stores an uploaded photo and records it against the product.
 *
 * The file itself goes through {@see StoreUploadedFile}, which owns the generated name, the
 * sniffed type and the measurements. What is left here is the only thing that is about a
 * *product*: which photo is the primary one.
 *
 * **`mime_type` is now the sniffed type rather than `getClientMimeType()`.** This action used to
 * store the client's own claim, which was defensible only because the `image` validation rule
 * had already proved the content really was an image — so the claim was checked but never
 * recorded. It is now recorded as what it is, which is strictly more accurate and matches what
 * every other file in the system stores.
 */
final class UploadProductImage
{
    public function __construct(
        private readonly SetPrimaryProductImage $setPrimary,
        private readonly StoreUploadedFile $storeFile,
    ) {}

    public function __invoke(
        Product $product,
        UploadedFile $file,
        ?string $altText = null,
        bool $makePrimary = false,
    ): ProductImage {
        $stored = ($this->storeFile)(
            $file,
            (string) config('media.disk'),
            "products/{$product->getKey()}",
        );

        // The first photo of a product becomes its primary one — a catalogue entry with images
        // but no thumbnail would just be a gap in the grid.
        $shouldBePrimary = $makePrimary || ! $product->images()->exists();

        return DB::transaction(function () use ($product, $stored, $altText, $shouldBePrimary): ProductImage {
            $image = $product->images()->create([
                'disk' => $stored->disk,
                'path' => $stored->path,
                'original_filename' => $stored->originalFilename,
                'mime_type' => $stored->mimeType,
                'size_bytes' => $stored->sizeBytes,
                'width_px' => $stored->widthPx,
                'height_px' => $stored->heightPx,
                'alt_text' => $altText,
                'is_primary' => false,
                'sort_order' => (int) $product->images()->max('sort_order') + 1,
            ]);

            if ($shouldBePrimary) {
                ($this->setPrimary)($product, $image);
            }

            return $image->refresh();
        });
    }
}
