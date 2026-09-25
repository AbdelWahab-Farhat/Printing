<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Application\Realtime\Events\CustomerTicketChanged;
use App\Application\Realtime\Events\DeskTicketChanged;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Support\Enums\TicketStatus;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Broadcasting\BroadcastException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Exceptions;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * التذاكر حيّة: ما يُبثّ، ولمن، وبأيّ شكل.
 *
 * **ثلاثة أشياء تُحرس هنا.** أن كل تغييرٍ يراه طرفٌ يصله ساعةَ يقع — رسالة، إغلاق، إعادة فتح —
 * وما لا يراه لا يُرسَل إليه (الإسناد والقراءة للمكتب وحده). وأن ما يصل العميلَ هو ما يرسله له
 * الـ API نفسه ولا أكثر: لا اسمَ موظف ولا مكتب. وأن خادمَ بثٍّ نائماً لا يُفشل رداً واحداً.
 *
 * البثُّ يقع بعد إرسال الرد (`defer`)، والاختبار يُنهي الطلب كما يُنهيه الخادم، فتُسجَّل
 * الأحداث قبل أن يصل سطرُ Assert.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class SupportRealtimeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    private function listen(): void
    {
        Event::fake([DeskTicketChanged::class, CustomerTicketChanged::class]);
    }

    private function customer(): Customer
    {
        return Customer::factory()->registered()->create();
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    private function member(PermissionName ...$permissions): User
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return $user;
    }

    /**
     * @return array<string, string>
     */
    private function headersOf(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @return array<string, string>
     */
    private function desk(): array
    {
        return $this->headersOf($this->member(PermissionName::ViewSupportTickets, PermissionName::ManageSupportTickets));
    }

    // ─────────────────────────── ما يُبثّ، ولمن ───────────────────────────

    public function test_a_customer_reply_reaches_the_desk_and_the_customer(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $this->listen();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson(
            "/api/v1/client/support/tickets/{$ticket->id}/messages",
            ['body' => 'هل من جديد؟'],
        );

        // Assert
        $response->assertCreated();
        $message = TicketMessage::query()->latest('id')->firstOrFail();

        Event::assertDispatchedTimes(DeskTicketChanged::class, 1);
        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->is($ticket) && $e->message?->is($message),
        );
        Event::assertDispatched(
            CustomerTicketChanged::class,
            fn (CustomerTicketChanged $e) => $e->ticket->is($ticket) && $e->message?->is($message),
        );
    }

    /**
     * التذكرةُ الجديدة تظهر في طابور المكتب ساعةَ تُفتح، ومعها سؤالُها — لا سطرَ موضوعٍ ينتظر من
     * يفتحه ليعرف ما فيه.
     */
    public function test_opening_a_ticket_is_announced_with_its_first_message(): void
    {
        // Arrange
        $me = $this->customer();
        $this->listen();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/support/tickets', [
            'subject' => 'تأخر في التوصيل',
            'body' => 'الطلبية لم تصل',
        ]);

        // Assert
        $response->assertCreated();

        Event::assertDispatchedTimes(DeskTicketChanged::class, 1);
        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->id === $response->json('data.id')
                && $e->message?->body === 'الطلبية لم تصل',
        );
    }

    public function test_a_staff_reply_reaches_both_sides(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create();
        $this->listen();

        // Act
        $response = $this->withHeaders($this->desk())->postJson(
            "/api/v1/support/tickets/{$ticket->id}/messages",
            ['body' => 'خرجت اليوم مع المندوب'],
        );

        // Assert
        $response->assertCreated();

        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->message?->body === 'خرجت اليوم مع المندوب',
        );
        Event::assertDispatched(
            CustomerTicketChanged::class,
            fn (CustomerTicketChanged $e) => $e->message?->body === 'خرجت اليوم مع المندوب',
        );
    }

    /**
     * على أيّ مكتبٍ تجلس التذكرة ترتيبٌ داخليٌّ للمحل، لا يراه العميل في تطبيقه — فلا يُرسَل إليه.
     */
    public function test_assigning_is_told_to_the_desk_alone(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create();
        $colleague = $this->member();
        $this->listen();

        // Act
        $response = $this->withHeaders($this->desk())->patchJson(
            "/api/v1/support/tickets/{$ticket->id}/assignment",
            ['assigned_to' => $colleague->id],
        );

        // Assert
        $response->assertOk();

        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->assigned_to === $colleague->id && $e->message === null,
        );
        Event::assertNotDispatched(CustomerTicketChanged::class);
    }

    public function test_assigning_to_the_desk_it_already_sits_on_says_nothing(): void
    {
        // Arrange
        $colleague = $this->member();
        $ticket = SupportTicket::factory()->create(['assigned_to' => $colleague->id]);
        $this->listen();

        // Act
        $this->withHeaders($this->desk())->patchJson(
            "/api/v1/support/tickets/{$ticket->id}/assignment",
            ['assigned_to' => $colleague->id],
        )->assertOk();

        // Assert
        Event::assertNotDispatched(DeskTicketChanged::class);
    }

    public function test_closing_reaches_both_sides(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create();
        $this->listen();

        // Act
        $this->withHeaders($this->desk())->postJson("/api/v1/support/tickets/{$ticket->id}/close")->assertOk();

        // Assert
        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->status === TicketStatus::Closed,
        );
        Event::assertDispatched(
            CustomerTicketChanged::class,
            fn (CustomerTicketChanged $e) => $e->ticket->status === TicketStatus::Closed,
        );
    }

    /** إغلاقُ المغلقة لا يكتب شيئاً، فليس عنده ما يقوله. */
    public function test_closing_a_closed_ticket_says_nothing_new(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->closed()->create();
        $this->listen();

        // Act
        $this->withHeaders($this->desk())->postJson("/api/v1/support/tickets/{$ticket->id}/close")->assertOk();

        // Assert
        Event::assertNotDispatched(DeskTicketChanged::class);
        Event::assertNotDispatched(CustomerTicketChanged::class);
    }

    public function test_reopening_reaches_both_sides(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->closed()->create();
        $this->listen();

        // Act
        $this->withHeaders($this->desk())->postJson("/api/v1/support/tickets/{$ticket->id}/reopen")->assertOk();

        // Assert
        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->status->isOpen(),
        );
        Event::assertDispatched(
            CustomerTicketChanged::class,
            fn (CustomerTicketChanged $e) => $e->ticket->status->isOpen(),
        );
    }

    /**
     * **المكتبُ يقرأ بمؤشّرٍ واحد**، فحين يفتح موظفٌ الخيط تنطفئ شارته عند زملائه أيضاً — وإلا
     * بقي الرقم الأحمر في طابورهم حتى يسحبوه للتحديث، وفتحها ثانٍ ليجد ما قرأه الأول.
     */
    /**
     * **والعميل يسمعها أيضاً منذ ٢٠٢٦-٠٩-٢٥**: قراءةُ المكتب هي ✓✓ على رسائله. يصله الحدّ
     * الجديد (`support_read_up_to`) في التذكرة، لا متى قُرئت ولا مَن قرأها.
     */
    public function test_the_desk_hears_when_a_colleague_reads_the_customers_messages(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create();
        $message = TicketMessage::factory()->for($ticket, 'ticket')->fromCustomer($ticket->customer_id)->create();
        $this->listen();

        // Act
        $this->withHeaders($this->desk())->getJson("/api/v1/support/tickets/{$ticket->id}")->assertOk();

        // Assert
        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->is($ticket)
                && $e->message === null
                && $e->ticket->unreadFor(staff: true) === 0,
        );
        Event::assertDispatched(
            CustomerTicketChanged::class,
            fn (CustomerTicketChanged $e) => $e->ticket->is($ticket)
                && $e->message === null
                && ($e->broadcastWith()['ticket']['support_read_up_to'] ?? null) === $message->id
                && ! array_key_exists('staff_read_at', $e->broadcastWith()['ticket']),
        );
    }

    public function test_reading_a_thread_with_nothing_unread_says_nothing(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create();
        $headers = $this->desk();
        $this->withHeaders($headers)->getJson("/api/v1/support/tickets/{$ticket->id}")->assertOk();
        $this->listen();

        // Act
        $this->withHeaders($headers)->getJson("/api/v1/support/tickets/{$ticket->id}")->assertOk();

        // Assert
        Event::assertNotDispatched(DeskTicketChanged::class);
    }

    /** حين يقرأ العميلُ ردودَ المحل يعرف المكتبُ ساعتَها، ولا يُعاد على العميل ما فعله بنفسه. */
    public function test_a_customer_reading_the_shops_replies_is_told_to_the_desk_alone(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        TicketMessage::factory()->for($ticket, 'ticket')->fromStaff($this->member()->id)->create();
        $this->listen();

        // Act
        $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}")->assertOk();

        // Assert
        Event::assertDispatched(
            DeskTicketChanged::class,
            fn (DeskTicketChanged $e) => $e->ticket->is($ticket) && $e->message === null,
        );
        Event::assertNotDispatched(CustomerTicketChanged::class);
    }

    public function test_a_customer_reading_a_thread_with_nothing_unread_says_nothing(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $this->listen();

        // Act
        $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}")->assertOk();

        // Assert
        Event::assertNotDispatched(DeskTicketChanged::class);
        Event::assertNotDispatched(CustomerTicketChanged::class);
    }

    public function test_a_refused_reply_says_nothing(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->closed()->create();
        $this->listen();

        // Act
        $this->withHeaders($this->desk())->postJson(
            "/api/v1/support/tickets/{$ticket->id}/messages",
            ['body' => 'إضافة'],
        )->assertStatus(422);

        // Assert
        Event::assertNotDispatched(DeskTicketChanged::class);
        Event::assertNotDispatched(CustomerTicketChanged::class);
    }

    // ─────────────────────────── ما يحمله ───────────────────────────

    public function test_the_desk_hears_the_desk_view_of_the_ticket(): void
    {
        // Arrange
        $author = User::factory()->create(['name' => 'سالم']);
        $ticket = SupportTicket::factory()->create(['assigned_to' => $author->id]);
        TicketMessage::factory()->for($ticket, 'ticket')->fromCustomer($ticket->customer_id)->create();
        $reply = TicketMessage::factory()->for($ticket, 'ticket')->fromStaff($author->id)->create(['body' => 'تم']);
        $event = new DeskTicketChanged(
            $ticket->fresh(['customer', 'order', 'assignee']),
            $reply->fresh('author'),
        );

        // Act
        $payload = $event->broadcastWith();

        // Assert
        $this->assertSame(['private-support.desk'], array_map('strval', $event->broadcastOn()));
        $this->assertSame('support.ticket.changed', $event->broadcastAs());
        $this->assertSame($ticket->id, $payload['ticket']['id']);
        $this->assertSame($ticket->customer->phone, $payload['ticket']['customer']['phone']);
        $this->assertSame('سالم', $payload['ticket']['assignee']['name']);
        $this->assertSame(1, $payload['ticket']['unread_count']);
        $this->assertArrayNotHasKey('messages', $payload['ticket']);
        $this->assertSame(
            ['id' => $reply->id, 'from' => 'staff', 'author_name' => 'سالم', 'body' => 'تم'],
            array_intersect_key($payload['message'], array_flip(['id', 'from', 'author_name', 'body'])),
        );
    }

    /**
     * **العميلُ يسمع ما يقرؤه في تطبيقه ولا حرفاً أكثر.** اسمُ الموظف الذي ردّ ومكتبُ التذكرة
     * ترتيبٌ داخلي، والـ API لا يرسلهما له — فالمقبس لا يرسلهما أيضاً.
     */
    public function test_the_customer_hears_no_colleagues_name(): void
    {
        // Arrange
        $author = User::factory()->create(['name' => 'سالم']);
        $ticket = SupportTicket::factory()->create(['assigned_to' => $author->id]);
        $reply = TicketMessage::factory()->for($ticket, 'ticket')->fromStaff($author->id)->create(['body' => 'تم']);
        $event = new CustomerTicketChanged(
            SupportTicket::query()->with(['customer', 'order', 'assignee'])->withCount('messages')->findOrFail($ticket->id),
            $reply->fresh('author'),
        );

        // Act
        $payload = $event->broadcastWith();

        // Assert
        $this->assertSame(["private-customers.{$ticket->customer_id}"], array_map('strval', $event->broadcastOn()));
        $this->assertSame('support.ticket.changed', $event->broadcastAs());
        $this->assertSame('support', $payload['message']['from']);
        $this->assertSame(1, $payload['ticket']['unread_count']);
        $this->assertSame(1, $payload['ticket']['messages_count']);
        $this->assertStringNotContainsString('سالم', json_encode($payload, JSON_UNESCAPED_UNICODE) ?: '');
        $this->assertArrayNotHasKey('author_name', $payload['message']);
        $this->assertArrayNotHasKey('assignee', $payload['ticket']);
        $this->assertArrayNotHasKey('assigned_to', $payload['ticket']);
    }

    // ─────────────────────────── ما لا يجوز أن يكسره ───────────────────────────

    /**
     * **Reverb نائم، والردُّ يُكتب ويُجاب ٢٠١ كأن شيئاً لم يكن.** البثُّ زينةٌ فوق محادثةٍ محفوظة:
     * يُسجَّل فشلُه ليراه من يراقب، ولا يُعاد إلى من كتب رسالته خطأً عن شيءٍ لا يملكه.
     */
    public function test_a_sleeping_broadcast_server_never_fails_a_reply(): void
    {
        // Arrange
        config([
            'broadcasting.default' => 'reverb',
            'broadcasting.connections.reverb.key' => 'test-key',
            'broadcasting.connections.reverb.secret' => 'test-secret',
            'broadcasting.connections.reverb.app_id' => 'test-app',
            // لا شيء يسمع على هذا المنفذ: الاتصالُ يُرفض فوراً.
            'broadcasting.connections.reverb.options.host' => '127.0.0.1',
            'broadcasting.connections.reverb.options.port' => 1,
            'broadcasting.connections.reverb.options.scheme' => 'http',
            'broadcasting.connections.reverb.options.useTLS' => false,
        ]);
        Broadcast::forgetDrivers();
        Exceptions::fake();

        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson(
            "/api/v1/client/support/tickets/{$ticket->id}/messages",
            ['body' => 'هل وصل ردّي؟'],
        );

        // Assert
        $response->assertCreated();
        $this->assertDatabaseHas('ticket_messages', ['support_ticket_id' => $ticket->id, 'body' => 'هل وصل ردّي؟']);
        Exceptions::assertReported(BroadcastException::class);
    }
}
