<?php

declare(strict_types=1);

namespace App\Domain\Delivery\Actions;

use App\Domain\Delivery\DTOs\CityData;
use App\Domain\Delivery\Models\City;

/**
 * The whole city is replaced by what was sent, so omitting `latitude`/`longitude` clears the pin
 * rather than keeping it. That is what PUT means, and it keeps "save the form" from silently
 * preserving a value the user just cleared.
 */
final class UpdateCity
{
    public function __invoke(City $city, CityData $data): City
    {
        $city->update([
            'name' => $data->name,
            'is_region_required' => $data->isRegionRequired,
            'delivery_price' => $data->deliveryPrice,
            'darb_branch' => $data->darbBranch,
            'latitude' => $data->latitude,
            'longitude' => $data->longitude,
        ]);

        return $city->loadCount('regions');
    }
}
