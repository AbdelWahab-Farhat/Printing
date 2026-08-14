<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Domain\Catalog\Models\Product;
use App\Domain\Catalog\Models\ProductCategory;
use Illuminate\Database\Seeder;

/**
 * التصنيفات التي يعرضها الكتالوج، والمنتجات المسجّلة قبلها.
 *
 * The three headings the public catalogue is already organised under — daaya.ly/catalog.html —
 * so the app and the site agree on what a category *is* from the first day rather than after
 * somebody types three names twice.
 *
 * **Idempotent, and it never overwrites a decision.** Categories are matched by name, and the
 * backfill only touches products that have no category at all: a product somebody has since
 * filed under «علب» is left exactly where they put it.
 *
 * **«مطبوعة» and «سادة» are on the list because «النوع» is not a field any more.** That split
 * lived in a `category` column beside this one and fed no calculation anywhere — see the
 * migration that dropped it — so it became two headings here rather than a second word on every
 * product. Mixing «كيف يُصنع» with «أين يقف في الكتالوج» in one list is the price of having one
 * list, and it is the cheaper of the two.
 *
 * The backfill puts a still-uncategorised product under «أكياس» because, on the day this was
 * written, every product in the system was a bag. That is a fact about this data, not a rule: a
 * box added tomorrow is filed by whoever adds it, and this seeder will not touch it. Products
 * the migration already filed under مطبوعة/سادة are not uncategorised, so it passes them by.
 */
class ProductCategorySeeder extends Seeder
{
    /**
     * Name, description and order — the same three the catalogue prints.
     *
     * @var list<array{name: string, description: string, sort_order: int}>
     */
    private const CATEGORIES = [
        [
            'name' => 'أكياس',
            'description' => 'تشكيلة أكياس مخصصة للتغليف والشحن، مناسبة للمتاجر والمطاعم والمشاريع '
                .'التجارية، مع خيارات متعددة من الخامات والأحجام وإمكانية الطباعة حسب الطلب.',
            'sort_order' => 1,
        ],
        [
            'name' => 'علب وكراتين التغليف',
            'description' => 'صناديق نقل وهدايا توفر الفخامة والحماية الفائقة لمنتجاتك.',
            'sort_order' => 2,
        ],
        [
            'name' => 'ستيكرات ومطبوعات أخرى',
            'description' => 'ملصقات، كروت شكر، وشريط لاصق لتعزيز تفاصيل التغليف.',
            'sort_order' => 3,
        ],
        [
            'name' => 'مطبوعة',
            'description' => 'منتجات تُطبع بالشعار والألوان حسب الطلب.',
            'sort_order' => 4,
        ],
        [
            'name' => 'سادة',
            'description' => 'منتجات بلا طباعة، تُباع غالباً بالوزن.',
            'sort_order' => 5,
        ],
    ];

    public function run(): void
    {
        foreach (self::CATEGORIES as $category) {
            ProductCategory::query()->firstOrCreate(
                ['name' => $category['name']],
                [
                    'description' => $category['description'],
                    'sort_order' => $category['sort_order'],
                    'is_active' => true,
                ],
            );
        }

        $bags = ProductCategory::query()->where('name', 'أكياس')->sole();

        // `whereNull` is the whole safety of this: re-running it changes nothing, and a product
        // moved to another heading stays there.
        $filled = Product::query()
            ->whereNull('product_category_id')
            ->update(['product_category_id' => $bags->getKey()]);

        $this->command?->info("تم تصنيف {$filled} منتجاً تحت «أكياس».");
    }
}
