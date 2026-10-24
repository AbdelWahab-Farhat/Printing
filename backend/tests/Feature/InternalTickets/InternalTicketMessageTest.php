<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketAttachment;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

/**
 * الرسائل: نصٌّ وصورةٌ وصوت، والاقتباس، والإعادة الآمنة، ومَن يكتب في ماذا.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketMessageTest extends InternalTicketTestCase
{
    public function test_the_colleague_replies_in_words(): void
    {
        // Arrange
        [, $mine] = $this->employee('سالم');
        [$colleague, $theirs] = $this->employee('هدى');
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $theirs, ['body' => 'وصلت أمس، في المخزن الآن']);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('message', 'تم إرسال الرسالة')
            ->assertJsonPath('data.messages.1.body', 'وصلت أمس، في المخزن الآن')
            ->assertJsonPath('data.messages.1.author.name', 'هدى')
            ->assertJsonPath('data.messages.1.is_mine', true)
            ->assertJsonPath('data.messages.0.is_mine', false)
            ->assertJsonPath('data.messages.1.can_edit', true);

        $ticket->refresh();
        $this->assertSame((int) $response->json('data.messages.1.id'), $ticket->assignee_read_message_id);
    }

    public function test_a_photo_with_no_words(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $theirs, ['file' => $this->image('shelf.jpg')]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.1.body', null)
            ->assertJsonPath('data.messages.1.attachments.0.kind', 'image')
            ->assertJsonPath('data.messages.1.attachments.0.width_px', 800)
            ->assertJsonPath('data.last_message.preview', 'صورة')
            ->assertJsonPath('data.last_message.kind', 'image');
    }

    public function test_several_photos_go_out_as_one_message_in_the_order_they_were_picked(): void
    {
        // Arrange — كبريمولا: الصورُ وتعليقُها رسالةٌ واحدة.
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->post(
            "/api/v1/internal-tickets/{$ticket->id}/messages",
            ['files' => [$this->image('a.jpg'), $this->image('b.jpg')]],
            $theirs + ['Accept' => 'application/json'],
        );

        // Assert
        $response->assertCreated()
            ->assertJsonCount(2, 'data.messages')
            ->assertJsonCount(2, 'data.messages.1.attachments')
            ->assertJsonPath('data.messages.1.attachments.0.name', 'a.jpg')
            ->assertJsonPath('data.messages.1.attachments.1.name', 'b.jpg')
            ->assertJsonPath('data.last_message.preview', 'صورتان')
            ->assertJsonPath('data.last_message.kind', 'image');
        $this->assertSame(2, InternalTicketAttachment::query()->count());
    }

    public function test_an_album_is_photos_only_and_ten_at_most(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $eleven = array_map(fn (int $i) => $this->image("p{$i}.jpg"), range(1, 11));
        $headers = $theirs + ['Accept' => 'application/json'];
        $url = "/api/v1/internal-tickets/{$ticket->id}/messages";

        // Act
        $withVoice = $this->post($url, ['files' => [$this->image(), $this->voice()]], $headers);
        $tooMany = $this->post($url, ['files' => $eleven], $headers);

        // Assert
        $withVoice->assertUnprocessable()
            ->assertJsonPath('errors', ['files.1' => ['الصورة يجب أن تكون JPG أو PNG أو WEBP']]);
        $tooMany->assertUnprocessable()->assertJsonPath('errors.files.0', 'عشر صور على الأكثر في الرسالة');
    }

    public function test_a_voice_note_keeps_its_length_and_waveform(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $waveform = array_map(fn (int $i) => $i * 2, range(0, 47));

        // Act
        $response = $this->say($ticket, $theirs, [
            'file' => $this->voice(),
            'duration_seconds' => 42,
            'waveform' => $waveform,
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.1.attachments.0.kind', 'voice')
            ->assertJsonPath('data.messages.1.attachments.0.kind_label', 'رسالة صوتية')
            ->assertJsonPath('data.messages.1.attachments.0.duration_seconds', 42)
            ->assertJsonPath('data.messages.1.attachments.0.waveform', $waveform)
            ->assertJsonPath('data.last_message.kind', 'voice')
            ->assertJsonPath('data.last_message.duration_seconds', 42)
            ->assertJsonPath('data.last_message.preview', '🎤 رسالة صوتية');

        $attachment = InternalTicketAttachment::query()->sole();
        $this->assertStringEndsWith('.m4a', $attachment->path);
        Storage::disk((string) config('media.internal_ticket_attachments.disk'))->assertExists($attachment->path);
    }

    public function test_an_m4a_the_phone_boxed_as_video_mp4_is_still_a_voice_note(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $theirs, [
            'file' => UploadedFile::fake()->create('recording.mp4', 40, 'video/mp4'),
            'duration_seconds' => 7,
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.messages.1.attachments.0.kind', 'voice');
        $this->assertStringEndsWith('.m4a', InternalTicketAttachment::query()->sole()->path);
    }

    public function test_a_voice_note_over_six_megabytes_is_refused(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $theirs, ['file' => $this->voice(6145)]);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'الرسالة الصوتية لا يمكن أن تتجاوز 6 ميغابايت');
    }

    public function test_a_photo_up_to_ten_megabytes_is_accepted_and_over_is_refused(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $within = $this->say($ticket, $theirs, ['file' => UploadedFile::fake()->image('big.jpg')->size(10240)]);
        $over = $this->say($ticket, $theirs, ['file' => UploadedFile::fake()->image('huge.jpg')->size(10241)]);

        // Assert
        $within->assertCreated();
        $over->assertUnprocessable()->assertJsonPath('errors.file.0', 'الصورة لا يمكن أن تتجاوز 10 ميغابايت');
    }

    public function test_a_voice_note_longer_than_five_minutes_is_refused(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $theirs, ['file' => $this->voice(), 'duration_seconds' => 301]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['duration_seconds']);
    }

    public function test_a_pdf_is_refused(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $pdf = UploadedFile::fake()->createWithContent('invoice.pdf', "%PDF-1.4\n".str_repeat('a', 1024));

        // Act
        $response = $this->say($ticket, $theirs, ['file' => $pdf]);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.file.0', 'المرفق يجب أن يكون صورة (JPG أو PNG أو WEBP) أو رسالة صوتية');
    }

    public function test_a_message_needs_words_or_a_file(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $theirs, ['body' => '']);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['body']);
    }

    public function test_a_retry_with_the_same_token_returns_the_same_message(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $payload = ['body' => 'تمام', 'client_token' => 'token-1'];

        // Act
        $first = $this->say($ticket, $theirs, $payload);
        $second = $this->say($ticket, $theirs, $payload);

        // Assert
        $first->assertCreated();
        $second->assertCreated();
        $this->assertSame(1, InternalTicketMessage::query()->where('client_token', 'token-1')->count());
    }

    public function test_a_reply_quotes_a_message_from_the_same_ticket(): void
    {
        // Arrange
        [, $mine] = $this->employee('سالم');
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $first = InternalTicketMessage::query()->where('internal_ticket_id', $ticket->id)->firstOrFail();

        // Act
        $response = $this->say($ticket, $theirs, ['body' => 'نعم', 'reply_to_message_id' => $first->id]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.1.reply_to.id', $first->id)
            ->assertJsonPath('data.messages.1.reply_to.author_name', 'سالم')
            ->assertJsonPath('data.messages.1.reply_to.preview', 'هل وصلت الأكياس من المطبعة؟')
            ->assertJsonPath('data.messages.1.reply_to.is_deleted', false);
    }

    public function test_a_reply_cannot_quote_another_ticket(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $elsewhere = InternalTicketMessage::factory()->by($colleague->id)->create();

        // Act
        $response = $this->say($ticket, $theirs, ['body' => 'نعم', 'reply_to_message_id' => $elsewhere->id]);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.reply_to_message_id.0', 'الرسالة المقتبسة ليست في هذه التذكرة');
    }

    public function test_nobody_writes_into_a_closed_ticket(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $mine)->assertOk();

        // Act
        $response = $this->say($ticket, $theirs, ['body' => 'شيء أخير']);

        // Assert
        $response->assertUnprocessable()->assertJsonPath('message', 'التذكرة مغلقة. افتح تذكرة جديدة لتكمل');
        $this->assertSame(1, InternalTicketMessage::query()->count());
    }

    public function test_an_admin_who_is_not_a_party_reads_but_does_not_write(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [, $admin] = $this->admin();
        $ticket = $this->open($mine, $colleague);

        // Act
        $read = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $admin);
        $write = $this->say($ticket, $admin, ['body' => 'أنا هنا']);

        // Assert
        $read->assertOk()->assertJsonPath('data.can_reply', false)->assertJsonPath('data.is_party', false);
        $write->assertForbidden();
        $this->assertSame(1, InternalTicketMessage::query()->count());
    }

    public function test_a_third_colleague_cannot_write_or_even_find_the_ticket(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [, $stranger] = $this->employee();
        $ticket = $this->open($mine, $colleague);

        // Act
        $response = $this->say($ticket, $stranger, ['body' => 'مرحبا']);

        // Assert
        $response->assertNotFound();
    }

    // ─────────────────────────── التعديل والحذف ───────────────────────────

    public function test_the_author_edits_within_twenty_minutes_and_it_reads_edited(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();
        $this->travel(19)->minutes();

        // Act
        $response = $this->patchJson(
            "/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}",
            ['body' => 'هل وصلت الأكياس من مطبعة النور؟'],
            $mine,
        );

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.body', 'هل وصلت الأكياس من مطبعة النور؟')
            ->assertJsonPath('data.is_edited', true)
            ->assertJsonMissingPath('data.original_body');

        $message->refresh();
        $this->assertSame('هل وصلت الأكياس من المطبعة؟', $message->original_body);
        $this->assertNotNull($message->edited_at);
    }

    public function test_the_first_text_is_kept_through_a_second_edit(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();
        $url = "/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}";

        // Act
        $this->patchJson($url, ['body' => 'الثاني'], $mine)->assertOk();
        $this->patchJson($url, ['body' => 'الثالث'], $mine)->assertOk();

        // Assert
        $message->refresh();
        $this->assertSame('الثالث', $message->body);
        $this->assertSame('هل وصلت الأكياس من المطبعة؟', $message->original_body);
    }

    public function test_sending_the_same_text_is_not_an_edit(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();

        // Act
        $response = $this->patchJson(
            "/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}",
            ['body' => 'هل وصلت الأكياس من المطبعة؟'],
            $mine,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.is_edited', false);
        $this->assertNull($message->refresh()->original_body);
    }

    public function test_after_twenty_one_minutes_the_author_can_no_longer_edit(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();
        $this->travel(21)->minutes();

        // Act
        $edit = $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", ['body' => 'جديد'], $mine);
        $delete = $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", [], $mine);

        // Assert
        $edit->assertForbidden()->assertJsonPath('message', 'مضت 20 دقيقة على إرسال الرسالة');
        $delete->assertForbidden();
    }

    public function test_nobody_edits_a_colleagues_message_not_even_an_admin_who_is_a_party(): void
    {
        // Arrange
        [$admin, $adminHeaders] = $this->admin();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $admin);
        $message = InternalTicketMessage::query()->firstOrFail();

        // Act
        $response = $this->patchJson(
            "/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}",
            ['body' => 'غيّرتها'],
            $adminHeaders,
        );

        // Assert
        $response->assertForbidden()->assertJsonPath('message', 'هذه الرسالة ليست لك');
        $this->assertSame('هل وصلت الأكياس من المطبعة؟', $message->refresh()->body);
    }

    public function test_a_message_in_a_closed_ticket_cannot_change(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $message = InternalTicketMessage::query()->firstOrFail();
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $mine)->assertOk();

        // Act
        $response = $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$message->id}", [], $mine);

        // Assert
        $response->assertForbidden()->assertJsonPath('message', 'التذكرة مغلقة');
    }

    public function test_a_deleted_message_stays_in_place_and_says_so(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->say($ticket, $theirs, ['file' => $this->voice(), 'duration_seconds' => 5])->assertCreated();
        $voice = InternalTicketMessage::query()->latest('id')->firstOrFail();

        // Act
        $response = $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$voice->id}", [], $theirs);
        $thread = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine);

        // Assert
        $response->assertOk()->assertJsonPath('data.is_deleted', true);
        $thread->assertOk()
            ->assertJsonCount(2, 'data.messages')
            ->assertJsonPath('data.messages.1.body', 'تم حذف هذه الرسالة')
            ->assertJsonPath('data.messages.1.is_deleted', true)
            ->assertJsonPath('data.messages.1.attachments', [])
            // المعاينةُ آخرُ كلامٍ حيّ، لا «تم حذف هذه الرسالة».
            ->assertJsonPath('data.last_message.preview', 'هل وصلت الأكياس من المطبعة؟');

        // سحبٌ لا حذف: الصفُّ والملفُّ باقيان للتدقيق.
        $this->assertNull($voice->refresh()->deleted_at);
        Storage::disk((string) config('media.internal_ticket_attachments.disk'))
            ->assertExists(InternalTicketAttachment::query()->sole()->path);
    }

    public function test_a_quote_of_a_deleted_message_says_it_was_deleted(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $first = InternalTicketMessage::query()->firstOrFail();
        $this->say($ticket, $theirs, ['body' => 'نعم', 'reply_to_message_id' => $first->id])->assertCreated();
        $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$first->id}", [], $mine)->assertOk();

        // Act
        $thread = $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $theirs);

        // Assert
        $thread->assertJsonPath('data.messages.1.reply_to.is_deleted', true)
            ->assertJsonPath('data.messages.1.reply_to.preview', 'تم حذف هذه الرسالة');
    }

    public function test_a_message_of_another_ticket_is_not_found_through_this_one(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $other = $this->open($mine, $colleague);
        $foreign = InternalTicketMessage::query()->where('internal_ticket_id', $other->id)->firstOrFail();

        // Act
        $response = $this->patchJson(
            "/api/v1/internal-tickets/{$ticket->id}/messages/{$foreign->id}",
            ['body' => 'x'],
            $mine,
        );

        // Assert
        $response->assertNotFound();
    }

    public function test_the_reply_is_the_last_word_and_resets_the_reminder_count(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        InternalTicket::query()->whereKey($ticket->id)->update(['reminder_count' => 5, 'last_reminder_at' => now()]);

        // Act
        $this->say($ticket, $theirs, ['body' => 'وصلت'])->assertCreated();

        // Assert
        $ticket->refresh();
        $this->assertSame(0, $ticket->reminder_count);
        $this->assertNull($ticket->last_reminder_at);
    }

    public function test_asking_again_while_waiting_does_not_reset_the_reminder_count(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        InternalTicket::query()->whereKey($ticket->id)->update(['reminder_count' => 5]);

        // Act
        $this->say($ticket, $mine, ['body' => '؟'])->assertCreated();

        // Assert
        $this->assertSame(5, $ticket->refresh()->reminder_count);
    }
}
