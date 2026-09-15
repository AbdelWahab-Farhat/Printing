<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Support\Facades\Storage;

/**
 * The road the brief describes, walked end to end.
 *
 * `جديد → قيد التصميم → بانتظار المراجعة → مكتمل`, and the same road with «تعديل مطلوب» in the
 * middle of it — twice, because "أكثر من دورة تعديل لنفس الطلب" is an acceptance criterion and one
 * round would not prove it.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketFlowTest extends DesignTicketTestCase
{
    public function test_a_ticket_is_raised_and_starts_new_in_the_shared_pool(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $customer = $this->customer();

        // Act
        $response = $this->postJson('/api/v1/design-tickets', $this->payload($customer), $headers);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.status', DesignTicketStatus::New->value)
            ->assertJsonPath('data.status_label', 'جديد')
            ->assertJsonPath('data.is_in_shared_pool', true)
            // The snapshot, taken from the resolved customer rather than from the body.
            ->assertJsonPath('data.customer_name', 'متجر إكس');

        $ticket = DesignTicket::query()->sole();
        $this->assertSame('D'.$ticket->id, $ticket->code);
    }

    public function test_the_whole_road_from_new_to_completed(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        // Act — accept
        $accepted = $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer);

        // Assert
        $accepted->assertOk()
            ->assertJsonPath('data.status', DesignTicketStatus::InProgress->value)
            ->assertJsonPath('data.accepted_by.id', $designerUser->id)
            ->assertJsonPath('data.is_in_shared_pool', false);

        // Act — submit
        $submitted = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v1.png'), 'note' => 'النسخة الأولى'],
            $designer,
        );

        // Assert
        $submitted->assertCreated()
            ->assertJsonPath('data.version', 1)
            ->assertJsonPath('data.status', DesignSubmissionStatus::Proposed->value);

        $this->assertSame(
            DesignTicketStatus::UnderReview,
            $ticket->refresh()->status,
        );

        $versionId = $submitted->json('data.id');

        // Act — approve
        $approved = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$versionId}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        );

        // Assert — the version is sealed, the ticket is closed, and the artwork is on the
        // customer's account. All four are one fact; the CHECK constraint refuses any part of it.
        $approved->assertOk()->assertJsonPath('data.status', DesignSubmissionStatus::Approved->value);

        $ticket->refresh();
        $this->assertSame(DesignTicketStatus::Completed, $ticket->status);
        $this->assertNotNull($ticket->completed_at);
        $this->assertNotNull($ticket->approved_customer_design_id);

        $design = CustomerDesign::query()->sole();
        $this->assertSame($customer->id, $design->customer_id);
        $this->assertSame($ticket->id, $design->design_ticket_id);
        $this->assertSame($designerUser->id, $design->designer_user_id);
        $this->assertNotNull($design->approved_at);
        // The label comes from the ticket's title, not the filename: the label is the whole way
        // staff tell two designs apart months later.
        $this->assertSame('تصميم كيس شحن — أسود', $design->label);
    }

    public function test_two_revision_rounds_happen_on_the_same_ticket_and_keep_every_version(): void
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

        // Act — two full rounds of «تعديل مطلوب» followed by a new version
        for ($round = 1; $round <= 2; $round++) {
            $pending = DesignTicketFile::query()
                ->where('status', DesignSubmissionStatus::Proposed)->sole();

            $this->postJson(
                "/api/v1/design-tickets/{$ticket->id}/versions/{$pending->id}/review",
                [
                    'verdict' => DesignSubmissionStatus::ChangesRequested->value,
                    'note' => "كبّر الشعار — الجولة {$round}",
                ],
                $employee,
            )->assertOk();

            $this->assertSame(DesignTicketStatus::ChangesRequested, $ticket->refresh()->status);

            // No second acceptance: a revision must not cost an extra tap.
            $this->postJson(
                "/api/v1/design-tickets/{$ticket->id}/versions",
                ['file' => $this->image("v{$round}b.png")],
                $designer,
            )->assertCreated();

            $this->assertSame(DesignTicketStatus::UnderReview, $ticket->refresh()->status);
        }

        // Assert — one ticket, three versions, numbered in order, and the notes still readable.
        $this->assertSame(1, DesignTicket::query()->count());

        $versions = $ticket->versions()->get();
        $this->assertSame([1, 2, 3], $versions->pluck('version')->all());
        $this->assertSame('كبّر الشعار — الجولة 1', $versions[0]->review_note);
        $this->assertSame('كبّر الشعار — الجولة 2', $versions[1]->review_note);
        $this->assertTrue($versions[2]->isAwaitingReview());
    }

    public function test_approving_a_file_already_in_the_library_does_not_store_it_twice(): void
    {
        // Arrange — the same bytes uploaded by hand first, then drawn again through a ticket.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        // A separate actor: putting a file straight into a customer's library is
        // `customers.manage`, which somebody who only raises design tickets has no reason to hold.
        [, $librarian] = $this->actor(
            PermissionName::ViewCustomers,
            PermissionName::ManageCustomers,
        );
        $customer = $this->customer();

        $this->postJson(
            "/api/v1/customers/{$customer->id}/designs",
            ['file' => $this->image('logo.png')],
            $librarian,
        )->assertCreated();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        // The same checksum: `UploadedFile::fake()->image()` with identical dimensions and name
        // produces identical bytes.
        $version = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('logo.png')],
            $designer,
        )->json('data.id');

        // Act
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();

        // Assert — one row, not two, and it now knows which ticket produced it.
        $design = CustomerDesign::query()->sole();
        $this->assertSame($ticket->id, $design->design_ticket_id);
        $this->assertSame($design->id, $ticket->refresh()->approved_customer_design_id);
    }

    public function test_a_cancelled_ticket_records_why_and_keeps_its_versions(): void
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

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/cancellation",
            ['reason' => 'الزبون غيّر رأيه'],
            $employee,
        );

        // Assert — the work that was done stays visible. Hiding it would make the cancellation
        // look as though the ticket had never had any.
        $response->assertOk()
            ->assertJsonPath('data.status', DesignTicketStatus::Cancelled->value)
            ->assertJsonPath('data.cancellation_reason', 'الزبون غيّر رأيه');

        $this->assertSame(1, $ticket->refresh()->versions()->count());
    }

    public function test_cancelling_without_a_reason_is_refused(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/cancellation", [], $employee);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('reason');
        $this->assertSame(DesignTicketStatus::New, $ticket->refresh()->status);
    }

    public function test_a_closed_ticket_refuses_new_work_but_keeps_its_history(): void
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
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();

        // Act
        $upload = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('late.png')],
            $designer,
        );
        $history = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employee);

        // Assert — «الاحتفاظ بسجل كامل للتذكرة حتى بعد إغلاقها»: shut to writes, open to reads.
        $upload->assertStatus(422);
        $history->assertOk()
            ->assertJsonPath('data.status', DesignTicketStatus::Completed->value)
            ->assertJsonCount(1, 'data.versions');
    }

    public function test_the_file_is_stored_on_the_designs_disk_and_never_replaced(): void
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

        $first = $ticket->versions()->sole();

        // Act — a change request, then a different file
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$first->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value, 'note' => 'كبّر الشعار'],
            $employee,
        )->assertOk();

        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v2.png')],
            $designer,
        )->assertCreated();

        // Assert — the first file is still exactly where it was. There is no endpoint that swaps
        // a version's bytes, and this is what that commitment looks like from outside.
        Storage::disk('local')->assertExists($first->path);
        $this->assertSame($first->path, $first->refresh()->path);
        $this->assertSame(2, $ticket->refresh()->versions()->count());
    }
}
