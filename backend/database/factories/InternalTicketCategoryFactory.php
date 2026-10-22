<?php

namespace Database\Factories;

use App\Domain\InternalTicket\Models\InternalTicketCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InternalTicketCategory>
 */
class InternalTicketCategoryFactory extends Factory
{
    /** @var class-string<InternalTicketCategory> */
    protected $model = InternalTicketCategory::class;

    /** تسلسلٌ لا عشوائية: الاسم فريد. */
    private static int $sequence = 0;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => 'نوع '.++self::$sequence,
            'is_active' => true,
            'sort_order' => 100 + self::$sequence,
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }
}
