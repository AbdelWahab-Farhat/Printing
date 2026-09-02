<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\Exceptions\CityHasNoNawrisMapping;
use App\Domain\Order\Models\Order;

/**
 * Turns the order's own city and region into the destination Nawris understands.
 *
 * **Nobody picks a Nawris destination by hand.** The order already knows where it is going, and
 * the city carries the mapping — see NAWRIS-INTEGRATION.md §4. This runs exactly once, at
 * dispatch; every later edit replays what it produced from the parcel row rather than calling it
 * again, because re-deriving a destination mid-journey moves the parcel.
 */
final class ResolveNawrisDestination
{
    /**
     * @param  array<string, mixed>  $config  `services.nawris`
     */
    public function __construct(private readonly array $config) {}

    /**
     * @throws CityHasNoNawrisMapping
     */
    public function __invoke(Order $order): NawrisDestination
    {
        $order->loadMissing(['city', 'region']);

        $government = $order->city?->nawris_government_id;

        if ($government === null || trim($government) === '') {
            // By name, so somebody can go and map that city — see the exception.
            throw CityHasNoNawrisMapping::make((string) $order->city_name);
        }

        $companyId = $this->config['shipping_company_id'] ?? null;

        return new NawrisDestination(
            government: $government,
            area: $order->region?->nawris_area_id,
            shippingCompanyId: $companyId !== null && $companyId !== '' ? (int) $companyId : null,
        );
    }
}
