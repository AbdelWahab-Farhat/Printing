<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;

/**
 * The verdict — and the rule that whoever drew it does not sign it off.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketReviewTest extends DesignTicketTestCase
{
    public function test_the_designer_who_uploaded_a_version_cannot_review_it(): void
    {
        // Arrange — one person holding every grant in the system, including `review`. A permission
        // could never stop this: an administrator holds them all by rule. Only the domain can.
        [, $employee] = $this->employee();
        [, $both] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::AcceptDesignTickets,
            PermissionName::SubmitDesignTickets,
            PermissionName::ReviewDesignTickets,
        );
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $both);
        $version = $ticket->versions()->sole();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $both,
        );

        // Assert — «لا أنصح أن يقوم المصمم نفسه باعتماد التصميم النهائي», made mechanical.
        $response->assertStatus(422)
            ->assertJsonPath('message', 'لا يمكن مراجعة تصميم رفعته بنفسك — الاعتماد من مسؤول آخر');

        $this->assertSame(DesignTicketStatus::UnderReview, $ticket->refresh()->status);
        $this->assertSame(0, CustomerDesign::query()->count());
    }

    public function test_the_resource_tells_the_uploader_not_to_draw_the_review_buttons(): void
    {
        // Arrange — the same situation, asked ahead of time. Without this the uploader would see
        // two buttons the domain then refuses, which reads as a bug rather than as a control.
        [, $employee] = $this->employee();
        [, $both] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::AcceptDesignTickets,
            PermissionName::SubmitDesignTickets,
            PermissionName::ReviewDesignTickets,
        );
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $both);

        // Act
        $uploaderSees = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $both);
        $reviewerSees = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employee);

        // Assert
        $uploaderSees->assertOk()->assertJsonPath('data.can_review', false);
        $reviewerSees->assertOk()->assertJsonPath('data.can_review', true);
    }

    public function test_a_change_request_without_a_note_is_refused(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $designer);
        $version = $ticket->versions()->sole();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value],
            $employee,
        );

        // Assert — a change request with no words turns the history into a count.
        $response->assertStatus(422)->assertJsonValidationErrors('note');
        $this->assertSame(DesignTicketStatus::UnderReview, $ticket->refresh()->status);
    }

    public function test_a_version_is_judged_once(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $designer);
        $version = $ticket->versions()->sole();

        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value, 'note' => 'كبّر الشعار'],
            $employee,
        )->assertOk();

        // Act — a reviewer changing their mind
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        );

        // Assert — rewriting a verdict would erase the reason the next version exists.
        $response->assertStatus(422);
        $this->assertSame('كبّر الشعار', $version->refresh()->review_note);
        $this->assertSame(0, CustomerDesign::query()->count());
    }

    public function test_a_brief_cannot_be_reviewed(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        $brief = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/attachments",
            ['file' => $this->image('reference.png')],
            $employee,
        )->json('data.id');

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$brief}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        );

        // Assert — a 404 rather than a 422: the id names no reviewable thing, which is a question
        // about the URL rather than about the body.
        $response->assertNotFound();
    }

    public function test_proposed_is_not_a_verdict_a_reviewer_may_send(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $designer);
        $version = $ticket->versions()->sole();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Proposed->value],
            $employee,
        );

        // Assert — «بانتظار المراجعة» is where a version arrives, never somewhere a person sends
        // one; offering it would let a reviewer stamp their name on a review that decided nothing.
        $response->assertStatus(422)->assertJsonValidationErrors('verdict');
    }
}
