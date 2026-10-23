<?php

namespace Database\Factories;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerSocialLink;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CustomerSocialLink>
 */
class CustomerSocialLinkFactory extends Factory
{
    /** @var class-string<CustomerSocialLink> */
    protected $model = CustomerSocialLink::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            // اسم المستخدم فريدٌ لكل صف، فرابطان من المصنع لا يتكرّران عند عميلٍ واحد.
            'url' => fake()->randomElement([
                'https://facebook.com/',
                'https://instagram.com/',
                'https://tiktok.com/@',
            ]).fake()->unique()->userName(),
        ];
    }
}
