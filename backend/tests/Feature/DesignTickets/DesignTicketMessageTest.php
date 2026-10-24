<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\DesignTicket\Models\DesignTicketMessageAttachment;
use App\Domain\Identity\Enums\PermissionName;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

/**
 * محادثة تذكرة التصميم: نصٌّ وصورةٌ وصوت، والاقتباس، والإعادة الآمنة، والتعديل والسحب، ومَن يكتب.
 *
 * **على قواعد التذاكر الداخلية نفسها** (DESIGN-TICKET-CHAT §٣): صاحبُ الرسالة وحده يعدّلها أو
 * يسحبها، خلال عشرين دقيقة. ومَن يكتب هو مَن يرى التذكرة، كما كان قبل أن تصير محادثة.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class DesignTicketMessageTest extends DesignTicketTestCase
{
    public function test_the_designer_replies_in_words(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $employeeHeaders, ['body' => 'الشعار في المرفقات'])->assertCreated();

        // Act
        $response = $this->say($ticket, $designerHeaders, ['body' => 'وصلني، أبدأ اليوم']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم إرسال الرسالة')
            ->assertJsonPath('data.messages.1.body', 'وصلني، أبدأ اليوم')
            ->assertJsonPath('data.messages.1.author.id', $designer->id)
            ->assertJsonPath('data.messages.1.is_mine', true)
            ->assertJsonPath('data.messages.0.is_mine', false)
            ->assertJsonPath('data.messages.1.can_edit', true)
            ->assertJsonPath('data.messages.1.attachments', [])
            ->assertJsonPath('data.can_reply', true)
            ->assertJsonPath('data.closed_note', null)
            ->assertJsonPath('data.ticket.code', $ticket->code)
            ->assertJsonPath('data.ticket.requester.id', $employee->id)
            ->assertJsonPath('data.ticket.designer.id', $designer->id);
    }

    public function test_the_thread_reads_oldest_first(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $employeeHeaders, ['body' => 'الأولى'])->assertCreated();
        $this->say($ticket, $designerHeaders, ['body' => 'الثانية'])->assertCreated();

        // Act
        $response = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $employeeHeaders);

        // Assert
        $response->assertOk()
            ->assertJsonCount(2, 'data.messages')
            ->assertJsonPath('data.messages.0.body', 'الأولى')
            ->assertJsonPath('data.messages.1.body', 'الثانية');
    }

    public function test_a_photo_with_a_caption(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $response = $this->say($ticket, $employeeHeaders, [
            'body' => 'هكذا يريد الزبون الكيس',
            'file' => $this->image('sample.png'),
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.0.body', 'هكذا يريد الزبون الكيس')
            ->assertJsonPath('data.messages.0.attachments.0.kind', 'image')
            ->assertJsonPath('data.messages.0.attachments.0.width_px', 1200)
            ->assertJsonPath('data.messages.0.attachments.0.height_px', 1600);

        $attachment = DesignTicketMessageAttachment::query()->sole();
        $this->assertStringStartsWith("design-ticket-messages/{$ticket->id}/", $attachment->path);
        Storage::disk((string) config('media.design_ticket_message_attachments.disk'))
            ->assertExists($attachment->path);
    }

    public function test_a_voice_note_keeps_its_length_and_waveform(): void
    {
        // Arrange
        [$employee] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $waveform = array_map(fn (int $i) => $i * 2, range(0, 47));

        // Act
        $response = $this->say($ticket, $designerHeaders, [
            'file' => $this->voice(),
            'duration_seconds' => 42,
            'waveform' => $waveform,
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.0.body', null)
            ->assertJsonPath('data.messages.0.attachments.0.kind', 'voice')
            ->assertJsonPath('data.messages.0.attachments.0.kind_label', 'رسالة صوتية')
            ->assertJsonPath('data.messages.0.attachments.0.duration_seconds', 42)
            ->assertJsonPath('data.messages.0.attachments.0.waveform', $waveform);

        $this->assertStringEndsWith('.m4a', DesignTicketMessageAttachment::query()->sole()->path);
    }

    public function test_the_limits_are_the_internal_tickets_limits(): void
    {
        // Arrange — حدودٌ واحدة للمحادثتين (السؤال ٧).
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $bigVoice = $this->say($ticket, $employeeHeaders, ['file' => $this->voice(6145)]);
        $bigPhoto = $this->say($ticket, $employeeHeaders, [
            'file' => UploadedFile::fake()->image('huge.jpg')->size(10241),
        ]);
        $tooLong = $this->say($ticket, $employeeHeaders, ['file' => $this->voice(), 'duration_seconds' => 301]);

        // Assert
        $bigVoice->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'الرسالة الصوتية لا يمكن أن تتجاوز 6 ميغابايت');
        $bigPhoto->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'الصورة لا يمكن أن تتجاوز 10 ميغابايت');
        $tooLong->assertUnprocessable()
            ->assertJsonPath('errors.duration_seconds.0', 'الرسالة الصوتية لا تتجاوز خمس دقائق');
        $this->assertSame(0, DesignTicketMessage::query()->count());
    }

    public function test_a_pdf_belongs_in_the_attachments_not_in_the_chat(): void
    {
        // Arrange — السؤال ٦: الملفات مكانها قسم «المرفقات».
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $response = $this->say($ticket, $employeeHeaders, [
            'file' => UploadedFile::fake()->create('brief.pdf', 100, 'application/pdf'),
        ]);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'المرفق يجب أن يكون صورة (JPG أو PNG أو WEBP) أو رسالة صوتية');
    }

    public function test_a_message_needs_words_or_a_file(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $response = $this->say($ticket, $employeeHeaders, ['body' => '   ']);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.body.0', 'اكتب رسالتك أو أرفق صورة أو رسالة صوتية');
    }

    public function test_a_retry_with_the_same_token_returns_the_same_message(): void
    {
        // Arrange — الشبكة انقطعت بعد أن وصل الطلب وقبل أن يصل الجواب.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $payload = ['body' => 'هل وصلتك؟', 'client_token' => 'tok-1'];

        // Act
        $first = $this->say($ticket, $employeeHeaders, $payload);
        $second = $this->say($ticket, $employeeHeaders, $payload);

        // Assert
        $first->assertCreated();
        $second->assertCreated()->assertJsonCount(1, 'data.messages');
        $this->assertSame(1, DesignTicketMessage::query()->count());
    }

    public function test_a_reply_quotes_a_message_from_the_same_ticket(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $quoted = $this->say($ticket, $employeeHeaders, ['file' => $this->voice()])->json('data.messages.0.id');

        // Act
        $response = $this->say($ticket, $designerHeaders, [
            'body' => 'فهمت',
            'reply_to_message_id' => $quoted,
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.1.reply_to.id', $quoted)
            ->assertJsonPath('data.messages.1.reply_to.author_name', $employee->name)
            ->assertJsonPath('data.messages.1.reply_to.preview', '🎤 رسالة صوتية')
            ->assertJsonPath('data.messages.1.reply_to.is_deleted', false);
    }

    public function test_a_reply_cannot_quote_another_ticket(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $other = $this->conversationBetween($employee, $designer);
        $elsewhere = $this->say($other, $employeeHeaders, ['body' => 'في تذكرةٍ أخرى'])->json('data.messages.0.id');

        // Act
        $response = $this->say($ticket, $employeeHeaders, [
            'body' => 'ردّ',
            'reply_to_message_id' => $elsewhere,
        ]);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.reply_to_message_id.0', 'الرسالة المقتبسة ليست في هذه التذكرة');
    }

    public function test_whoever_sees_the_ticket_may_write_on_it_as_before(): void
    {
        // Arrange — مديرٌ يرى التذاكر كلَّها، ولا اسمَ له عليها.
        [$employee] = $this->employee();
        [$designer] = $this->designer();
        [, $manager] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
        );
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $response = $this->say($ticket, $manager, ['body' => 'استعجلوا، الزبون ينتظر']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.is_party', false)
            ->assertJsonPath('data.can_reply', true);
    }

    public function test_a_colleagues_ticket_is_not_found(): void
    {
        // Arrange — مأخوذة، فليست في الصفّ المشترك، ولا يراها غريب.
        [$employee] = $this->employee();
        [$designer] = $this->designer();
        [, $stranger] = $this->actor(PermissionName::ViewDesignTickets);
        $ticket = $this->conversationBetween($employee, $designer);

        // Act
        $read = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $stranger);
        $written = $this->say($ticket, $stranger, ['body' => 'مرحبا']);

        // Assert — ٤٠٤ لا ٤٠٣: مَن لا يرى التذكرة لا يُقال له إنها موجودة.
        $read->assertNotFound();
        $written->assertNotFound();
        $this->assertSame(0, DesignTicketMessage::query()->count());
    }

    public function test_the_author_edits_within_twenty_minutes_and_it_reads_edited(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, ['body' => 'الأسود'])->json('data.messages.0.id');
        $this->travel(19)->minutes();

        // Act
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/{$id}",
            ['body' => 'الأسود المطفي'],
            $employeeHeaders,
        );

        // Assert
        $response->assertOk()
            ->assertJsonPath('message', 'تم تعديل الرسالة')
            ->assertJsonPath('data.body', 'الأسود المطفي')
            ->assertJsonPath('data.is_edited', true);

        $message = DesignTicketMessage::query()->findOrFail($id);
        $this->assertSame('الأسود', $message->original_body);
        $this->assertArrayNotHasKey('original_body', $response->json('data'));
    }

    public function test_after_twenty_one_minutes_the_author_can_no_longer_edit(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, ['body' => 'الأسود'])->json('data.messages.0.id');
        $this->travel(21)->minutes();

        // Act
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/{$id}",
            ['body' => 'الأبيض'],
            $employeeHeaders,
        );

        // Assert
        $response->assertForbidden()->assertJsonPath('message', 'مضت 20 دقيقة على إرسال الرسالة');
        $this->assertSame('الأسود', DesignTicketMessage::query()->findOrFail($id)->body);
    }

    public function test_nobody_edits_a_colleagues_message_not_even_a_moderator(): void
    {
        // Arrange — السؤال ١: «إدارة الملاحظات» لا تمتدّ إلى المحادثة.
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        [, $moderator] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ModerateComments,
        );
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, ['body' => 'الأسود'])->json('data.messages.0.id');

        // Act
        $edited = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/{$id}",
            ['body' => 'الأبيض'],
            $moderator,
        );
        $removed = $this->deleteJson("/api/v1/design-tickets/{$ticket->id}/messages/{$id}", [], $moderator);
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $moderator);

        // Assert
        $edited->assertForbidden()->assertJsonPath('message', 'هذه الرسالة ليست لك');
        $removed->assertForbidden();
        $list->assertOk()
            ->assertJsonPath('data.messages.0.can_edit', false)
            ->assertJsonPath('data.messages.0.can_delete', false)
            ->assertJsonPath('data.messages.0.mutation_block_reason', 'هذه الرسالة ليست لك');
    }

    public function test_a_deleted_message_stays_in_place_and_says_so(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer, $designerHeaders] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $id = $this->say($ticket, $employeeHeaders, [
            'body' => 'هذه الصورة',
            'file' => $this->image(),
        ])->json('data.messages.0.id');
        $this->say($ticket, $designerHeaders, ['body' => 'ما هي؟', 'reply_to_message_id' => $id])->assertCreated();

        // Act
        $response = $this->deleteJson("/api/v1/design-tickets/{$ticket->id}/messages/{$id}", [], $employeeHeaders);
        $list = $this->getJson("/api/v1/design-tickets/{$ticket->id}/messages", $designerHeaders);

        // Assert
        $response->assertOk()
            ->assertJsonPath('message', 'تم حذف الرسالة')
            ->assertJsonPath('data.is_deleted', true);
        $list->assertOk()
            ->assertJsonCount(2, 'data.messages')
            ->assertJsonPath('data.messages.0.body', 'تم حذف هذه الرسالة')
            ->assertJsonPath('data.messages.0.attachments', [])
            ->assertJsonPath('data.messages.1.reply_to.is_deleted', true)
            ->assertJsonPath('data.messages.1.reply_to.preview', 'تم حذف هذه الرسالة');

        // سحبٌ لا حذف: الرسالةُ وملفُّها باقيان للتدقيق.
        $this->assertNotNull(DesignTicketMessage::query()->findOrFail($id)->retracted_at);
        Storage::disk((string) config('media.design_ticket_message_attachments.disk'))
            ->assertExists(DesignTicketMessageAttachment::query()->sole()->path);
    }

    public function test_a_message_of_another_ticket_is_not_found_through_this_one(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $other = $this->conversationBetween($employee, $designer);
        $elsewhere = $this->say($other, $employeeHeaders, ['body' => 'هناك'])->json('data.messages.0.id');

        // Act
        $response = $this->patchJson(
            "/api/v1/design-tickets/{$ticket->id}/messages/{$elsewhere}",
            ['body' => 'هنا'],
            $employeeHeaders,
        );

        // Assert
        $response->assertNotFound();
    }

    public function test_the_conversation_goes_with_the_ticket(): void
    {
        // Arrange
        [$employee, $employeeHeaders] = $this->employee();
        [$designer] = $this->designer();
        $ticket = $this->conversationBetween($employee, $designer);
        $this->say($ticket, $employeeHeaders, ['body' => 'نص', 'file' => $this->image()])->assertCreated();

        // Act
        $ticket->delete();

        // Assert — يُحذف حذفاً ناعماً معها، فلا يبقى خيطٌ يشير إلى تذكرةٍ يقول الـAPI إنها غير موجودة.
        $this->assertSoftDeleted(DesignTicketMessage::query()->withTrashed()->sole());
        $this->assertSoftDeleted(DesignTicketMessageAttachment::query()->withTrashed()->sole());
        $this->assertInstanceOf(DesignTicket::class, DesignTicket::withTrashed()->find($ticket->id));
    }
}
