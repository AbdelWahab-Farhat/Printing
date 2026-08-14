<?php

declare(strict_types=1);

namespace App\Domain\Catalog\Models;

use App\Domain\Audit\Concerns\Auditable;
use App\Domain\Audit\Contracts\HasAuditTrail;
use Database\Factories\ProductCategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Contracts\Filesystem\Filesystem;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Storage;

/**
 * التصنيف — a heading in the catalogue: أكياس, علب وكراتين التغليف, ستيكرات ومطبوعات أخرى,
 * مطبوعة, سادة.
 *
 * Reference data the business curates, exactly as {@see BusinessField} is: a short list, edited
 * from a screen, pointed at by every product. It is what the catalogue is organised by, and what
 * the products screen filters on.
 *
 * **The only thing that classifies a product**, since the last two names on that list arrived.
 * مطبوعة/سادة used to be «النوع», a column of its own on the product; it fed no calculation
 * anywhere, so it became two rows here and the column was dropped. See PRODUCT-CATEGORIES.md.
 */
#[UseFactory(ProductCategoryFactory::class)]
#[Fillable(['name', 'description', 'is_active', 'sort_order', 'parent_id'])]
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
            'image_width_px' => 'integer',
            'image_height_px' => 'integer',
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
     * The heading this one sits under, or null when it is a heading in its own right.
     *
     * @return BelongsTo<ProductCategory, $this>
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    /**
     * The headings under this one, in the catalogue's own order.
     *
     * **One level deep.** A child may not hold children — the rule is enforced where it can be
     * explained, in {@see StoreProductCategoryRequest}, rather than by a database that can only
     * say no.
     *
     * @return HasMany<ProductCategory, $this>
     */
    public function children(): HasMany
    {
        return $this->hasMany(self::class, 'parent_id')->orderBy('sort_order')->orderBy('name');
    }

    /**
     * Whether a product may be filed under this heading.
     *
     * **A heading with children is a heading, not a slot.** Allowing both would make «كم منتجاً
     * تحت أكياس؟» two different questions — «مباشرة» and «بالمجموع» — and every count on every
     * screen would have to say which one it meant.
     */
    public function isLeaf(): bool
    {
        return ! $this->children()->exists();
    }

    /** Whether this heading may itself be given a parent — see the one-level rule. */
    public function isRoot(): bool
    {
        return $this->parent_id === null;
    }

    /**
     * The ones a picker may offer: still on offer, and not hidden behind a stopped parent.
     *
     * A live child under a stopped root is not offerable — the root was stopped precisely to
     * take that part of the catalogue out of circulation, and honouring only the child's own
     * flag would leave half the decision applied.
     *
     * @param  Builder<ProductCategory>  $query
     */
    #[Scope]
    protected function offerable(Builder $query): void
    {
        $query->where('is_active', true)
            ->where(fn (Builder $query) => $query
                ->whereNull('parent_id')
                ->orWhereHas('parent', fn (Builder $parent) => $parent->where('is_active', true)));
    }

    public function hasImage(): bool
    {
        return $this->image_disk !== null && $this->image_path !== null;
    }

    public function imageStorage(): Filesystem
    {
        return Storage::disk((string) $this->image_disk);
    }

    /**
     * Built on demand from the disk the file actually lives on, and never stored.
     *
     * A URL embeds a bucket, a region and a host, all of which change; a stored one silently
     * rots. On a disk that signs its links this hands out a temporary one, exactly as
     * {@see CustomerDesign} does.
     */
    public function imageUrl(): ?string
    {
        if (! $this->hasImage()) {
            return null;
        }

        $disk = $this->imageStorage();

        return $disk->providesTemporaryUrls()
            ? $disk->temporaryUrl((string) $this->image_path, now()->addMinutes(config('media.temporary_url_minutes')))
            : $disk->url((string) $this->image_path);
    }

    /**
     * Whether anything points at this category — a product, directly or through a child.
     *
     * Counts soft-deleted products too, deliberately: a deleted product can be restored, and a
     * category removed in the meantime would leave it pointing at nothing.
     */
    public function isInUse(): bool
    {
        if ($this->products()->withTrashed()->exists()) {
            return true;
        }

        return $this->children()
            ->whereHas('products', fn (Builder $query) => $query->withTrashed())
            ->exists();
    }

    /**
     * @return array<string, list<int|string>>
     */
    public function auditTrailSubjects(): array
    {
        return [$this->getMorphClass() => [$this->getKey()]];
    }
}
