<?php

declare(strict_types=1);

namespace App\Domain\Catalog;

use App\Domain\Catalog\Actions\CreateProduct;
use App\Domain\Catalog\Actions\QuoteProductPrice;
use App\Domain\Catalog\Actions\UpdateProduct;
use App\Domain\Catalog\DTOs\PriceQuote;
use App\Domain\Catalog\DTOs\ProductData;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductVariant;
use App\Domain\Catalog\Queries\FindProductVariant;
use App\Domain\Catalog\Queries\ProductFilters;
use App\Domain\Catalog\Queries\ProductListQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The Catalog module's public front door.
 *
 * When Orders arrive they price a line by calling `quote()` here — never by reading price tiers
 * themselves. That is what guarantees the number a customer was shown and the number written to
 * their order are produced by the same code.
 *
 * Inventory asks the same way: a stock movement resolves the size it names through
 * `findVariant()` and asks `requiresWholeQuantities()` whether a fraction of it is meaningful,
 * rather than reading `products.pricing_unit` itself. Same reason — the rule that stops an order
 * for half a bag and the rule that stops half a bag being moved between warehouses have to be
 * one rule, or they will eventually disagree.
 */
class CatalogService
{
    public function __construct(
        private readonly CreateProduct $createProduct,
        private readonly UpdateProduct $updateProduct,
        private readonly QuoteProductPrice $quoteProductPrice,
        private readonly ProductListQuery $listQuery,
        private readonly FindProductVariant $findProductVariant,
    ) {}

    /**
     * @return LengthAwarePaginator<int, Product>
     */
    public function paginate(ProductFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->listQuery)($filters, $perPage);
    }

    /**
     * One product with everything pricing needs already loaded.
     *
     * Eager-loads the tiers because the caller is about to quote against them, and strict mode
     * turns a forgotten load into an exception rather than a silent query per line.
     */
    public function findProduct(int $id): Product
    {
        return Product::query()->with('variants.priceTiers')->findOrFail($id);
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

    /**
     * One size, by id, with its product loaded. 404s on its own if there is no such size.
     *
     * The seam another context reaches a variant through — it never queries
     * {@see ProductVariant} itself.
     */
    public function findVariant(int $variantId): ProductVariant
    {
        return ($this->findProductVariant)($variantId);
    }

    /**
     * Whether a fraction of this size means anything.
     *
     * Pieces are countable, so half a shipping bag is a typo; a per-kilo product's quantity is a
     * weight and fractions are the normal case. The rule itself lives on
     * {@see PricingUnit}, next to the two cases it distinguishes —
     * this only carries it across the context boundary so a caller does not have to walk into
     * the product to find it.
     */
    public function requiresWholeQuantities(ProductVariant $variant): bool
    {
        return $variant->loadMissing('product')->product->pricing_unit->requiresWholeQuantities();
    }
}
