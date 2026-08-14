<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Requests\Product;

use App\Domain\Catalog\Enums\PricingMode;
use App\Domain\Catalog\Enums\PricingUnit;
use App\Domain\Catalog\Models\Product;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Exists;
use Illuminate\Validation\Rules\Unique;

/**
 * Same shape as creating, plus `variants.*.id` so an existing size can be edited in place.
 *
 * The rules are written out in full rather than merged onto the parent's: Scramble reads this
 * method statically to build the OpenAPI request body and cannot follow
 * `array_merge(parent::rules(), …)`, which would leave this endpoint published with no body.
 */
class UpdateProductRequest extends StoreProductRequest
{
    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'slug' => ['required', 'string', 'max:80', 'regex:/^[a-z0-9-]+$/', $this->slugUniqueAmongOtherProducts()],
            'name' => ['required', 'string', 'min:2', 'max:255'],
            'description' => ['nullable', 'string', 'max:2000'],
            'features' => ['nullable', 'array', 'max:12'],
            'features.*' => ['required', 'string', 'max:255'],

            // **The catalogue heading, and it is required from today on.** The column is
            // nullable because the products recorded before this feature existed have to stay
            // valid; nothing saved through this request may be. `exists` refuses a category that
            // was deleted — a product pointing at a hidden row is worse than one with none.
            'product_category_id' => [
                'required', 'integer',
                Rule::exists('product_categories', 'id')->whereNull('deleted_at'),
            ],
            'pricing_unit' => ['required', Rule::enum(PricingUnit::class)],
            'pricing_mode' => ['required', Rule::enum(PricingMode::class)],

            'min_order_quantity' => ['required', 'numeric', 'min:0.001'],
            // Omit to leave the product's current state alone.
            'is_active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],

            // Omit `variants` to keep the existing price list. Sending the key replaces the whole
            // set: entries with an `id` are updated, entries without one are added, and anything
            // left out is deleted.
            'variants' => ['sometimes', 'array'],
            'variants.*.id' => ['sometimes', 'integer', $this->variantBelongsToThisProduct()],
            'variants.*.label' => ['required', 'string', 'max:60', 'distinct'],
            'variants.*.width_cm' => ['nullable', 'integer', 'min:1', 'max:1000'],
            'variants.*.height_cm' => ['nullable', 'integer', 'min:1', 'max:1000'],
            'variants.*.is_active' => ['sometimes', 'boolean'],
            'variants.*.sort_order' => ['sometimes', 'integer', 'min:0', 'max:65535'],
            'variants.*.price_tiers' => ['sometimes', 'array'],
            'variants.*.price_tiers.*.min_quantity' => ['required', 'numeric', 'min:0.001'],
            'variants.*.price_tiers.*.unit_price' => ['required', 'numeric', 'min:0'],
        ];
    }

    private function slugUniqueAmongOtherProducts(): Unique
    {
        /** @var Product $product */
        $product = $this->route('product');

        return Rule::unique('products', 'slug')->ignore($product->getKey())->withoutTrashed();
    }

    /**
     * Constrained to this product's own variants, so one product's request can never reach into
     * another's price list.
     */
    private function variantBelongsToThisProduct(): Exists
    {
        /** @var Product $product */
        $product = $this->route('product');

        return Rule::exists('product_variants', 'id')->where('product_id', $product->getKey());
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return array_merge(parent::messages(), [
            'variants.*.id.exists' => 'المقاس المحدد لا ينتمي لهذا المنتج',
        ]);
    }
}
