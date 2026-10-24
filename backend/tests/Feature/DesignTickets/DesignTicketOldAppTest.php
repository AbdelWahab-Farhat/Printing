<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Comment\Models\Comment;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;

/**
 * نسخةُ تطبيق الموظفين القديمة، يومَ تنتقل المحادثة إلى الرسائل (DESIGN-TICKET-CHAT §٣، السؤال ٣).
 *
 * **تقرأ ولا تكتب.** تطلب `/comments` كما كانت، فتجد الملاحظات القديمة في مكانها، ومكانَ الصندوق
 * «حدّث التطبيق لتكتب في المحادثة». ولو بقيت تكتب لكتبت ملاحظاتٍ لا يراها زميلُها في المحادثة
 * الجديدة — وهذا أسوأ من ألّا تكتب.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class DesignTicketOldAppTest extends DesignTicketTestCase
{
    public function test_the_old_notes_still_read_and_say_to_update(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->noteOn($ticket, $designer, 'وصلني، أبدأ اليوم');

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $employeeHeaders);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.body', 'وصلني، أبدأ اليوم')
            ->assertJsonPath('data.0.can_edit', false)
            ->assertJsonPath('meta.can_comment', false)
            ->assertJsonPath('meta.closed_note', 'حدّث التطبيق لتكتب في المحادثة');
    }

    public function test_the_old_app_cannot_write_a_note_nobody_would_see(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $response = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/comments",
            ['body' => 'الشعار في المرفقات'],
            $employeeHeaders,
        );

        // Assert
        $response->assertStatus(422)->assertJsonPath('message', 'حدّث التطبيق لتكتب في المحادثة');
        $this->assertSame(0, Comment::query()->count());
    }

    public function test_a_closed_ticket_still_says_how_it_ended(): void
    {
        // Arrange — النهايةُ أصدقُ من «حدّث التطبيق»: لا شيء يُكتب فيها في أيّ نسخة.
        [$employee, $employeeHeaders] = $this->employee();
        $ticket = DesignTicket::factory()->cancelled()->create(['requested_by_user_id' => $employee->getKey()]);

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}/comments", $employeeHeaders);

        // Assert
        $response->assertOk()->assertJsonPath('meta.closed_note', 'أُلغيت التذكرة وأُغلقت المحادثة');
    }

    public function test_the_old_app_still_clears_its_badge(): void
    {
        // Arrange — النسخة القديمة تطلب `comments/read` عند فتح الملاحظات.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $designerHeaders, ['body' => 'جاري التعديل'])->assertCreated();

        // Act
        $response = $this->postJson("/api/v1/design-tickets/{$ticket->id}/comments/read", [], $employeeHeaders);

        // Assert
        $response->assertOk()->assertJsonPath('data.unread_total', 0);
    }

    private function noteOn(DesignTicket $ticket, User $author, string $body): void
    {
        $comment = new Comment(['body' => $body]);
        $comment->commentable()->associate($ticket);
        $comment->user_id = (int) $author->getKey();
        $comment->save();
    }
}
