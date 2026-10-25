<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\Audit\Models\ActivityLog;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Http\Request;

/**
 * ثلاثةُ أيامٍ بلا كلامٍ من أيٍّ من الطرفين تُغلق التذكرة (طلبُ المالك ٢٠٢٦-١٠-٢٥)، ويصل الخبرُ إلى
 * الطرفين. الرسالةُ وحدها تعيد العدّ — علامةُ القراءة لا. والقديمةُ الصامتة تُغلق أوّلَ مرة.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketSilenceCloseTest extends InternalTicketTestCase
{
    private function sweep(): void
    {
        // المجدوِلُ عمليةٌ بلا طلبٍ ولا مستخدم؛ والاختبارُ يحمل آخرَ طلبٍ ورمزَه، فيقرأ منه Sanctum مَن
        // سجّل دخوله — يُنسيان معاً، كما في الخادم.
        $this->app->instance('request', Request::create('/'));
        $this->app['auth']->forgetGuards();

        $this->artisan('internal-tickets:close-silent')->assertSuccessful();
    }

    public function test_three_days_without_a_word_close_the_ticket_with_nobodys_name_on_it(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(3)->days();
        $this->travel(1)->minute();

        // Act
        $this->sweep();

        // Assert
        $ticket->refresh();
        $this->assertSame(InternalTicketStatus::Closed, $ticket->status);
        $this->assertNull($ticket->closed_by);
        $this->assertNotNull($ticket->closed_at);
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine)
            ->assertJsonPath('data.status', 'closed')
            ->assertJsonPath('data.closed_by', null)
            ->assertJsonPath('data.closed_for_silence', true);
    }

    public function test_just_under_three_days_stays_open(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(3)->days();
        $this->travel(-1)->minute();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(InternalTicketStatus::InProgress, $ticket->refresh()->status);
    }

    public function test_a_message_from_either_side_starts_the_three_days_again(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(2)->days();
        $this->say($ticket, $theirs, ['body' => 'أعمل عليها'])->assertCreated();
        $this->travel(2)->days();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(InternalTicketStatus::InProgress, $ticket->refresh()->status);
    }

    public function test_the_read_mark_does_not_start_the_three_days_again(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [, $theirs] = $this->employee();
        $ticket = $this->open($theirs, $me);
        $this->travel(2)->days();
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/seen", [], $mine)->assertOk();
        $this->travel(1)->day();
        $this->travel(1)->minute();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(InternalTicketStatus::Closed, $ticket->refresh()->status);
    }

    public function test_a_withdrawn_message_is_not_a_reply(): void
    {
        // Arrange — قال زميلي كلمةً ثم سحبها: آخرُ كلامٍ حيٍّ هو فتحُ التذكرة.
        [, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(2)->days();
        $said = $this->say($ticket, $theirs, ['body' => 'خطأ'])->assertCreated();
        $messageId = (int) collect($said->json('data.messages'))->last()['id'];
        $this->deleteJson("/api/v1/internal-tickets/{$ticket->id}/messages/{$messageId}", [], $theirs)->assertOk();
        $this->travel(1)->day();
        $this->travel(1)->minute();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(InternalTicketStatus::Closed, $ticket->refresh()->status);
    }

    public function test_both_parties_hear_that_it_closed(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague, ['title' => 'فاتورة المطبعة']);
        $this->travel(4)->days();

        // Act
        $this->sweep();

        // Assert
        $notification = Notification::query()->where('type', NotificationType::InternalTicketClosedForSilence)->sole();
        $recipients = $notification->recipients()->pluck('user_id')->map(fn ($id) => (int) $id)->sort()->values()->all();
        $this->assertSame(collect([$me->id, $colleague->id])->sort()->values()->all(), $recipients);
        $this->assertSame('أُغلقت التذكرة لعدم الردّ', $this->rendered($notification)->title);
        $this->assertSame('فاتورة المطبعة', $this->rendered($notification)->body);
        $this->assertSame("/internal-tickets/{$ticket->id}", $this->rendered($notification)->route);
    }

    public function test_a_second_sweep_closes_nothing_and_rings_nobody(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(4)->days();
        $this->sweep();
        $closedAt = $ticket->refresh()->closed_at;
        $this->travel(1)->hour();

        // Act
        $this->sweep();

        // Assert
        $this->assertEquals($closedAt, $ticket->refresh()->closed_at);
        $this->assertSame(1, Notification::query()->where('type', NotificationType::InternalTicketClosedForSilence)->count());
    }

    public function test_a_ticket_someone_closed_keeps_their_name(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $mine)->assertOk();
        $this->travel(5)->days();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame($me->id, $ticket->refresh()->closed_by);
        $this->getJson("/api/v1/internal-tickets/{$ticket->id}", $mine)->assertJsonPath('data.closed_for_silence', false);
        $this->assertSame(0, Notification::query()->where('type', NotificationType::InternalTicketClosedForSilence)->count());
    }

    public function test_old_silent_tickets_close_on_the_first_sweep(): void
    {
        // Arrange — تذاكرُ صامتةٌ منذ أسابيع قبل النشر تُغلق في أوّل ساعةٍ بعده.
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $old = $this->open($mine, $colleague, ['title' => 'قديمة']);
        $this->travel(20)->days();
        $fresh = $this->open($mine, $colleague, ['title' => 'جديدة']);

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(InternalTicketStatus::Closed, $old->refresh()->status);
        $this->assertSame(InternalTicketStatus::InProgress, $fresh->refresh()->status);
    }

    public function test_zero_days_turns_it_off(): void
    {
        // Arrange
        config(['internal_tickets.close_after_silence.days' => 0]);
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(30)->days();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(InternalTicketStatus::InProgress, $ticket->refresh()->status);
    }

    public function test_the_closing_is_in_the_tickets_history_with_no_one_behind_it(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travel(4)->days();

        // Act
        $this->sweep();

        // Assert
        $entry = ActivityLog::query()
            ->where('subject_type', $ticket->getMorphClass())
            ->where('subject_id', $ticket->id)
            ->orderByDesc('id')
            ->firstOrFail();
        $this->assertSame('updated', $entry->event);
        $this->assertNull($entry->causer_id);
        $this->assertSame('closed', $entry->attribute_changes?->get('attributes')['status'] ?? null);
    }

    public function test_it_runs_every_hour_without_overlapping_itself(): void
    {
        // Arrange — الجدولُ يُبنى حين يبدأ Artisan، فيُقرأ بعد أن يبدأ لا قبله.
        $this->artisan('schedule:list')->assertSuccessful();

        // Act
        $events = array_values(array_filter(
            app(Schedule::class)->events(),
            fn ($event): bool => str_contains((string) $event->command, 'internal-tickets:close-silent'),
        ));

        // Assert
        $this->assertCount(1, $events);
        $this->assertSame('0 * * * *', $events[0]->expression);
        $this->assertTrue($events[0]->withoutOverlapping);
    }

    public function test_it_reaches_every_silent_ticket_not_every_other_one(): void
    {
        // Arrange — إغلاقُ صفٍّ يُخرجه من الاستعلام؛ التصفّحُ بالإزاحة كان سيقفز فوق نصفها.
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        foreach (range(1, 5) as $i) {
            $this->open($mine, $colleague, ['title' => "صامتة {$i}"]);
        }
        $this->travel(4)->days();

        // Act
        $this->sweep();

        // Assert
        $this->assertSame(0, InternalTicket::query()->where('status', InternalTicketStatus::InProgress)->count());
    }
}
