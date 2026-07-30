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
            'location' => fake()->city(),
            'page_url' => fake()->boolean(70) ? 'https://facebook.com/'.fake()->userName() : null,
        ];
    }
}
