<?php

namespace Database\Factories;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DesignTicketMessage>
 *
 * رسالةٌ نصية افتراضاً، بكاتبٍ جديد. `by()` لكاتبٍ بعينه، و`retracted()` لرسالةٍ سحبها صاحبها.
 */
class DesignTicketMessageFactory extends Factory
{
    /** @var class-string<DesignTicketMessage> */
    protected $model = DesignTicketMessage::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'design_ticket_id' => DesignTicket::factory(),
            'user_id' => User::factory(),
            'body' => fake()->sentence(),
        ];
    }

    public function by(int $userId): static
    {
        return $this->state(fn () => ['user_id' => $userId]);
    }

    public function retracted(): static
    {
        return $this->state(fn () => ['retracted_at' => now()]);
    }
}
