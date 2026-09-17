<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;

/**
 * «بعد الاعتماد لا يوجد مزيد» — the conversation ends with the ticket.
 *
 * **A ticket that has finished is a record of what was agreed, and a record that can still be
 * added to is not a record.** {@see DesignTicketStatus::isClosed()} already says it outright —
 * "nothing more will be drawn, reviewed or said" — and the first two halves of that sentence
 * were enforced from the beginning while the third was not: a designer could keep writing under
 * an approved design, and either side could quietly rewrite what they had promised before it was
 * signed off.
 *
 * **Both endings, and everybody.** «ملغى» closes it for the same reason «مكتمل» does: the
 * request is over. And the freeze is not a permission — a moderator is refused too, because what
 * is being protected is the state of the ticket rather than the ownership of a sentence.
 *
 * The app is told before it draws anything: `meta.can_comment` on the list, and `can_edit` /
 * `can_delete` false on every row. This file asserts both halves — the flags that hide the
 * buttons, and the refusals that are the actual rule.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketClosedConversationTest extends DesignTicketTestCase
{
    public function test_an_open_ticket_takes_messages_and_says_so(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $ticket = $this->ticketFor($employee, $designerUser->id);

        // Act — written and then read by its author, whose own note is his to rewrite while the
        // ticket is still open.
        $written = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'الشعار في المرفقات'],
            $employee,
        );
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $employee);

        // Assert — the ordinary case, stated so the closed one below means something.
        $written->assertCreated();
        $list->assertOk()
            ->assertJsonPath('meta.can_comment', true)
            ->assertJsonPath('meta.closed_note', null)
            ->assertJsonPath('data.0.can_edit', true);
    }

    public function test_an_approved_ticket_takes_no_more_messages(): void
    {
        // Arrange — the whole point: «اعتُمد التصميم» is the end of the conversation, for the
        // designer who drew it and for the employee who asked.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->approvedTicket($employee, $designer);

        // Act
        $fromEmployee = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'وكمان غيّر اللون'],
            $employee,
        );
        $fromDesigner = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'تمام'],
            $designer,
        );

        // Assert — 422 and the ticket's own words, so the app shows why rather than «حدث خطأ ما».
        $fromEmployee->assertStatus(422);
        $fromDesigner->assertStatus(422)
            ->assertJsonPath('message', 'اعتُمد التصميم وأُغلقت المحادثة');
    }

    public function test_a_cancelled_ticket_takes_no_more_messages(): void
    {
        // Arrange — the other ending. It is not a verdict on anybody's work, and it ends the
        // request all the same.
        [, $employee] = $this->employee();
        [$designerUser] = $this->designer();
        $ticket = $this->ticketFor($employee, $designerUser->id);

        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/cancellation",
            ['reason' => 'الزبون غيّر رأيه'],
            $employee,
        )->assertOk();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'ليش تلغى؟'],
            $employee,
        );

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('message', 'أُلغيت التذكرة وأُغلقت المحادثة');
    }

    public function test_the_messages_already_in_a_closed_ticket_freeze(): void
    {
        // Arrange — written while the ticket was open, by its author, who could rewrite it
        // freely an hour ago.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->ticketFor($employee);

        $comment = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'اتفقنا على الأسود'],
            $employee,
        )->assertCreated()->json('data.id');

        $this->close($ticket, $employee, $designer);

        // Act
        $rewritten = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/{$comment}",
            ['body' => 'لا، اتفقنا على الأبيض'],
            $employee,
        );
        $removed = $this->deleteJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/{$comment}",
            [],
            $employee,
        );
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $employee);

        // Assert — what was agreed before the sign-off stays as it was written.
        $rewritten->assertStatus(422);
        $removed->assertStatus(422);
        $list->assertOk()
            ->assertJsonPath('meta.can_comment', false)
            ->assertJsonPath('meta.closed_note', 'اعتُمد التصميم وأُغلقت المحادثة')
            ->assertJsonPath('data.0.can_edit', false)
            ->assertJsonPath('data.0.can_delete', false);
    }

    public function test_even_a_moderator_is_refused_after_the_sign_off(): void
    {
        // Arrange — `comments.moderate` is the power to rewrite a colleague's sentence, not the
        // power to reopen a finished ticket. The freeze is about the ticket's state.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        [, $moderator] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ModerateComments,
        );
        $ticket = $this->ticketFor($employee);

        $comment = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'اتفقنا على الأسود'],
            $employee,
        )->assertCreated()->json('data.id');

        $this->close($ticket, $employee, $designer);

        // Act
        $response = $this->deleteJson(
            "/api/v1/design-tickets/{$ticket->id}/comments/{$comment}",
            [],
            $moderator,
        );

        // Assert
        $response->assertStatus(422);
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $moderator)
            ->assertOk()
            ->assertJsonPath('data.0.can_delete', false);
    }

    /**
     * A ticket raised by this employee, optionally already assigned to a designer.
     *
     * @param  array<string, string>  $employee
     */
    private function ticketFor(array $employee, ?int $designerId = null): DesignTicket
    {
        $overrides = $designerId === null ? [] : ['assigned_designer_id' => $designerId];

        return DesignTicket::query()->findOrFail(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($this->customer(), $overrides),
                $employee,
            )->assertCreated()->json('data.id'),
        );
    }

    /**
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     */
    private function approvedTicket(array $employee, array $designer): DesignTicket
    {
        $ticket = $this->ticketFor($employee);
        $this->close($ticket, $employee, $designer);

        return $ticket;
    }

    /**
     * Takes a ticket all the way to «مكتمل»: accepted, a version sent up, and approved.
     *
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     */
    private function close(DesignTicket $ticket, array $employee, array $designer): void
    {
        $this->ticketAwaitingReview($ticket, $designer);

        $version = $ticket->versions()->sole();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();
    }
}
