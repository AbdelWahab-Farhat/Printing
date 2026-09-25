<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Support\Actions\MarkTicketRead;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * علامةُ القراءة — ✓ أُرسلت، ✓✓ قرأها الطرف الآخر.
 *
 * **المؤشّر رقمُ آخر رسالةٍ رآها القارئ، لا ساعةُ قراءته.** الأعمدة الزمنية في هذا الجدول
 * بدقّة الثانية، فرسالةٌ تصل في الثانية نفسها التي فُتح فيها الخيط كانت ستُعدّ مقروءة وهي لم
 * تُعرض على أحد — ✓✓ كاذبة، وشارةُ ردٍّ جديد لا تظهر. والرقم لا يتساوى فيه اثنان: القارئ رأى
 * كل رسالة رقمها حتى المؤشّر، ولم يرَ ما بعده.
 *
 * **والمؤشّر لا يرجع إلى الوراء.** قراءةٌ بطيئة حملت رسائل أقل تصل بعد قراءةٍ أحدث، فلا تمحو ما
 * قُرئ.
 *
 * **والعميل يرى أن المحل قرأ، ولا يرى متى.** الحدّ وحده يُرسل (`support_read_up_to`)، والساعة
 * (`staff_read_at`) لا تغادر الخادم.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class SupportReadMarkTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
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

    /**
     * @return array<string, string>
     */
    private function desk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewSupportTickets->value,
            PermissionName::ManageSupportTickets->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function say(Customer $customer, SupportTicket $ticket, string $body): int
    {
        return (int) $this->withHeaders($this->bearerFor($customer))
            ->postJson("/api/v1/client/support/tickets/{$ticket->id}/messages", ['body' => $body])
            ->assertCreated()
            ->json('data.messages.'.($ticket->messages()->count() - 1).'.id');
    }

    // ─────────────────────────── ما يراه العميل ───────────────────────────

    public function test_a_message_the_shop_has_not_opened_is_not_read(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/support/tickets', [
            'subject' => 'سؤال',
            'body' => 'متى تفتحون؟',
        ]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.support_read_up_to', null);
    }

    public function test_the_shop_opening_the_thread_marks_my_messages_read(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $mine = $this->say($me, $ticket, 'الطلبية لم تصل');

        // Act
        $this->withHeaders($this->desk())->getJson("/api/v1/support/tickets/{$ticket->id}")->assertOk();
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.support_read_up_to', $mine);
    }

    /**
     * **الحالة التي من أجلها المؤشّر رقم.** بمؤشّرٍ زمني بدقّة الثانية كانت هذه الرسالة تُعدّ
     * مقروءة: كُتبت في الثانية نفسها التي فتح فيها الموظف الخيط، ولم تكن على شاشته.
     */
    public function test_a_message_written_in_the_same_second_the_shop_read_stays_unread(): void
    {
        // Arrange
        $this->freezeSecond();
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $seen = $this->say($me, $ticket, 'الأولى');
        $this->withHeaders($this->desk())->getJson("/api/v1/support/tickets/{$ticket->id}")->assertOk();

        // Act
        $unseen = $this->say($me, $ticket, 'الثانية، في الثانية نفسها');
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.support_read_up_to', $seen);
        $this->assertLessThan($unseen, $seen);
    }

    /** مَن ردّ فقد قرأ ما قبل ردّه — كما في كل تطبيق محادثة. */
    public function test_a_shop_reply_marks_what_came_before_it_read(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $mine = $this->say($me, $ticket, 'هل من جديد؟');

        // Act
        $this->withHeaders($this->desk())
            ->postJson("/api/v1/support/tickets/{$ticket->id}/messages", ['body' => 'نعم، خرجت اليوم'])
            ->assertCreated();
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}");

        // Assert
        $this->assertGreaterThanOrEqual($mine, $response->assertOk()->json('data.support_read_up_to'));
    }

    /** الحدّ يُرسل، والساعة لا. */
    public function test_the_customer_is_never_told_when_the_shop_read(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $this->say($me, $ticket, 'سؤال');
        $this->withHeaders($this->desk())->getJson("/api/v1/support/tickets/{$ticket->id}")->assertOk();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}");

        // Assert
        $response->assertOk()
            ->assertJsonMissingPath('data.staff_read_at')
            ->assertJsonMissingPath('data.staff_read_message_id');
    }

    // ─────────────────────────── ما يراه المكتب ───────────────────────────

    public function test_the_desk_sees_when_the_customer_has_read_its_reply(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $reply = (int) $this->withHeaders($this->desk())
            ->postJson("/api/v1/support/tickets/{$ticket->id}/messages", ['body' => 'جاهزة للاستلام'])
            ->assertCreated()
            ->json('data.messages.0.id');

        // Act
        $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}")->assertOk();
        $response = $this->withHeaders($this->desk())->getJson("/api/v1/support/tickets/{$ticket->id}");

        // Assert
        $response->assertOk()->assertJsonPath('data.customer_read_up_to', $reply);
    }

    // ─────────────────────────── المؤشّر نفسه ───────────────────────────

    public function test_a_read_never_moves_the_mark_backwards(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create();
        $older = TicketMessage::factory()->fromCustomer($ticket->customer_id)->create(['support_ticket_id' => $ticket->id]);
        $newer = TicketMessage::factory()->fromCustomer($ticket->customer_id)->create(['support_ticket_id' => $ticket->id]);
        app(MarkTicketRead::class)($ticket, staff: true, upToMessageId: $newer->id);

        // Act — قراءةٌ أبطأ حملت الخيط قبل أن تصل الرسالة الأحدث.
        app(MarkTicketRead::class)($ticket->refresh(), staff: true, upToMessageId: $older->id);

        // Assert
        $this->assertSame($newer->id, $ticket->refresh()->staff_read_message_id);
    }

    /**
     * **وشارةُ الردّ الجديد تُحسب بالمؤشّر نفسه.** بمؤشّرٍ زمني كان ردٌّ يصل في ثانية القراءة
     * يضيع: لا يُعدّ غير مقروء، فلا شارة ولا «ردّ جديد»، والعميل لا يعلم أن أحداً أجابه.
     */
    public function test_a_reply_in_the_same_second_as_my_read_still_counts_as_new(): void
    {
        // Arrange
        $this->freezeSecond();
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $headers = $this->desk();
        $this->withHeaders($headers)
            ->postJson("/api/v1/support/tickets/{$ticket->id}/messages", ['body' => 'الأول'])->assertCreated();
        $this->withHeaders($this->bearerFor($me))->getJson("/api/v1/client/support/tickets/{$ticket->id}")->assertOk();

        // Act
        $this->withHeaders($headers)
            ->postJson("/api/v1/support/tickets/{$ticket->id}/messages", ['body' => 'الثاني'])->assertCreated();
        $list = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/support/tickets');
        $badges = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/badges');

        // Assert
        $list->assertOk()->assertJsonPath('data.0.unread_count', 1);
        $badges->assertOk()->assertJsonPath('data.support', 1);
    }
}
