<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Product;

use App\Domain\Catalog\Models\ProductCategory;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Unique;

/**
 * Same shape as creating; only the uniqueness rule differs, because a category keeping its own
 * name must not collide with itself.
 *
 * The rules are written out in full rather than merged onto the parent's on purpose: Scramble
 * reads this method statically to build the OpenAPI request body and cannot follow an
 * `array_merge(parent::rules(), …)` call — doing that leaves the endpoint with no documented body.
 */
class UpdateProductCategoryRequest extends StoreProductCategoryRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:100', $this->nameUniqueAmongOthers()],
            'description' => ['sometimes', 'nullable', 'string', 'max:500'],
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:9999'],
        ];
    }

    private function nameUniqueAmongOthers(): Unique
    {
        /** @var ProductCategory $category */
        $category = $this->route('product_category');

        return Rule::unique('product_categories', 'name')->ignore($category->getKey())->withoutTrashed();
    }
}
