<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Notification\Models\NotificationRecipient;
use Illuminate\Testing\TestResponse;

/**
 * علامةُ القراءة بجانب «رد» في بطاقة الرئيسية (طلبُ المالك ٢٠٢٦-١٠-٢٥): «قرأتُها ولا ردّ عندي».
 * تُخرج التذكرةَ من بطاقتي حتى يكتب زميلي من جديد، وتُسكت تذكيرَ الصباح، ولا تمسّ القائمة.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketReadMarkTest extends InternalTicketTestCase
{
    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    private function markSeen(InternalTicket $ticket, array $headers, array $payload = []): TestResponse
    {
        return $this->postJson("/api/v1/internal-tickets/{$ticket->id}/seen", $payload, $headers);
    }

    /**
     * @param  array<string, string>  $headers
     * @return list<int>
     */
    private function homeIds(array $headers): array
    {
        return array_map('intval', array_column($this->getJson('/api/v1/internal-tickets/home', $headers)->json('data.tickets'), 'id'));
    }

    public function test_the_read_mark_takes_the_ticket_off_my_home_card(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);

        // Act
        $response = $this->markSeen($ticket, $mine);

        // Assert
        $response->assertOk();
        $home = $this->getJson('/api/v1/internal-tickets/home', $mine);
        $home->assertJsonPath('data.awaiting_my_reply', 0)
            ->assertJsonPath('data.total_open', 1)
            ->assertJsonCount(0, 'data.tickets');
    }

    public function test_a_new_message_from_the_colleague_brings_it_back(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->markSeen($ticket, $mine)->assertOk();

        // Act
        $this->say($ticket, $theirs, ['body' => 'وصلتك؟'])->assertCreated();

        // Assert
        $this->assertSame([$ticket->id], $this->homeIds($mine));
    }

    public function test_it_stops_at_the_message_that_was_on_screen(): void
    {
        // Arrange — وصلت رسالةٌ ثانية بعد أن رُسمت البطاقة وقبل الضغط.
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $first = (int) InternalTicketMessage::query()->value('id');
        $this->say($ticket, $theirs, ['body' => 'وأمرٌ آخر'])->assertCreated();

        // Act
        $this->markSeen($ticket, $mine, ['up_to_message_id' => $first])->assertOk();

        // Assert
        $this->assertSame([$ticket->id], $this->homeIds($mine));
    }

    public function test_it_never_goes_back(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->say($ticket, $theirs, ['body' => 'ثانية'])->assertCreated();
        [$first, $second] = InternalTicketMessage::query()->orderBy('id')->pluck('id')->all();

        // Act
        $this->markSeen($ticket, $mine, ['up_to_message_id' => $second])->assertOk();
        $this->markSeen($ticket, $mine, ['up_to_message_id' => $first])->assertOk();

        // Assert
        $this->assertSame((int) $second, $ticket->refresh()->assignee_seen_message_id);
        $this->assertSame([], $this->homeIds($mine));
    }

    public function test_a_number_past_the_thread_cannot_hide_what_comes_next(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->markSeen($ticket, $mine, ['up_to_message_id' => 999_999])->assertOk();

        // Act
        $this->say($ticket, $theirs, ['body' => 'جديد'])->assertCreated();

        // Assert
        $this->assertSame([$ticket->id], $this->homeIds($mine));
    }

    public function test_it_reads_the_thread_too_so_my_colleague_sees_the_double_tick(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $first = (int) InternalTicketMessage::query()->value('id');

        // Act
        $this->markSeen($ticket, $mine)->assertOk();

        // Assert
        $this->assertSame($first, $ticket->refresh()->assignee_read_message_id);
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $theirs)
            ->assertJsonPath('data.counterpart_read_up_to', $first);
    }

    public function test_it_silences_the_bells_of_that_ticket_for_me(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);

        // Act
        $this->markSeen($ticket, $mine)->assertOk();

        // Assert
        $unread = NotificationRecipient::query()->where('user_id', $me->id)->whereNull('read_at')->count();
        $this->assertSame(0, $unread);
    }

    public function test_the_list_page_still_shows_it_waiting_on_me(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->markSeen($ticket, $mine)->assertOk();

        // Act
        $response = $this->getJson('/api/v1/internal-tickets', $mine);

        // Assert
        $response->assertJsonPath('data.0.id', $ticket->id)->assertJsonPath('data.0.awaiting_my_reply', true);
    }

    public function test_the_morning_reminder_stays_quiet_until_the_colleague_writes_again(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->markSeen($ticket, $mine)->assertOk();
        $this->travel(2)->hours();
        $this->artisan('internal-tickets:remind')->assertSuccessful();
        $quiet = Notification::query()->where('type', NotificationType::InternalTicketReminder)->count();

        // Act
        $this->say($ticket, $theirs, ['body' => 'ما زلت أنتظر'])->assertCreated();
        $this->travel(2)->hours();
        $this->artisan('internal-tickets:remind')->assertSuccessful();

        // Assert
        $this->assertSame(0, $quiet);
        $this->assertSame(1, Notification::query()->where('type', NotificationType::InternalTicketReminder)->count());
    }

    public function test_the_new_owner_of_a_transferred_ticket_starts_with_it_on_the_card(): void
    {
        // Arrange — فتحتُها، وردّ زميلي، فعلّمتُها مقروءة ثم سلّمتها لغيري.
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        [$heir, $heirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->say($ticket, $theirs, ['body' => 'جاهز'])->assertCreated();
        $this->markSeen($ticket, $mine)->assertOk();

        // Act
        $this->patchJson("/api/v1/internal-tickets/{$ticket->id}/transfer", ['new_owner_id' => $heir->id], $mine)->assertOk();

        // Assert
        $this->assertSame([$ticket->id], $this->homeIds($heirs));
    }

    public function test_only_its_two_parties_mark_it(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        [, $outsider] = $this->employee();
        [, $admin] = $this->admin();
        $ticket = $this->open($mine, $colleague);

        // Act
        $byAdmin = $this->markSeen($ticket, $admin);
        $byOutsider = $this->markSeen($ticket, $outsider);

        // Assert
        $byAdmin->assertForbidden();
        $byOutsider->assertNotFound();
        $this->assertNull($ticket->refresh()->opener_seen_message_id);
    }

    public function test_the_number_must_be_a_message_number(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);

        // Act
        $response = $this->markSeen($ticket, $mine, ['up_to_message_id' => 0]);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['up_to_message_id']);
    }
}
