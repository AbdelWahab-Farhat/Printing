<?php

declare(strict_types=1);

namespace App\Domain\Customer\Actions;

use App\Domain\Customer\DTOs\CustomerShopData;
use App\Domain\Customer\Models\Customer;

/**
 * Makes a customer's shops match the given set exactly.
 *
 * Entries carrying an `id` update that shop, entries without one create a new shop, and any
 * existing shop missing from the set is removed. Shops belong to their customer and have no
 * life of their own, so replacing the whole set is the honest operation.
 */
final class SyncCustomerShops
{
    /**
     * @param  list<CustomerShopData>  $shops
     */
    public function __invoke(Customer $customer, array $shops): void
    {
        $keptIds = [];

        foreach ($shops as $shop) {
            $attributes = [
                'name' => $shop->name,
                'location' => $shop->location,
                'page_url' => $shop->pageUrl,
            ];

            // Scoped through the relation, so an id belonging to another customer simply
            // finds nothing and is created fresh rather than being hijacked.
            $existing = $shop->id !== null
                ? $customer->shops()->whereKey($shop->id)->first()
                : null;

            if ($existing !== null) {
                $existing->update($attributes);
                $keptIds[] = $existing->getKey();

                continue;
            }

            $keptIds[] = $customer->shops()->create($attributes)->getKey();
        }

        $customer->shops()->whereKeyNot($keptIds)->delete();
    }
}
