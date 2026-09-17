<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Customer\Models\Customer;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DesignTicket>
 */
class DesignTicketFactory extends Factory
{
    /** @var class-string<DesignTicket> */
    protected $model = DesignTicket::class;

    /**
     * A new ticket in the shared pool, because that is the state everything else moves out of.
     *
     * `code` is left out — the model allocates it on `creating`, like a shortage's and an
     * order's.
     *
     * **`customer_name` is not defaulted to a literal.** It is resolved from whatever customer the
     * row ends up with, so a test that passes its own customer does not silently get a ticket
     * whose snapshot names a different one — which is exactly the bug the snapshot exists to make
     * impossible in production.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'customer_id' => Customer::factory(),
            'customer_name' => fn (array $attributes) => Customer::query()
                ->whereKey($attributes['customer_id'])->value('name') ?? 'متجر إكس',
            'title' => 'تصميم كيس شحن — أسود',
            'description' => 'ضع الشعار في المنتصف وأضف رقم الهاتف أسفله.',
            'instructions' => null,
            'status' => DesignTicketStatus::New,
            'requested_by_user_id' => User::factory(),
        ];
    }

    /** Addressed to a named designer, still waiting to be accepted. */
    public function assignedTo(int $designerId): static
    {
        return $this->state(fn (): array => ['assigned_designer_id' => $designerId]);
    }

    /**
     * Taken, and being drawn.
     *
     * Sets `assigned_designer_id` as well, because that is what the acceptance path produces for
     * a pool ticket and a state nobody could reach in production is not worth testing against.
     */
    public function acceptedBy(int $designerId): static
    {
        return $this->state(fn (): array => [
            'assigned_designer_id' => $designerId,
            'accepted_by_user_id' => $designerId,
            'accepted_at' => now(),
            'status' => DesignTicketStatus::InProgress,
        ]);
    }

    public function underReview(int $designerId): static
    {
        return $this->acceptedBy($designerId)
            ->state(fn (): array => ['status' => DesignTicketStatus::UnderReview]);
    }

    public function changesRequested(int $designerId): static
    {
        return $this->acceptedBy($designerId)
            ->state(fn (): array => ['status' => DesignTicketStatus::ChangesRequested]);
    }

    /**
     * Cancelled, with the reason the CHECK constraint requires.
     *
     * Deliberately no `completed()` state beside it: «مكتمل» demands a `customer_designs` row
     * that only a real approval can produce, and a factory able to fabricate one would let a test
     * assert against a ticket the domain would never have written.
     */
    public function cancelled(string $reason = 'فُتحت بالخطأ'): static
    {
        return $this->state(fn (): array => [
            'status' => DesignTicketStatus::Cancelled,
            'cancellation_reason' => $reason,
        ]);
    }
}
