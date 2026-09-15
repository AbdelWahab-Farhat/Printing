<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;

/**
 * «قبول الطلب» — the step that stops two designers drawing the same bag.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketAcceptanceTest extends DesignTicketTestCase
{
    public function test_a_pool_ticket_is_accepted_once_and_the_second_designer_is_told_who_has_it(): void
    {
        // Arrange — two designers reaching for the same unclaimed ticket.
        [, $employee] = $this->employee();
        [$first, $firstHeaders] = $this->designer();
        [, $secondHeaders] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        // Act
        $won = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $firstHeaders);
        $lost = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $secondHeaders);

        // Assert — «لا تضيع هوية المصمم الذي استلم الطلب», read from the losing side: the refusal
        // names the holder, so the second designer knows whom to talk to.
        $won->assertOk();
        $lost->assertStatus(422)->assertJsonPath('message', "تم قبول هذه التذكرة من {$first->name}");

        $this->assertSame($first->id, (int) $ticket->refresh()->accepted_by_user_id);
    }

    public function test_a_ticket_addressed_to_one_designer_is_refused_to_another(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$mine] = $this->designer();
        [, $theirs] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $mine->id]),
                $employee,
            )->json('data.id'),
        );

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $theirs);

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('message', 'هذه التذكرة مُسنَدة إلى مصمم آخر');
        $this->assertNull($ticket->refresh()->accepted_at);
    }

    public function test_uploading_before_accepting_is_refused(): void
    {
        // Arrange — the acceptance step is only meaningful if nothing routes around it.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image()],
            $designer,
        );

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('message', 'يجب قبول التذكرة قبل رفع تصميم');
        $this->assertSame(0, $ticket->versions()->count());
    }

    public function test_assigning_does_not_start_the_work(): void
    {
        // Arrange — routing is a supervisor's act; starting is the designer's.
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        // Act
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => $designerUser->id],
            $employee,
        );

        // Assert — still «جديد». A ticket addressed to somebody who has not said yet yes is not
        // work in progress, and counting it as such would make the board's first number wrong.
        $response->assertOk()
            ->assertJsonPath('data.status', DesignTicketStatus::New->value)
            ->assertJsonPath('data.designer.id', $designerUser->id)
            ->assertJsonPath('data.accepted_by', null);
    }

    public function test_reassigning_after_acceptance_does_not_rewrite_who_did_the_work(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$original, $originalHeaders] = $this->designer();
        [$replacement] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $originalHeaders)
            ->assertOk();

        // Act
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => $replacement->id],
            $employee,
        );

        // Assert — two columns, two different facts: who it is addressed to now, and who took it.
        $response->assertOk()
            ->assertJsonPath('data.designer.id', $replacement->id)
            ->assertJsonPath('data.accepted_by.id', $original->id);
    }

    public function test_a_ticket_can_be_returned_to_the_shared_pool(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $designerUser->id]),
                $employee,
            )->json('data.id'),
        );

        // Act — null is an instruction, which is why the field is `present` rather than `required`
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => null],
            $employee,
        );

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.designer', null)
            ->assertJsonPath('data.is_in_shared_pool', true);
    }

    public function test_omitting_the_designer_field_entirely_is_a_mistake_not_an_instruction(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $designerUser->id]),
                $employee,
            )->json('data.id'),
        );

        // Act
        $response = $this->patchJson("/api/v1/design-tickets/{$ticket->id}/designer", [], $employee);

        // Assert — a half-built request must not quietly clear somebody's queue.
        $response->assertStatus(422)->assertJsonValidationErrors('assigned_designer_id');
        $this->assertSame($designerUser->id, (int) $ticket->refresh()->assigned_designer_id);
    }

    /**
     * «أرجِعها إلى الطابور المشترك» after somebody has already taken it — the designer who went
     * home sick.
     *
     * **Asserted from the next designer's side rather than from the columns**, because the failure
     * this pins was invisible in the row: clearing `assigned_designer_id` alone left `accepted_at`
     * set, and the pool is defined by both. The ticket then belonged to nobody, appeared in no
     * queue, and could be seen only by the designer it had just been taken from. Reading it back
     * through the list is the only way to catch that, since every column involved looked plausible.
     */
    public function test_returning_an_accepted_ticket_to_the_pool_releases_it_to_the_other_designers(): void
    {
        // Arrange — one designer takes the job, then stops being available.
        [, $employee] = $this->employee();
        [$first, $firstHeaders] = $this->designer();
        [, $secondHeaders] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $first->id]),
                $employee,
            )->json('data.id'),
        );

        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $firstHeaders)
            ->assertOk();

        // Act — the supervisor hands it back to the pool.
        $released = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => null],
            $employee,
        );

        // Assert — it is genuinely unclaimed again, not merely unaddressed.
        $released->assertOk();

        $ticket->refresh();
        $this->assertNull($ticket->assigned_designer_id);
        $this->assertNull($ticket->accepted_by_user_id);
        $this->assertNull($ticket->accepted_at);
        $this->assertSame(DesignTicketStatus::New, $ticket->status);

        // The pool a designer actually scrolls. This is the assertion that used to fail.
        $this->getJson('/api/v1/design-tickets?designer=none', $secondHeaders)
            ->assertOk()
            ->assertJsonPath('data.0.id', $ticket->id);

        // And somebody else can now pick it up — «لا يضيع الطلب» is the whole point.
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $secondHeaders)
            ->assertOk();
    }

    /**
     * The same move on a ticket nobody had taken yet leaves the status alone.
     *
     * A ticket that was merely *addressed* to a designer is still «جديد», so a release has no
     * claim to undo — and rewriting the status to the value it already held would put a move in
     * the history that nobody made.
     */
    public function test_returning_an_unaccepted_ticket_to_the_pool_changes_only_the_address(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $designerUser->id]),
                $employee,
            )->json('data.id'),
        );

        // Act
        $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => null],
            $employee,
        )->assertOk();

        // Assert
        $ticket->refresh();
        $this->assertNull($ticket->assigned_designer_id);
        $this->assertNull($ticket->accepted_at);
        $this->assertSame(DesignTicketStatus::New, $ticket->status);
    }
}
