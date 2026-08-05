<?php

declare(strict_types=1);

namespace App\Domain\Delivery;

use App\Domain\Delivery\Actions\CreateCity;
use App\Domain\Delivery\Actions\CreateRegion;
use App\Domain\Delivery\Actions\DeleteCity;
use App\Domain\Delivery\Actions\DeleteRegion;
use App\Domain\Delivery\Actions\UpdateCity;
use App\Domain\Delivery\Actions\UpdateRegion;
use App\Domain\Delivery\DTOs\CityData;
use App\Domain\Delivery\DTOs\RegionData;
use App\Domain\Delivery\Models\City;
use App\Domain\Delivery\Models\Region;
use App\Domain\Delivery\Queries\CityFilters;
use App\Domain\Delivery\Queries\CityListQuery;
use App\Domain\Delivery\Queries\RegionListQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

/**
 * The Delivery module's public front door.
 *
 * When Orders arrive, they resolve a delivery address and its price through here — never by
 * reading `cities` themselves. That seam is what lets the delivery map change shape internally
 * without every caller changing with it.
 */
class DeliveryService
{
    public function __construct(
        private readonly CreateCity $createCity,
        private readonly UpdateCity $updateCity,
        private readonly DeleteCity $deleteCity,
        private readonly CreateRegion $createRegion,
        private readonly UpdateRegion $updateRegion,
        private readonly DeleteRegion $deleteRegion,
        private readonly CityListQuery $cityListQuery,
        private readonly RegionListQuery $regionListQuery,
    ) {}

    /**
     * @return LengthAwarePaginator<int, City>
     */
    public function paginateCities(CityFilters $filters, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->cityListQuery)($filters, $perPage);
    }

    /**
     * One city by id, for a caller that received it in a request body rather than through
     * route-model binding — an order names its destination that way.
     *
     * Here rather than in Order, because Order must never query City directly: that seam is
     * what lets the delivery map change internally without a ripple.
     */
    public function findCity(int $id): City
    {
        return City::query()->findOrFail($id);
    }

    /** One region by id. Whether it belongs to the chosen city is the caller's rule to enforce. */
    public function findRegion(int $id): Region
    {
        return Region::query()->findOrFail($id);
    }

    public function createCity(CityData $data): City
    {
        return ($this->createCity)($data);
    }

    public function updateCity(City $city, CityData $data): City
    {
        return ($this->updateCity)($city, $data);
    }

    /**
     * The regions inside go with it — they have no life outside their city.
     *
     * Soft, since every model here soft deletes: the city and its regions leave the API and
     * keep their history, and the audit trail records who removed them.
     *
     * 🎯 Revisit when Orders lands: an order that names a deleted city would lose its delivery
     * address, so this will likely become a deactivation the way customers and products are.
     */
    public function deleteCity(City $city): void
    {
        ($this->deleteCity)($city);
    }

    /**
     * @return LengthAwarePaginator<int, Region>
     */
    public function paginateRegions(City $city, ?string $search = null, int $perPage = 15): LengthAwarePaginator
    {
        return ($this->regionListQuery)($city, $search, $perPage);
    }

    public function createRegion(City $city, RegionData $data): Region
    {
        return ($this->createRegion)($city, $data);
    }

    public function updateRegion(Region $region, RegionData $data): Region
    {
        return ($this->updateRegion)($region, $data);
    }

    public function deleteRegion(Region $region): void
    {
        ($this->deleteRegion)($region);
    }
}
