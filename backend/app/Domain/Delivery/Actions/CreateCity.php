<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Actions;

use App\Domain\Delivery\DTOs\CityData;
use App\Domain\Delivery\Models\City;

final class CreateCity
{
    public function __invoke(CityData $data): City
    {
        $city = City::create([
            'name' => $data->name,
            'is_region_required' => $data->isRegionRequired,
            'delivery_price' => $data->deliveryPrice,
            'darb_branch' => $data->darbBranch,
            'latitude' => $data->latitude,
            'longitude' => $data->longitude,
        ]);

        // A brand-new city has none, but the count must still be present: the resource renders
        // it, and strict mode turns a missing attribute into an exception rather than a null.
        return $city->loadCount('regions');
    }
}
