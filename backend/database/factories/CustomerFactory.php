<?php

namespace Database\Factories;

use App\Domain\Customer\Actions\AllocateCustomerIdentifier;
use App\Domain\Customer\Models\Customer;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Customer>
 */
class CustomerFactory extends Factory
{
    /** @var class-string<Customer> */
    protected $model = Customer::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->company(),
            'primary_phone' => '09'.fake()->numerify('########'),
            'is_active' => true,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }

    /**
     * The code is normally allocated by CreateCustomer, which the factory bypasses — so it
     * reserves an id the same way, keeping factory-made customers consistent with real ones.
     */
    public function configure(): static
    {
        return $this->afterMaking(function (Customer $customer): void {
            if ($customer->code === null) {
                $identifier = app(AllocateCustomerIdentifier::class)();
                $customer->id = $identifier->id;
                $customer->code = $identifier->code;
            }
        });
    }
}
