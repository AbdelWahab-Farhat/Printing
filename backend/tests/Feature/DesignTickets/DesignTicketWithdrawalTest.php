<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Support\Facades\Event;
use Illuminate\Testing\TestResponse;

/**
 * «سحب النسخة» — **المصمّم يصلح ملفاً رفعه خطأً، بلا انتظار أحد.**
 *
 * يسحب نسختَه هو وحده، ما دامت بانتظار المراجعة ولم يحكم عليها أحد. فتعود التذكرة إلى حيث كانت
 * قبل الرفع — «قيد التصميم»، أو «تعديل مطلوب» إن كان طلبُ التعديل قائماً — ويرفع الملفّ الصحيح
 * نسخةً تالية. **والمسحوبةُ لا تُحذف**: تبقى في السجلّ بعلامة «سحبها المصمّم»، كما تبقى كلُّ نسخة.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class DesignTicketWithdrawalTest extends DesignTicketTestCase
{
    /**
     * تذكرةٌ طلبها هذا الموظف وأخذها هذا المصمّم، ونسختُها الأولى بانتظار المراجعة.
     *
     * @param  array<string, string>  $employeeHeaders
     * @param  array<string, string>  $designerHeaders
     */
    private function awaitingReview(array $employeeHeaders, array $designerHeaders): DesignTicket
    {
        $ticket = DesignTicket::query()->findOrFail(
            $this->postJson('/api/v1/design-tickets', $this->payload($this->customer()), $employeeHeaders)
                ->json('data.id'),
        );

        return $this->ticketAwaitingReview($ticket, $designerHeaders);
    }

    /**
     * @param  array<string, string>  $headers
     */
    private function withdraw(DesignTicket $ticket, int $versionId, array $headers): TestResponse
    {
        return $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$versionId}/withdrawal",
            [],
            $headers,
        );
    }

    public function test_the_designer_withdraws_a_wrong_file_and_uploads_the_right_one_at_once(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);
        $wrong = $ticket->versions()->sole();

        // Act
        $withdrawn = $this->withdraw($ticket, $wrong->id, $designer);
        $right = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v2.png')],
            $designer,
        );

        // Assert — المسحوبةُ في مكانها بعلامتها، والصحيحةُ نسخةٌ تالية بانتظار المراجعة.
        $withdrawn->assertOk()
            ->assertJsonPath('message', 'سُحبت النسخة — ارفع الملف الصحيح')
            ->assertJsonPath('data.status', 'withdrawn')
            ->assertJsonPath('data.status_label', 'سحبها المصمّم')
            ->assertJsonPath('data.is_awaiting_review', false);
        $right->assertCreated()->assertJsonPath('data.version', 2);
        $this->assertSame(DesignTicketStatus::UnderReview, $ticket->refresh()->status);
        $this->assertSame(
            [DesignSubmissionStatus::Withdrawn, DesignSubmissionStatus::Proposed],
            $ticket->versions()->get()->map->status->all(),
        );
    }

    public function test_the_first_version_withdrawn_puts_the_ticket_back_in_design(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);

        // Act
        $this->withdraw($ticket, $ticket->versions()->sole()->id, $designer)->assertOk();
        $designerSees = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $designer);
        $employeeSees = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employee);

        // Assert — لا شيء يُراجَع الآن، والرفعُ للمصمّم من جديد.
        $designerSees->assertOk()
            ->assertJsonPath('data.status', DesignTicketStatus::InProgress->value)
            ->assertJsonPath('data.can_submit', true)
            ->assertJsonPath('data.can_withdraw', false);
        $employeeSees->assertOk()->assertJsonPath('data.can_review', false);
    }

    public function test_a_withdrawn_revision_goes_back_to_the_change_request_that_still_stands(): void
    {
        // Arrange — النسخة ١ طُلب تعديلها، والنسخة ٢ رُفعت خطأً.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$ticket->versions()->sole()->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value, 'note' => 'كبّر الشعار'],
            $employee,
        )->assertOk();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v2.png')],
            $designer,
        )->assertCreated();
        $second = $ticket->versions()->where('version', 2)->sole();

        // Act
        $response = $this->withdraw($ticket, $second->id, $designer);

        // Assert
        $response->assertOk();
        $this->assertSame(DesignTicketStatus::ChangesRequested, $ticket->refresh()->status);
    }

    public function test_only_the_uploader_sees_the_button_and_only_while_it_awaits_review(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);

        // Act
        $designerSees = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $designer);
        $employeeSees = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employee);

        // Assert
        $designerSees->assertOk()->assertJsonPath('data.can_withdraw', true);
        $employeeSees->assertOk()->assertJsonPath('data.can_withdraw', false);
    }

    public function test_nobody_but_the_uploader_withdraws_a_version(): void
    {
        // Arrange — صاحب التذكرة، ومصمّمٌ آخر بالصلاحية نفسها.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        [, $colleague] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::AcceptDesignTickets,
            PermissionName::SubmitDesignTickets,
            PermissionName::ViewAllDesignTickets,
        );
        $ticket = $this->awaitingReview($employee, $designer);
        $version = $ticket->versions()->sole();

        // Act
        $byRequester = $this->withdraw($ticket, $version->id, $employee);
        $byColleague = $this->withdraw($ticket, $version->id, $colleague);

        // Assert — الأوّلُ بلا صلاحية الرفع أصلاً، والثاني ليست النسخةُ نسختَه.
        $byRequester->assertForbidden();
        $byColleague->assertForbidden()->assertJsonPath('message', 'يسحب النسخةَ مَن رفعها وحده');
        $this->assertSame(DesignSubmissionStatus::Proposed, $version->refresh()->status);
        $this->assertSame(DesignTicketStatus::UnderReview, $ticket->refresh()->status);
    }

    public function test_a_version_already_judged_cannot_be_withdrawn(): void
    {
        // Arrange — طُلب تعديلها: الحكمُ صدر، وهو سببُ النسخة التالية.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);
        $version = $ticket->versions()->sole();
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::ChangesRequested->value, 'note' => 'غيّر اللون'],
            $employee,
        )->assertOk();

        // Act
        $response = $this->withdraw($ticket, $version->id, $designer);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('message', 'النسخة رقم 1 تمت مراجعتها مسبقاً: تعديل مطلوب');
        $this->assertSame(DesignSubmissionStatus::ChangesRequested, $version->refresh()->status);
    }

    public function test_a_withdrawn_version_cannot_be_reviewed(): void
    {
        // Arrange — شاشةُ المراجِع قديمة: فتحها قبل أن يسحبها المصمّم.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);
        $version = $ticket->versions()->sole();
        $this->withdraw($ticket, $version->id, $designer)->assertOk();

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        );

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('message', 'سحب المصمّم النسخة رقم 1، فلا تُراجَع');
        $this->assertSame(DesignTicketStatus::InProgress, $ticket->refresh()->status);
    }

    public function test_a_cancelled_ticket_keeps_its_versions_as_they_are(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);
        $version = $ticket->versions()->sole();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/cancellation", ['reason' => 'ألغى العميل'], $employee)
            ->assertOk();

        // Act
        $response = $this->withdraw($ticket, $version->id, $designer);

        // Assert
        $response->assertUnprocessable();
        $this->assertSame(DesignSubmissionStatus::Proposed, $version->refresh()->status);
    }

    public function test_withdrawing_rings_no_bell(): void
    {
        // Arrange — صاحبُ التذكرة يُبلَّغ حين يصل الملفّ الصحيح، لا حين يُسحب الخطأ.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);
        Event::fake([DesignTicketProgressed::class]);

        // Act
        $this->withdraw($ticket, $ticket->versions()->sole()->id, $designer)->assertOk();

        // Assert
        Event::assertNotDispatched(DesignTicketProgressed::class);
    }

    public function test_the_withdrawal_is_in_the_history(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$designerUser, $designer] = $this->designer();
        $ticket = $this->awaitingReview($employee, $designer);

        // Act
        $this->withdraw($ticket, $ticket->versions()->sole()->id, $designer)->assertOk();

        // Assert — سجلُّ التدقيق يحفظ مَن سحبها ومتى، كأيّ تغيير.
        $this->assertDatabaseHas('activity_log', [
            'subject_type' => 'design_ticket_file',
            'subject_id' => $ticket->versions()->sole()->id,
            'causer_id' => $designerUser->id,
            'event' => 'updated',
        ]);
    }
}
