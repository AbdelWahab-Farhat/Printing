<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use Spatie\Activitylog\Models\Activity;

/**
 * ✓✓ — «قرأها» بين الطالب والمصمّم (DESIGN-TICKET-CHAT §٣، السؤال ٥).
 *
 * مؤشّران على التذكرة، لكلّ طرفٍ واحد، بقواعد التذاكر الداخلية: يتقدّم إلى آخر ما عُرض، ولا يرجع،
 * والكاتبُ قرأ ما قبل كتابته. **ومَن ليس طرفاً لا يحرّك شيئاً**: مديرٌ يفتح المحادثة لا يجعلها ✓✓
 * عند أحد. **والمصمّمُ الجديد لم يقرأ شيئاً**: إعادةُ الإسناد تصفّر مؤشّره.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class DesignTicketReadReceiptTest extends DesignTicketTestCase
{
    public function test_the_writer_has_read_everything_before_their_own_message(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $response = $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات']);

        // Assert — مؤشّرُ الطالب على رسالته، ومؤشّرُ المصمّم لم يتحرّك، فهي ✓ لا ✓✓.
        $id = $response->assertCreated()->json('data.messages.0.id');
        $response->assertJsonPath('data.read_up_to.requester', $id)
            ->assertJsonPath('data.read_up_to.designer', null)
            ->assertJsonPath('data.counterpart_read_up_to', null);
    }

    public function test_opening_the_thread_reads_it_and_the_writer_sees_two_ticks(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات'])->json('data.messages.0.id');

        // Act
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $designerHeaders)->assertOk();
        $seenByWriter = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $employeeHeaders);

        // Assert
        $seenByWriter->assertOk()
            ->assertJsonPath('data.read_up_to.designer', $id)
            ->assertJsonPath('data.counterpart_read_up_to', $id);
    }

    public function test_opening_the_thread_clears_the_badge(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $designerHeaders, ['body' => 'جاري التعديل'])->assertCreated();

        // Act
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $employeeHeaders)->assertOk();

        // Assert — مَن فتح المحادثة قرأ جرسها، كما في التذاكر الداخلية.
        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employeeHeaders)
            ->assertOk()
            ->assertJsonPath('data.unread_comments_count', 0);
    }

    public function test_a_reader_who_is_neither_party_moves_nothing(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        [, $manager] = $this->actor(PermissionName::ViewDesignTickets, PermissionName::ViewAllDesignTickets);
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات'])->assertCreated();

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $manager);
        $read = $this->postJson("/api/v1/design-tickets/{$ticket->id}/messages/read", [], $manager);

        // Assert — المديرُ يرى المؤشّرين كما هما، ولا «طرفَ آخر» عنده.
        $response->assertOk()
            ->assertJsonPath('data.read_up_to.designer', null)
            ->assertJsonPath('data.counterpart_read_up_to', null);
        $read->assertOk();
        $this->assertNull($ticket->refresh()->designer_read_message_id);
    }

    public function test_a_slower_read_does_not_take_the_cursor_back(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $first = $this->say($ticket, $employeeHeaders, ['body' => 'الأولى'])->json('data.messages.0.id');
        $second = $this->say($ticket, $employeeHeaders, ['body' => 'الثانية'])->json('data.messages.1.id');

        // Act
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/messages/read", ['up_to_message_id' => $second], $designerHeaders)
            ->assertOk();
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/messages/read", ['up_to_message_id' => $first], $designerHeaders)
            ->assertOk();

        // Assert
        $this->assertSame($second, $ticket->refresh()->designer_read_message_id);
    }

    public function test_the_cursor_cannot_run_past_the_conversation(): void
    {
        // Arrange — رقمٌ من خارج المحادثة لا يجعل رسائلَ لم تُكتب بعد مقروءةً سلفاً.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, ['body' => 'الأولى'])->json('data.messages.0.id');

        // Act
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/read",
            ['up_to_message_id' => $id + 1000],
            $designerHeaders,
        )->assertOk();

        // Assert
        $this->assertSame($id, $ticket->refresh()->designer_read_message_id);
    }

    public function test_a_new_designer_has_read_nothing(): void
    {
        // Arrange — أُسندت إلى مصمّمٍ قرأ المحادثة، ثم إلى غيره قبل أن يقبلها أحد.
        [, $employeeHeaders] = $this->employee();
        [$first, $firstHeaders] = $this->designer();
        [$second] = $this->designer();
        $ticket = DesignTicket::query()->findOrFail(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($this->customer(), ['assigned_designer_id' => $first->id]),
                $employeeHeaders,
            )->assertCreated()->json('data.id'),
        );
        $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات'])->assertCreated();
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $firstHeaders)->assertOk();
        $this->assertNotNull($ticket->refresh()->designer_read_message_id);

        // Act
        $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/designer",
            ['assigned_designer_id' => $second->id],
            $employeeHeaders,
        )->assertOk();

        // Assert
        $this->assertNull($ticket->refresh()->designer_read_message_id);
    }

    public function test_reading_writes_nothing_into_the_tickets_history(): void
    {
        // Arrange — كلُّ فتحٍ للمحادثة كان سيكتب سطراً في سجلّ التذكرة.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات'])->assertCreated();
        $before = Activity::query()->where('subject_type', 'design_ticket')->where('subject_id', $ticket->id)->count();

        // Act
        $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $designerHeaders)->assertOk();

        // Assert
        $this->assertNotNull($ticket->refresh()->designer_read_message_id);
        $this->assertSame(
            $before,
            Activity::query()->where('subject_type', 'design_ticket')->where('subject_id', $ticket->id)->count(),
        );
    }
}
