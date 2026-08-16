<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Domain\Customer\Actions\CreateCustomer;
use App\Domain\Customer\DTOs\CustomerData;
use App\Domain\Customer\DTOs\CustomerShopData;
use App\Domain\Customer\Models\BusinessField;
use App\Domain\Customer\Models\Customer;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use Illuminate\Database\Seeder;

/**
 * The customer book the business already had, out of storage/ارقام الزباين.xlsx.
 *
 * **Real records, not sample data** — 574 people who have actually ordered, which is why this one
 * belongs in production while the demo seeders do not.
 *
 * The spreadsheet is transcribed into {@see database/seeders/data/customers.php} by
 * `extract_customers.py` and committed; nothing here opens a workbook. A seeder that read the
 * sheet at runtime would only run where somebody happened to leave a copy of it, and production
 * has none.
 *
 * **Idempotent, and it has to be.** `customers.phone` is unique, so a second run would otherwise
 * fail partway and leave the book half-imported. A phone already on file is skipped, so this can
 * be re-run after the sheet grows.
 *
 * Customers go through {@see CreateCustomer} rather than `Customer::create()`: the code (`C1`,
 * `C2`, …) is drawn from the id sequence there, and a row written around that action is a
 * customer with no code — the identifier every screen and every phone call uses.
 */
class CustomerSeeder extends Seeder
{
    /** Arabic spelling varies by who typed it; compare on a normalised form, store the original. */
    private static function fold(?string $value): string
    {
        if ($value === null) {
            return '';
        }

        $folded = preg_replace('/[\x{064B}-\x{0652}\x{0640}]/u', '', trim($value)) ?? '';
        $folded = strtr($folded, ['أ' => 'ا', 'إ' => 'ا', 'آ' => 'ا', 'ى' => 'ي', 'ة' => 'ه']);

        return preg_replace('/\s+/u', ' ', $folded) ?? '';
    }

    public function run(): void
    {
        $path = database_path('seeders/data/customers.php');

        // **Deliberately not in the repository.** It is 574 real people's names and telephone
        // numbers, and this repository is public — so the book is copied to each server out of
        // band and git-ignored here. Missing is therefore an ordinary state on a fresh clone,
        // and it says so rather than failing with a `require` that names no reason.
        if (! file_exists($path)) {
            $this->command?->warn(
                'seeders/data/customers.php is absent — the customer book is not in git '
                .'(it is personal data and this repository is public). Copy it to the server first.'
            );

            return;
        }

        /** @var list<array{name:string,phone:string,shop:?string,field:?string,place:?string,note:?string}> $book */
        $book = require $path;

        $cities = City::query()->get(['id', 'name'])
            ->keyBy(fn (City $c): string => self::fold($c->name));
        $regions = Region::query()->get(['id', 'name', 'city_id'])
            ->keyBy(fn (Region $r): string => self::fold($r->name));
        $fields = BusinessField::query()->get(['id', 'name'])
            ->keyBy(fn (BusinessField $f): string => self::fold($f->name));

        // The sheet's own trades, said its own way. Where one is plainly the same thing the
        // starting list already names, it is pointed at that row rather than duplicating it;
        // «شي إن» and «ساده» have no equivalent and are added, because BusinessFieldSeeder is a
        // starting point the business administers, not a closed set.
        $synonyms = [
            'ملابس' => 'بيع ملابس',
            'عطور' => 'عطور ومستحضرات تجميل',
            'مستحضرات تجميل' => 'عطور ومستحضرات تجميل',
            'حلويات' => 'حلويات ومخابز',
            'مخابز' => 'حلويات ومخابز',
            'شحن' => 'شحن وتوصيل',
            'توصيل' => 'شحن وتوصيل',
            'مطاعم' => 'مطاعم ومقاهي',
            'مقاهي' => 'مطاعم ومقاهي',
            'صيدلية' => 'صيدليات',
            'الكترونيات' => 'إلكترونيات وهواتف',
            'هواتف' => 'إلكترونيات وهواتف',
            'بقالة' => 'بقالة وسوبرماركت',
            'مكتبة' => 'مكتبات وقرطاسية',
        ];

        $create = app(CreateCustomer::class);
        $existing = Customer::query()->pluck('phone')->flip();

        $made = $skipped = $withShop = 0;

        foreach ($book as $entry) {
            if ($existing->has($entry['phone'])) {
                $skipped++;

                continue;
            }

            // Resolved once. Calling this twice would ask `fieldFor` to invent the same missing
            // trade a second time, and the second one would be a duplicate row in the picker.
            $shops = $this->shopFor($entry, $cities, $regions, $fields, $synonyms);

            $create(new CustomerData(
                name: $entry['name'],
                phone: $entry['phone'],
                shops: $shops,
            ));

            $existing[$entry['phone']] = true;
            $made++;

            if ($shops !== null) {
                $withShop++;
            }
        }

        $this->command?->info("customers: {$made} created, {$skipped} already on file, {$withShop} with a shop");
    }

    /**
     * A shop, when the sheet says enough to place one.
     *
     * **`city_id` is NOT NULL, so a place that cannot be resolved means no shop at all** — the
     * customer is still created, and their number is what staff look them up by anyway. Inventing
     * a city to satisfy the column would put the customer in the wrong town on the delivery
     * screen, which is worse than leaving the shop to be filled in later.
     *
     * «استلام من المكتب» is not a place. It is how the order leaves, and the order carries that
     * already — recording it as an address would put 147 customers in a town called "office
     * pickup".
     *
     * @return list<CustomerShopData>|null
     */
    private function shopFor(
        array $entry,
        \Illuminate\Support\Collection $cities,
        \Illuminate\Support\Collection $regions,
        \Illuminate\Support\Collection $fields,
        array $synonyms,
    ): ?array {
        $place = self::fold($entry['place']);

        if ($place === '' || str_contains($place, 'مكتب')) {
            return null;
        }

        $cityId = null;
        $regionId = null;

        if ($city = $cities->get($place)) {
            $cityId = $city->id;
        } elseif ($region = $regions->get($place)) {
            // A region knows its city, which is the whole reason the delivery map is two levels.
            $regionId = $region->id;
            $cityId = $region->city_id;
        }

        if ($cityId === null) {
            return null;
        }

        return [new CustomerShopData(
            // The trading name when there is one. Falling back to the person's own name keeps the
            // column honest — `name` is NOT NULL, and a blank shop is a row nobody can read.
            name: $entry['shop'] ?? $entry['name'],
            cityId: $cityId,
            regionId: $regionId,
            businessFieldId: $this->fieldFor($entry['field'], $fields, $synonyms),
        )];
    }

    private function fieldFor(?string $raw, \Illuminate\Support\Collection $fields, array $synonyms): ?int
    {
        $folded = self::fold($raw);

        if ($folded === '') {
            return null;
        }

        if ($named = $fields->get($folded)) {
            return $named->id;
        }

        foreach ($synonyms as $sheet => $listed) {
            if ($folded === self::fold($sheet) && ($match = $fields->get(self::fold($listed)))) {
                return $match->id;
            }
        }

        // A trade the starting list never named. Added rather than dropped: these are the fields
        // the business actually works in, and the picker is administered from the app.
        $created = BusinessField::query()->create(['name' => $raw, 'is_active' => true]);
        $fields[self::fold($raw)] = $created;

        return $created->id;
    }
}
