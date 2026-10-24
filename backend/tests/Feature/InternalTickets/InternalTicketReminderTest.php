<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use Carbon\CarbonImmutable;
use Illuminate\Console\Scheduling\Schedule;

/**
 * التذكير مرّةً في اليوم لمن يُنتظر ردّه — الساعة التاسعة بتوقيت طرابلس، لمن مرّت عليه ساعةٌ بلا ردّ،
 * و٢٤ مرة على الأكثر.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class InternalTicketReminderTest extends InternalTicketTestCase
{
    private function remind(): void
    {
        $this->artisan('internal-tickets:remind')->assertSuccessful();
    }

    /**
     * @return list<int>
     */
    private function remindedUserIds(): array
    {
        return Notification::query()
            ->where('type', NotificationType::InternalTicketReminder)
            ->with('recipients')
            ->get()
            ->flatMap(fn (Notification $n) => $n->recipients->pluck('user_id'))
            ->map(fn ($id) => (int) $id)
            ->all();
    }

    public function test_nothing_is_due_before_an_hour(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $this->open($mine, $colleague);
        $this->travel(50)->minutes();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([], $this->remindedUserIds());
    }

    public function test_after_an_hour_the_colleague_who_owes_an_answer_is_reminded(): void
    {
        // Arrange
        [$me, $mine] = $this->employee('سالم');
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague, ['title' => 'المخزن']);
        $this->travel(61)->minutes();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([$colleague->id], $this->remindedUserIds());
        $notification = Notification::query()->where('type', NotificationType::InternalTicketReminder)->sole();
        $this->assertSame('سالم ينتظر ردّك', $this->rendered($notification)->title);
        $this->assertSame('المخزن', $this->rendered($notification)->body);
        $this->assertSame(1, $ticket->refresh()->reminder_count);
        $this->assertNotSame($me->id, $colleague->id);
    }

    public function test_the_opener_is_reminded_when_the_colleague_spoke_last(): void
    {
        // Arrange
        [$me, $mine] = $this->employee();
        [$colleague, $theirs] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->say($ticket, $theirs, ['body' => 'أحتاج رقم الطلبية'])->assertCreated();
        $this->travel(61)->minutes();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([$me->id], $this->remindedUserIds());
    }

    public function test_it_reminds_once_a_day_not_every_hour(): void
    {
        // Arrange — أوقاتٌ ثابتة بتوقيت طرابلس، فلا يعبر منتصفُ الليل بين النداءين صدفةً.
        $this->travelTo(CarbonImmutable::parse('2026-10-24 08:00', 'Africa/Tripoli'));
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travelTo(CarbonImmutable::parse('2026-10-24 09:00', 'Africa/Tripoli'));
        $this->remind();

        // Act
        $this->travelTo(CarbonImmutable::parse('2026-10-24 15:00', 'Africa/Tripoli'));
        $this->remind();
        $sameDay = $ticket->refresh()->reminder_count;
        $this->travelTo(CarbonImmutable::parse('2026-10-25 09:00', 'Africa/Tripoli'));
        $this->remind();

        // Assert
        $this->assertSame(1, $sameDay);
        $this->assertSame(2, $ticket->refresh()->reminder_count);
    }

    public function test_the_day_is_tripolis_not_utcs(): void
    {
        // Arrange — ٠١:٠٠ و٢٣:٠٠ يومٌ واحد في طرابلس، ويومان في UTC (٢٣:٠٠ أمس و٢١:٠٠ اليوم).
        $this->travelTo(CarbonImmutable::parse('2026-10-23 23:00', 'Africa/Tripoli'));
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->travelTo(CarbonImmutable::parse('2026-10-24 01:00', 'Africa/Tripoli'));
        $this->remind();

        // Act
        $this->travelTo(CarbonImmutable::parse('2026-10-24 23:00', 'Africa/Tripoli'));
        $this->remind();

        // Assert
        $this->assertSame(1, $ticket->refresh()->reminder_count);
    }

    public function test_it_stops_after_twenty_four(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        InternalTicket::query()->whereKey($ticket->id)->update(['reminder_count' => 24]);
        $this->travel(3)->hours();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([], $this->remindedUserIds());
    }

    public function test_a_closed_ticket_reminds_nobody(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $ticket = $this->open($mine, $colleague);
        $this->postJson("/api/v1/internal-tickets/{$ticket->id}/close", [], $mine)->assertOk();
        $this->travel(2)->hours();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([], $this->remindedUserIds());
    }

    public function test_a_deactivated_colleague_is_not_reminded(): void
    {
        // Arrange
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $this->open($mine, $colleague);
        $colleague->forceFill(['is_active' => false])->save();
        $this->travel(2)->hours();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([], $this->remindedUserIds());
    }

    public function test_max_zero_turns_reminders_off(): void
    {
        // Arrange
        config(['internal_tickets.reminder.max' => 0]);
        [, $mine] = $this->employee();
        [$colleague] = $this->employee();
        $this->open($mine, $colleague);
        $this->travel(2)->hours();

        // Act
        $this->remind();

        // Assert
        $this->assertSame([], $this->remindedUserIds());
    }

    public function test_it_runs_daily_at_nine_tripoli_time_without_overlapping_itself(): void
    {
        // Arrange — الجدولُ يُبنى حين يبدأ Artisan، فيُقرأ بعد أن يبدأ لا قبله.
        $this->artisan('schedule:list')->assertSuccessful();

        // Act
        $events = array_values(array_filter(
            app(Schedule::class)->events(),
            fn ($event): bool => str_contains((string) $event->command, 'internal-tickets:remind'),
        ));

        // Assert
        $this->assertCount(1, $events);
        $this->assertSame('0 9 * * *', $events[0]->expression);
        $this->assertSame('Africa/Tripoli', $events[0]->timezone);
        $this->assertTrue($events[0]->withoutOverlapping);
    }
}
