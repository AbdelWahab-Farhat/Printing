<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\DevicePlatform;
use App\Domain\Notification\Jobs\DeliverCustomerPush;
use App\Domain\Notification\Listeners\NotifyCustomerWhenSupportReplies;
use App\Domain\Notification\Models\CustomerDeviceToken;
use App\Domain\Support\Actions\CloseTicket;
use App\Domain\Support\Actions\MarkTicketRead;
use App\Domain\Support\Actions\OpenTicket;
use App\Domain\Support\Actions\PostTicketMessage;
use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Models\SupportTicket;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

/**
 * ردَّ المحلُّ في الدعم، فيصل الخبرُ إلى هاتف العميل.
 *
 * **ردودٌ متتالية دفعةٌ واحدة حتى يقرأ العميل** — الوجهُ الآخر لقاعدة الجرس عند الموظفين: موظفٌ
 * يكتب «أهلاً» ثم الجواب ثم رقمَ الطلبية في دقيقة لا يوقظ العميل ثلاث مرات. فإذا قرأ العميل الخيطَ
 * فالردُّ التالي خبرٌ جديد.
 *
 * **والنصُّ موضوعُ التذكرة لا نصُّ الرسالة**: الدفعُ يُقرأ على شاشةٍ مقفلة.
 *
 * يمرّ كلُّ اختبارٍ بالأفعال الحقيقية — `OpenTicket` و`PostTicketMessage` — فالمستمِع يُستدعى من
 * الحدث المسجَّل لا باليد. والمهمّة وحدها مزيّفة في الطابور.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class CustomerSupportPushTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('services.fcm.project_id', 'test-project');
        config()->set('services.fcm.credentials', '/dev/null');

        Queue::fake([DeliverCustomerPush::class]);
    }

    private function customerWithADevice(?Customer $customer = null): Customer
    {
        $customer ??= Customer::factory()->create();

        $device = new CustomerDeviceToken;
        $device->customer_id = (int) $customer->getKey();
        $device->token = 'token-'.uniqid();
        $device->platform = DevicePlatform::Ios;
        $device->save();

        return $customer;
    }

    private function open(Customer $customer, string $subject = 'استفسار عن المقاس'): SupportTicket
    {
        return app(OpenTicket::class)($customer, $subject, 'السلام عليكم');
    }

    private function staffReplies(SupportTicket $ticket, string $body = 'أهلاً، كيف نساعدك؟', ?User $staff = null): void
    {
        app(PostTicketMessage::class)(
            $ticket->refresh(),
            $body,
            staff: $staff ?? User::factory()->create(['is_active' => true]),
        );
    }

    private function customerWrites(SupportTicket $ticket, Customer $customer, string $body = 'شكراً'): void
    {
        app(PostTicketMessage::class)($ticket->refresh(), $body, customer: $customer);
    }

    public function test_a_staff_reply_is_pushed_to_the_customer(): void
    {
        // Arrange
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer, 'استفسار عن المقاس');

        // Act
        $this->staffReplies($ticket);

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 1);
        Queue::assertPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => $job->title === 'ردٌّ من الدعم'
            && $job->body === 'استفسار عن المقاس'
            && $job->route === '/support/'.$ticket->getKey());
    }

    public function test_the_push_never_carries_the_reply_itself(): void
    {
        // Arrange — الشاشةُ المقفلة يقرؤها مَن يحمل الهاتف.
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer, 'استفسار');

        // Act
        $this->staffReplies($ticket, 'رصيدك عندنا 450 دينار');

        // Assert
        Queue::assertNotPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => str_contains($job->title.$job->body, '450'));
        Queue::assertPushed(DeliverCustomerPush::class, 1);
    }

    public function test_the_customers_own_message_is_not_pushed_back_to_them(): void
    {
        // Arrange
        $customer = $this->customerWithADevice();

        // Act — فتحُ التذكرة نفسه رسالةٌ من العميل، ثم رسالةٌ ثانية منه.
        $ticket = $this->open($customer);
        $this->customerWrites($ticket, $customer);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_replies_in_a_row_are_one_push_until_the_customer_reads(): void
    {
        // Arrange
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);

        // Act
        $this->staffReplies($ticket, 'أهلاً');
        $this->staffReplies($ticket, 'المقاس المتوفر 25*35');
        $this->staffReplies($ticket, 'وهذا رقم طلبيتك');

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 1);
    }

    public function test_once_the_customer_has_read_the_next_reply_is_pushed_again(): void
    {
        // Arrange
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);
        $this->staffReplies($ticket, 'أهلاً');
        app(MarkTicketRead::class)($ticket->refresh(), staff: false);

        // Act
        $this->staffReplies($ticket, 'هل وصلتك الصورة؟');

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 2);
    }

    public function test_opening_the_thread_in_the_app_counts_as_reading(): void
    {
        // Arrange — الطريقُ الحقيقي: التطبيق يفتح الخيط، وفتحُه هو ما يعلّمه مقروءاً.
        $customer = $this->customerWithADevice(Customer::factory()->registered()->create(['phone' => '0911111111']));
        $ticket = $this->open($customer);
        $this->staffReplies($ticket, 'أهلاً');
        $this->withHeaders(['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken])
            ->getJson("/api/v1/client/support/tickets/{$ticket->getKey()}")
            ->assertOk();

        // Act
        $this->staffReplies($ticket, 'تفضّل');

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 2);
    }

    public function test_the_customer_replying_counts_as_reading(): void
    {
        // Arrange — مَن كتب فقد قرأ ما قبله (PostTicketMessage يقدّم مؤشّره).
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);
        $this->staffReplies($ticket, 'أهلاً');
        $this->customerWrites($ticket, $customer, 'أريد 500 كيس');

        // Act
        $this->staffReplies($ticket, 'تمام');

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 2);
    }

    public function test_a_reply_the_customer_already_read_before_the_job_ran_is_not_pushed(): void
    {
        // Arrange — الخيطُ كان مفتوحاً، فوصل الردُّ حيّاً وقُرئ قبل أن يصل الطابورُ إلى المستمِع.
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);
        Event::fake([TicketChanged::class]);
        $this->staffReplies($ticket, 'أهلاً');
        app(MarkTicketRead::class)($ticket->refresh(), staff: false);
        $messageId = (int) $ticket->refresh()->customer_read_message_id;

        // Act
        app(NotifyCustomerWhenSupportReplies::class)->handle(
            new TicketChanged((int) $ticket->getKey(), TicketChange::MessagePosted, $messageId),
        );

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_other_ticket_changes_are_not_pushed(): void
    {
        // Arrange
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);

        // Act
        app(CloseTicket::class)($ticket->refresh(), User::factory()->create());

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_a_deactivated_customer_is_not_woken(): void
    {
        // Arrange
        $customer = $this->customerWithADevice(Customer::factory()->inactive()->create());
        $ticket = $this->open($customer);

        // Act
        $this->staffReplies($ticket);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_nothing_is_pushed_while_firebase_is_not_configured(): void
    {
        // Arrange
        config()->set('services.fcm.credentials', null);
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);

        // Act
        $this->staffReplies($ticket);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_a_message_gone_before_the_job_runs_pushes_nothing(): void
    {
        // Arrange
        $customer = $this->customerWithADevice();
        $ticket = $this->open($customer);

        // Act
        app(NotifyCustomerWhenSupportReplies::class)->handle(
            new TicketChanged((int) $ticket->getKey(), TicketChange::MessagePosted, 999999),
        );

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_the_listener_is_queued_after_commit_and_registered(): void
    {
        // Arrange
        Event::fake();

        // Act
        $listener = app(NotifyCustomerWhenSupportReplies::class);

        // Assert
        $this->assertInstanceOf(ShouldQueue::class, $listener);
        $this->assertTrue($listener->afterCommit);
        Event::assertListening(TicketChanged::class, NotifyCustomerWhenSupportReplies::class);
    }
}
