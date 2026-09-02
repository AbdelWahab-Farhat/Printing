<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Actions;

use App\Domain\Catalog\DTOs\ProductCategoryData;
use App\Domain\Catalog\Models\ProductCategory;

/**
 * Replaces a category with what was sent.
 *
 * **Renaming is allowed even when products point at it**, deliberately: this is a *label*, not a
 * snapshot. An order records what it cost on the day; a product records where it sits in the
 * catalogue, and fixing «ستيكرات» spelt wrong should fix it everywhere at once.
 */
final class UpdateProductCategory
{
    public function __invoke(ProductCategory $category, ProductCategoryData $data): ProductCategory
    {
        $category->update([
            'name' => $data->name,
            'parent_id' => $data->parentId,
            'description' => $data->description,
            'is_active' => $data->isActive,
            'sort_order' => $data->sortOrder,
            // **Orders already taken keep the road they were taken under.** Flipping this
            // re-routes the *next* order under the heading, never one in flight — the flow is
            // stamped on the order at intake, see `ResolveOrderFlow`.
            'skips_production' => $data->skipsProduction,
        ]);

        return $category->loadCount(['products', 'children']);
    }
}
