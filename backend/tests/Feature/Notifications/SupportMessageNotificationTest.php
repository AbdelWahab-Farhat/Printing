<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Definitions\CustomerWroteToSupport;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Models\Notification;
use App\Domain\Support\Actions\OpenTicket;
use App\Domain\Support\Actions\PostTicketMessage;
use App\Domain\Support\Models\SupportTicket;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * العميل كتب إلى الدعم، فيصل الخبرُ إلى مَن يستطيع الردّ — جرساً في التطبيق ودفعاً على الهاتف.
 *
 * **كانت التذكرة لا تُعرف إلا والشاشة مفتوحة** (طلب المستخدم، 2026-09-25: «واضف Fcmtokens بما
 * يخص الإشعارات بتذاكر»). الدفعُ نفسه قائمٌ لتطبيق الموظفين (`device_tokens`)، فما كان ناقصاً هو
 * النوعُ وحده.
 *
 * **الجمهورُ مَن على المكتب، أو كلُّ مَن يستطيع الردّ إن لم يكن عليه أحد.** و«يستطيع الردّ» هي
 * `support.manage` لا `support.view`: مَن يقرأ ولا يردّ لا يُوقَظ لأجل رسالةٍ لا يملك جوابها.
 *
 * **ورسائلُ متتالية جرسٌ واحد حتى يقرأها المكتب.** عميلٌ يكتب «السلام عليكم» ثم سؤاله ثم رقم
 * طلبيته في دقيقة لا يستحقّ ثلاثة أجراس على كل هاتف. فإذا قرأ المكتب — أو ردّ — فالرسالةُ التالية
 * خبرٌ جديد.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class SupportMessageNotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    public function test_a_new_ticket_reaches_everyone_who_can_answer_it(): void
    {
        // Arrange — مَن يردّ، ومَن يقرأ فقط، ومَن لا شأن له بالدعم.
        $answerer = $this->staff(PermissionName::ManageSupportTickets, PermissionName::ViewSupportTickets);
        $this->staff(PermissionName::ViewSupportTickets);
        $this->staff(PermissionName::ViewOrders);

        // Act
        $ticket = $this->open();

        // Assert
        $notification = Notification::query()->sole();
        $this->assertSame(NotificationType::SupportCustomerMessage, $notification->type);
        $this->assertSame('support_ticket', $notification->subject_type);
        $this->assertSame((int) $ticket->getKey(), $notification->subject_id);
        $this->assertSame([(int) $answerer->getKey()], $this->recipientsOf($notification));
    }

    public function test_a_ticket_on_a_desk_reaches_the_person_at_that_desk_alone(): void
    {
        // Arrange — تذكرةٌ أخذها موظف، وموظفٌ آخر يستطيع الردّ أيضاً.
        $desk = $this->staff(PermissionName::ManageSupportTickets);
        $this->staff(PermissionName::ManageSupportTickets);
        $ticket = SupportTicket::factory()->inProgress()->create(['assigned_to' => $desk->getKey()]);

        // Act
        $this->customerWrites($ticket);

        // Assert — صاحبُ المكتب وحده: التذكرةُ له، والآخرون لا يُسحبون إليها.
        $this->assertSame([(int) $desk->getKey()], $this->recipientsOf(Notification::query()->sole()));
    }

    public function test_the_shops_own_reply_announces_nothing(): void
    {
        // Arrange
        $desk = $this->staff(PermissionName::ManageSupportTickets);
        $ticket = SupportTicket::factory()->inProgress()->create(['assigned_to' => $desk->getKey()]);

        // Act
        app(PostTicketMessage::class)($ticket, 'تم، سنرسلها غداً', staff: $desk);

        // Assert — ردُّ المحل خبرٌ للعميل لا للمحل.
        $this->assertSame(0, Notification::query()->count());
    }

    public function test_messages_in_a_row_are_one_bell_until_the_desk_reads_them(): void
    {
        // Arrange
        $this->staff(PermissionName::ManageSupportTickets);
        $ticket = $this->open();

        // Act
        $this->customerWrites($ticket, 'عندي سؤال');
        $this->customerWrites($ticket, 'بخصوص المقاس');

        // Assert
        $this->assertSame(1, Notification::query()->count());
    }

    public function test_once_the_desk_has_read_the_next_message_rings_again(): void
    {
        // Arrange
        $desk = $this->staff(PermissionName::ManageSupportTickets, PermissionName::ViewSupportTickets);
        $ticket = $this->open();
        $this->withHeaders($this->bearer($desk))
            ->getJson("/api/v1/support/tickets/{$ticket->getKey()}")
            ->assertOk();

        // Act
        $this->customerWrites($ticket, 'هل وصلت رسالتي؟');

        // Assert
        $this->assertSame(2, Notification::query()->count());
    }

    public function test_opening_the_ticket_clears_its_bell(): void
    {
        // Arrange
        $desk = $this->staff(PermissionName::ManageSupportTickets, PermissionName::ViewSupportTickets);
        $ticket = $this->open();

        // Act
        $this->withHeaders($this->bearer($desk))
            ->getJson("/api/v1/support/tickets/{$ticket->getKey()}")
            ->assertOk();

        // Assert — مَن قرأ المحادثة في مكانها قرأها، فلا يبقى في الجرس رقمٌ يكذب.
        $this->assertNotNull(Notification::query()->sole()->recipients()->sole()->read_at);
    }

    public function test_the_sentence_names_the_customer_and_the_subject_but_never_the_message(): void
    {
        // Arrange — الدفعُ يُقرأ على شاشةٍ مقفلة.
        $this->staff(PermissionName::ManageSupportTickets);
        $ticket = $this->open(subject: 'استفسار عن طلبية', body: 'رقم حسابي 4455');
        $customer = Customer::query()->findOrFail($ticket->customer_id);

        // Act
        $notification = Notification::query()->sole();
        $rendered = app(CustomerWroteToSupport::class)->render($notification->payload);

        // Assert
        $this->assertSame('تذكرة دعم جديدة', $rendered->title);
        $this->assertStringContainsString('استفسار عن طلبية', $rendered->body);
        $this->assertStringContainsString((string) $customer->name, $rendered->body);
        $this->assertSame('/support/tickets/'.$ticket->getKey(), $rendered->route);
        $this->assertStringNotContainsString('4455', $rendered->title.' '.$rendered->body);
        $this->assertArrayNotHasKey('body', $notification->payload);
    }

    public function test_a_later_message_reads_as_a_message_not_as_a_new_ticket(): void
    {
        // Arrange — المكتبُ قرأ السطرَ الأول، فالتالي يرنّ.
        $desk = $this->staff(PermissionName::ManageSupportTickets, PermissionName::ViewSupportTickets);
        $ticket = $this->open();
        $this->withHeaders($this->bearer($desk))
            ->getJson("/api/v1/support/tickets/{$ticket->getKey()}")
            ->assertOk();
        $this->customerWrites($ticket, 'هل من جديد؟');

        // Act
        $latest = Notification::query()->latest('id')->firstOrFail();
        $rendered = app(CustomerWroteToSupport::class)->render($latest->payload);

        // Assert
        $this->assertSame('رسالة جديدة من العميل', $rendered->title);
    }

    public function test_the_app_endpoint_carries_a_new_ticket_all_the_way_to_the_desk(): void
    {
        // Arrange — الطريقُ كاملاً: المتحكّم ← الفعل ← الحدث ← المستمِع.
        $answerer = $this->staff(PermissionName::ManageSupportTickets);
        $customer = Customer::factory()->registered()->create(['phone' => '0911111111']);

        // Act
        $response = $this->withHeaders([
            'Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken,
        ])->postJson('/api/v1/client/support/tickets', [
            'subject' => 'استفسار',
            'body' => 'السلام عليكم',
        ]);

        // Assert
        $response->assertCreated();
        $this->assertSame([(int) $answerer->getKey()], $this->recipientsOf(Notification::query()->sole()));
    }

    private function staff(PermissionName ...$permissions): User
    {
        $user = User::factory()->create(['is_active' => true]);
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return $user;
    }

    /**
     * @return array<string, string>
     */
    private function bearer(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * تذكرةٌ يفتحها العميل كما يفتحها من التطبيق: الموضوعُ وأولى الرسائل معاً.
     */
    private function open(string $subject = 'استفسار عن طلبية', string $body = 'السلام عليكم'): SupportTicket
    {
        return app(OpenTicket::class)(Customer::factory()->create(), $subject, $body);
    }

    private function customerWrites(SupportTicket $ticket, string $body = 'ممكن ردّ؟'): void
    {
        $ticket->refresh();

        app(PostTicketMessage::class)(
            $ticket,
            $body,
            customer: Customer::query()->findOrFail($ticket->customer_id),
        );
    }

    /**
     * @return list<int>
     */
    private function recipientsOf(Notification $notification): array
    {
        return $notification->recipients()
            ->pluck('user_id')
            ->map(fn ($id) => (int) $id)
            ->all();
    }
}
