<?php

namespace Database\Factories;

use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InternalTicketMessage>
 *
 * **بلا كاتبٍ افتراضيّ**، كرسالة الدعم: كلُّ مستدعٍ يقول مَن كتبها بـ`by()`، لأن «مَن قال هذا؟» هو
 * السؤال الذي يوجد الصفُّ ليجيب عنه.
 */
class InternalTicketMessageFactory extends Factory
{
    /** @var class-string<InternalTicketMessage> */
    protected $model = InternalTicketMessage::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'internal_ticket_id' => InternalTicket::factory(),
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
