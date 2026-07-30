<?php

declare(strict_types=1);

namespace App\Domain\Catalog;

use App\Domain\Catalog\Actions\CreateProduct;
use App\Domain\Catalog\Actions\QuoteProductPrice;
use App\Domain\Catalog\Actions\UpdateProduct;
use App\Domain\Catalog\DTOs\PriceQuote;
use App\Domain\Catalog\DTOs\ProductData;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Catalog\Queries\ProductFilters;
use App\Domain\Catalog\Queries\ProductListQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The Catalog module's public front door.
 *
 * When Orders arrive they price a line by calling `quote()` here — never by reading price tiers
 * themselves. That is what guarantees the number a customer was shown and the number written to
 * their order are produced by the same code.
 */
class CatalogService
{
    public function __construct(
        private readonly CreateProduct $createProduct,
        private readonly UpdateProduct $updateProduct,
        private readonly QuoteProductPrice $quoteProductPrice,
        private readonly ProductListQuery $listQuery,
    ) {}

    /**
     * @return LengthAwarePaginator<int, Product>
     */
    public function paginate(ProductFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->listQuery)($filters, $perPage);
    }

    public function create(ProductData $data): Product
    {
        return ($this->createProduct)($data);
    }

    public function update(Product $product, ProductData $data): Product
    {
        return ($this->updateProduct)($product, $data);
    }

    /**
     * Products are deactivated rather than deleted, so past orders keep pointing at a row that
     * still exists.
     */
    public function setActive(Product $product, bool $isActive): Product
    {
        $product->update(['is_active' => $isActive]);

        return $product->load(['variants.priceTiers', 'images']);
    }

    public function quote(Product $product, ProductVariant $variant, string $quantity): PriceQuote
    {
        return ($this->quoteProductPrice)($product, $variant, $quantity);
    }
}
