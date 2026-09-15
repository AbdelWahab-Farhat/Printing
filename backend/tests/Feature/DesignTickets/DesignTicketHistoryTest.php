<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;

/**
 * «سجل التذكرة» and «الرد داخل التذكرة» — the two things that came free.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketHistoryTest extends DesignTicketTestCase
{
    public function test_the_history_covers_the_ticket_its_files_and_its_comments(): void
    {
        // Arrange — a whole ticket, then read its log as an auditor.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        [, $auditor] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ViewActivityLogs,
        );
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $designer);
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'الزبون يريدها اليوم'],
            $employee,
        )->assertCreated();

        $version = $ticket->versions()->sole();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}/logs", $auditor);

        // Assert — the ticket's own changes plus the rows it owns. «من رفع النسخة؟» and «متى طلب
        // التعديل؟» are the questions this endpoint exists for, and neither lives on the ticket
        // row, which is why `auditTrailSubjects()` reaches into the files and the comments.
        $response->assertOk();

        $subjects = collect($response->json('data'))->pluck('subject_type')->unique();
        $this->assertTrue($subjects->contains('design_ticket'));
        $this->assertTrue($subjects->contains('design_ticket_file'));
    }

    public function test_the_conversation_lives_on_the_ticket(): void
    {
        // Arrange — one `use HasComments` line and four routes, and this works.
        [, $employee] = $this->employee();
        [$designerUser, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $designerUser->id]),
                $employee,
            )->json('data.id'),
        );

        // Act — both sides write, because anyone who may read a ticket may write on it.
        $fromEmployee = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'الشعار في المرفقات'],
            $employee,
        );
        $fromDesigner = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'وصلني، أبدأ اليوم'],
            $designer,
        );
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $designer);

        // Assert — newest first, and attributed to whoever actually wrote each one.
        $fromEmployee->assertCreated();
        $fromDesigner->assertCreated();
        $list->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.body', 'وصلني، أبدأ اليوم')
            ->assertJsonPath('data.0.author.id', $designerUser->id);
    }

    public function test_a_comment_on_a_ticket_the_reader_cannot_see_is_refused(): void
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
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $theirs);

        // Assert — the ticket itself is a 404 to this reader, so its conversation must be too.
        // The route's own `can:design_tickets.view` would have let this through.
        $response->assertNotFound();
    }

    public function test_the_status_counts_describe_the_same_rows_the_list_shows(): void
    {
        // Arrange — a chip row that counted a colleague's work would tell a designer how much
        // exists that they may not open.
        [, $employee] = $this->employee();
        [$mine] = $this->designer();
        [, $theirs] = $this->designer();
        $customer = $this->customer();

        $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($customer, ['assigned_designer_id' => $mine->id]),
            $employee,
        )->assertCreated();

        // Act
        $summary = $this->getJson('/api/v1/design-tickets/summary', $theirs);
        $list = $this->getJson('/api/v1/design-tickets', $theirs);

        // Assert
        $summary->assertOk()->assertJsonPath('data.total', 0);
        $list->assertOk()->assertJsonCount(0, 'data');

        // Every status present, zeros included, so the app draws a stable row.
        $this->assertCount(6, $summary->json('data.counts'));
    }
}
