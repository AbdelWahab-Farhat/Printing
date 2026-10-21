<?php

namespace Database\Factories;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketPriority;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Models\InternalTicket;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<InternalTicket>
 *
 * **الطرفان موظفان مختلفان دائماً**، وإلا رفض الجدولُ الصف (`internal_tickets_two_parties`).
 * و`between()` يسمّيهما حين يهمّ الاختبارَ مَن هما.
 */
class InternalTicketFactory extends Factory
{
    /** @var class-string<InternalTicket> */
    protected $model = InternalTicket::class;

    /** تسلسلٌ لا عشوائية: الكود فريد، وتصادمٌ بالصدفة يُسقط اختباراً لا شأن له به. */
    private static int $sequence = 0;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'code' => 'TR-F'.++self::$sequence,
            'title' => 'سؤال عن '.fake()->word(),
            'status' => InternalTicketStatus::InProgress,
            'priority' => InternalTicketPriority::Medium,
            'opened_by' => User::factory(),
            'assignee_id' => User::factory(),
            'last_message_at' => now(),
        ];
    }

    public function between(User $opener, User $assignee): static
    {
        return $this->state(fn () => [
            'opened_by' => $opener->getKey(),
            'assignee_id' => $assignee->getKey(),
        ]);
    }

    public function closed(): static
    {
        return $this->state(fn () => ['status' => InternalTicketStatus::Closed, 'closed_at' => now()]);
    }
}
