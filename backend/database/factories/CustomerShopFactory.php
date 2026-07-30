<?php

namespace Database\Factories;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerShop;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CustomerShop>
 */
class CustomerShopFactory extends Factory
{
    /** @var class-string<CustomerShop> */
    protected $model = CustomerShop::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            'name' => fake()->streetName().' — فرع',
            // Bounded to roughly Libya, so factory data looks plausible on a map instead of
            // scattering shops across the planet.
            'latitude' => fake()->latitude(24, 33),
            'longitude' => fake()->longitude(9, 25),
            'page_url' => fake()->boolean(70) ? 'https://facebook.com/'.fake()->userName() : null,
        ];
    }
}
