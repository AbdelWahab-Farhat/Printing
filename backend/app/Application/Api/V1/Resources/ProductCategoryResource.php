<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Catalog\Models\ProductCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ProductCategory
 */
class ProductCategoryResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,

            // The heading this one sits under, or null when it is one itself. The name travels
            // with the id because every screen showing a child shows where it belongs, and an
            // app that looks one up per row is an app making N requests to draw a list.
            'parent_id' => $this->parent_id,
            'parent' => $this->whenLoaded(
                'parent',
                fn () => $this->parent === null ? null : [
                    'id' => $this->parent->id,
                    'name' => $this->parent->name,
                ],
            ),
            'description' => $this->description,
            'is_active' => $this->is_active,
            'sort_order' => $this->sort_order,

            // Whether an order made only of goods from this heading skips the designer and the
            // press. **This row's own answer, not the effective one** — a child that inherits a
            // flagged parent reads false here, and that is deliberate: this is the value an edit
            // form puts back, so showing the inherited answer would have somebody save a flag
            // onto a child that never asked for one. The effective answer is the domain's, and
            // it is asked through `ProductCategory::skipsProduction()`.
            'skips_production' => $this->skips_production,

            // Products filed directly on this heading. Zero for a parent by construction — a
            // heading with children is a heading, not a slot.
            'products_count' => $this->whenCounted('products'),

            // How many subheadings it holds. What tells the app this row is a heading rather
            // than something a product can be filed under, without asking a second question.
            'children_count' => $this->whenCounted('children'),

            // Everything under it, children included. **This is the number a screen shows** —
            // «أكياس · ١٢ منتجاً» is true of the whole heading — and it is the same number that
            // decides whether a delete will be refused, so the screen can say so before the
            // button is pressed.
            //
            // Present only where it was selected — the listing computes it with one correlated
            // subquery, while a single category answered after a save has no reason to. Asked of
            // the attribute bag rather than of the model, because strict mode turns reading an
            // unselected attribute into an exception rather than a null.
            'total_products_count' => $this->when(
                $this->hasCountsForTotal(),
                fn () => (int) $this->products_count + (int) $this->descendant_products_count,
            ),

            // Built per request from the disk the file actually lives on, and never stored: a
            // URL embeds a bucket, a region and a host, all of which change.
            'image_url' => $this->imageUrl(),
            'image_width_px' => $this->image_width_px,
            'image_height_px' => $this->image_height_px,

            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }

    /** Whether both halves of the subtree total were actually selected for this row. */
    private function hasCountsForTotal(): bool
    {
        $attributes = $this->resource->getAttributes();

        return array_key_exists('products_count', $attributes)
            && array_key_exists('descendant_products_count', $attributes);
    }
}
