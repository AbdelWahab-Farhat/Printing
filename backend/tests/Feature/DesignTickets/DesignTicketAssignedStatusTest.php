<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Support\Carbon;

/**
 * «مُسنَد»: a ticket addressed to a designer who has not accepted it yet.
 *
 * Every move is driven through the real endpoints.
 *
 * Arrange - Act - Assert.
 */
class DesignTicketAssignedStatusTest extends DesignTicketTestCase
{
    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $overrides
     */
    private function raise(array $headers, array $overrides = []): DesignTicket
    {
        return DesignTicket::query()->findOrFail(
            $this->postJson('/api/v1/design-tickets', $this->payload($this->customer(), $overrides), $headers)
                ->assertCreated()
                ->json('data.id'),
        );
    }

    /** @param array<string, string> $headers */
    private function assign(DesignTicket $ticket, ?int $designerId, array $headers): void
    {
        $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => $designerId],
            $headers,
        )->assertOk();
    }

    public function test_a_ticket_raised_with_a_designer_starts_assigned(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();

        // Act
        $response = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), ['assigned_designer_id' => $designerUser->id]),
            $employee,
        );

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.status', DesignTicketStatus::Assigned->value)
            ->assertJsonPath('data.status_label', 'مُسنَد')
            ->assertJsonPath('data.designer.id', $designerUser->id);
    }

    public function test_assigning_stamps_the_status_change(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $ticket = $this->raise($employee);

        // Act
        $this->travel(1)->minutes();
        $at = Carbon::now()->toDateTimeString();
        $this->assign($ticket, $designerUser->id, $employee);

        // Assert
        $ticket->refresh();
        $this->assertSame(DesignTicketStatus::Assigned, $ticket->status);
        $this->assertSame($at, $ticket->status_changed_at->toDateTimeString());
    }

    public function test_moving_an_assigned_ticket_to_another_designer_keeps_it_assigned(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$first] = $this->designer();
        [$second] = $this->designer();
        $ticket = $this->raise($employee, ['assigned_designer_id' => $first->id]);
        $stamp = $ticket->status_changed_at->toDateTimeString();

        // Act
        $this->travel(1)->minutes();
        $this->assign($ticket, $second->id, $employee);

        // Assert — same status, so the time on the card does not move either.
        $ticket->refresh();
        $this->assertSame(DesignTicketStatus::Assigned, $ticket->status);
        $this->assertSame($second->id, (int) $ticket->assigned_designer_id);
        $this->assertSame($stamp, $ticket->status_changed_at->toDateTimeString());
    }

    public function test_the_designer_accepting_moves_it_to_in_progress(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser, $designer] = $this->designer();
        $ticket = $this->raise($employee, ['assigned_designer_id' => $designerUser->id]);

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer);

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.status', DesignTicketStatus::InProgress->value)
            ->assertJsonPath('data.accepted_by.id', $designerUser->id);
    }

    public function test_another_designer_still_cannot_accept_an_assigned_ticket(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        [, $other] = $this->designer();
        $ticket = $this->raise($employee, ['assigned_designer_id' => $designerUser->id]);

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $other);

        // Assert
        $response->assertStatus(422);
        $this->assertSame(DesignTicketStatus::Assigned, $ticket->refresh()->status);
    }

    public function test_an_assigned_ticket_can_be_cancelled(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $ticket = $this->raise($employee, ['assigned_designer_id' => $designerUser->id]);

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/cancellation",
            ['reason' => 'الزبون غيّر رأيه'],
            $employee,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.status', DesignTicketStatus::Cancelled->value);
    }

    public function test_the_list_filters_and_counts_assigned_tickets(): void
    {
        // Arrange
        [$supervisor, $headers] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ManageDesignTickets,
            PermissionName::AssignDesignTickets,
        );
        [$designerUser] = $this->designer();
        $this->raise($headers);
        $assigned = $this->raise($headers, ['assigned_designer_id' => $designerUser->id]);

        // Act
        $list = $this->getJson('/api/v1/design-tickets?status=assigned', $headers);
        $summary = $this->getJson('/api/v1/design-tickets/summary', $headers);

        // Assert
        $list->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $assigned->id);
        $summary->assertOk()
            ->assertJsonPath('data.counts.new', 1)
            ->assertJsonPath('data.counts.assigned', 1)
            ->assertJsonPath('data.total', 2);
    }

    public function test_a_dispatcher_accepting_an_unassigned_ticket_is_told_to_assign_it(): void
    {
        // Arrange — the employee holds the assign grant, so accepting from the pool is refused.
        [$employeeUser, $employee] = $this->employee();
        $employeeUser->givePermissionTo(PermissionName::AcceptDesignTickets->value);
        $ticket = $this->raise($employee);

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $employee);

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('message', 'من يوزّع العمل لا يقبل تذكرة «غير مُسنَد لمصمم» — استعمل «إسناد إلى مصمم»');
    }
}
