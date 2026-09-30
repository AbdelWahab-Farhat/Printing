<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Customer\Models\Customer;
use App\Domain\Notification\Enums\DevicePlatform;
use App\Domain\Notification\Jobs\DeliverCustomerPush;
use App\Domain\Notification\Listeners\NotifyCustomerWhenOrderStageChanges;
use App\Domain\Notification\Models\CustomerDeviceToken;
use App\Domain\Order\Enums\CustomerOrderStage;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Events\OrderStatusChanged;
use App\Domain\Order\Models\Order;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * تتحرّك الطلبية، فيُخبَر صاحبُها — بالمراحل التي تعنيه، لا بكل خطوةٍ في الورشة.
 *
 * **يُحكم بالمرحلة لا بالحالة.** حالاتُ الورشة تصل إلى العميل مراحلَ أقلّ ({@see CustomerOrderStage})،
 * فانتقالٌ بين حالتين من مرحلةٍ واحدة — من المطبعة إلى الورشة الخارجية — لا يغيّر شيئاً مما يراه،
 * فلا يُقال له شيء.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class CustomerOrderPushTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config()->set('services.fcm.project_id', 'test-project');
        config()->set('services.fcm.credentials', '/dev/null');

        // المهمّة وحدها مزيّفة: ما يُدرَج هو السؤال، لا ما يصل إلى Google.
        Queue::fake([DeliverCustomerPush::class]);
    }

    private function orderWithADevice(?Customer $customer = null): Order
    {
        $customer ??= Customer::factory()->create();

        $device = new CustomerDeviceToken;
        $device->customer_id = (int) $customer->getKey();
        $device->token = 'token-'.uniqid();
        $device->platform = DevicePlatform::Android;
        $device->save();

        return Order::factory()->forCustomer($customer)->create();
    }

    private function move(Order $order, OrderStatus $from, OrderStatus $to): void
    {
        app(NotifyCustomerWhenOrderStageChanges::class)->handle(
            new OrderStatusChanged((int) $order->getKey(), $from, $to),
        );
    }

    /**
     * @return array<string, array{0: OrderStatus, 1: OrderStatus, 2: string}>
     */
    public static function announcedMoves(): array
    {
        return [
            'the request is accepted' => [OrderStatus::Requested, OrderStatus::New, 'قبلنا طلبيتك'],
            'the request is refused' => [OrderStatus::Requested, OrderStatus::RequestRejected, 'تعذّر قبول طلبيتك'],
            'made at our press' => [OrderStatus::Printing, OrderStatus::Ready, 'طلبيتك جاهزة'],
            'made at a vendor, waiting at the counter' => [OrderStatus::Manufacturing, OrderStatus::OfficePickup, 'طلبيتك جاهزة'],
            'out with the courier' => [OrderStatus::Ready, OrderStatus::OutForDelivery, 'طلبيتك في الطريق إليك'],
            'sent out again after a return' => [OrderStatus::Resend, OrderStatus::OutForDelivery, 'طلبيتك في الطريق إليك'],
            'came back' => [OrderStatus::OutForDelivery, OrderStatus::ReturnedCourier, 'رجعت طلبيتك إلينا'],
            'written off' => [OrderStatus::New, OrderStatus::Cancelled, 'أُلغيت طلبيتك'],
        ];
    }

    #[DataProvider('announcedMoves')]
    public function test_a_move_the_customer_cares_about_is_pushed(OrderStatus $from, OrderStatus $to, string $title): void
    {
        // Arrange
        $order = $this->orderWithADevice();

        // Act
        $this->move($order, $from, $to);

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 1);
        Queue::assertPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => $job->title === $title
            && $job->route === '/orders/'.$order->getKey());
    }

    /**
     * @return array<string, array{0: OrderStatus, 1: OrderStatus}>
     */
    public static function silentMoves(): array
    {
        return [
            // المرحلةُ نفسها على الجانبين: لا شيء تغيّر على شاشة العميل.
            'press to vendor, both producing' => [OrderStatus::Printing, OrderStatus::Manufacturing],
            'ready to the counter, both ready' => [OrderStatus::Ready, OrderStatus::OfficePickup],
            'delivered to settled, both delivered' => [OrderStatus::Delivered, OrderStatus::Settled],
            'returned to resend, both returned' => [OrderStatus::ReturnedCourier, OrderStatus::Resend],
            'new to deposit, both preparing' => [OrderStatus::New, OrderStatus::AwaitingDeposit],

            // «قيد التجهيز» خبرٌ مرةً واحدة — حين يُقبل الطلب — لا كلما رجعت إليه الورشة.
            'back from the artwork to the press queue' => [OrderStatus::Designing, OrderStatus::ReadyToPrint],

            // تقدّمٌ لا يُطلب فيه من العميل شيء، ويراه في التطبيق.
            'into designing' => [OrderStatus::New, OrderStatus::Designing],
            'into producing' => [OrderStatus::ReadyToPrint, OrderStatus::Printing],

            // الطردُ في يده، فلا يُخبَر بما يعرفه.
            'delivered' => [OrderStatus::OutForDelivery, OrderStatus::Delivered],

            // التراجعُ عن الرفض يعيد الطلب إلى المراجعة — والعميلُ لم يُسأل شيئاً.
            'refusal undone' => [OrderStatus::RequestRejected, OrderStatus::Requested],
        ];
    }

    #[DataProvider('silentMoves')]
    public function test_a_move_that_changes_nothing_for_the_customer_is_silent(OrderStatus $from, OrderStatus $to): void
    {
        // Arrange
        $order = $this->orderWithADevice();

        // Act
        $this->move($order, $from, $to);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_the_body_is_the_order_code_then_the_stage_hint(): void
    {
        // Arrange
        $order = $this->orderWithADevice();
        $hint = (string) CustomerOrderStage::Ready->hint();

        // Act
        $this->move($order, OrderStatus::Printing, OrderStatus::Ready);

        // Assert — الرقمُ عارياً في أوّل النص: لا «طلبية» ولا «#» قبله (قاعدةٌ في تطبيق العميل).
        Queue::assertPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => $job->body === "{$order->code} · {$hint}");
    }

    public function test_a_stage_with_no_hint_sends_the_code_alone(): void
    {
        // Arrange — «ملغاة» بلا سطرٍ تحتها.
        $order = $this->orderWithADevice();

        // Act
        $this->move($order, OrderStatus::New, OrderStatus::Cancelled);

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => $job->body === (string) $order->code);
    }

    public function test_the_order_code_is_never_prefixed(): void
    {
        // Arrange
        $order = $this->orderWithADevice();

        // Act
        foreach (self::announcedMoves() as [$from, $to]) {
            $this->move($order, $from, $to);
        }

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, count(self::announcedMoves()));
        Queue::assertNotPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => ! str_starts_with($job->body, (string) $order->code)
            || str_contains($job->title.$job->body, '#')
            || str_contains($job->title.$job->body, 'طلبية '.$order->code));
    }

    public function test_every_destination_status_is_decided(): void
    {
        // Arrange — `match` بلا `default`: مرحلةٌ جديدة بلا قرارٍ ترمي هنا لا في الإنتاج.
        $order = $this->orderWithADevice();

        // Act
        foreach (OrderStatus::cases() as $to) {
            $this->move($order, OrderStatus::Requested, $to);
            $this->move($order, OrderStatus::Cancelled, $to);
        }

        // Assert — من المراجعة: خمسُ حالاتٍ إلى «قيد التجهيز» + جاهزتان + التوصيل + أربعُ مرتجعات
        // + الإلغاء + الرفض = ١٤. ومن «ملغاة»: التجهيزُ صامتٌ لأنه ليس من المراجعة، فجاهزتان + التوصيل
        // + أربعُ مرتجعات + الرفض = ٨.
        Queue::assertPushed(DeliverCustomerPush::class, 22);
    }

    public function test_only_the_customer_who_owns_the_order_is_pushed(): void
    {
        // Arrange
        $order = $this->orderWithADevice();
        $stranger = Customer::factory()->create();
        $strangersDevice = new CustomerDeviceToken;
        $strangersDevice->customer_id = (int) $stranger->getKey();
        $strangersDevice->token = 'stranger-token';
        $strangersDevice->platform = DevicePlatform::Ios;
        $strangersDevice->save();

        // Act
        $this->move($order, OrderStatus::Ready, OrderStatus::OutForDelivery);

        // Assert
        Queue::assertPushed(DeliverCustomerPush::class, 1);
        Queue::assertNotPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => $job->customerDeviceTokenId === (int) $strangersDevice->getKey());
    }

    public function test_a_deactivated_customer_hears_nothing(): void
    {
        // Arrange
        $order = $this->orderWithADevice(Customer::factory()->inactive()->create());

        // Act
        $this->move($order, OrderStatus::Ready, OrderStatus::OutForDelivery);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_a_deleted_customer_hears_nothing(): void
    {
        // Arrange
        $customer = Customer::factory()->create();
        $order = $this->orderWithADevice($customer);
        $customer->delete();

        // Act
        $this->move($order, OrderStatus::Ready, OrderStatus::OutForDelivery);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_nothing_is_pushed_while_firebase_is_not_configured(): void
    {
        // Arrange
        config()->set('services.fcm.project_id', '');
        $order = $this->orderWithADevice();

        // Act
        $this->move($order, OrderStatus::Ready, OrderStatus::OutForDelivery);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_an_order_gone_before_the_job_runs_pushes_nothing(): void
    {
        // Arrange
        $this->orderWithADevice();

        // Act
        app(NotifyCustomerWhenOrderStageChanges::class)->handle(
            new OrderStatusChanged(999999, OrderStatus::Ready, OrderStatus::OutForDelivery),
        );

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_the_listener_is_queued_after_commit_and_registered(): void
    {
        // Arrange
        Event::fake();

        // Act
        $listener = app(NotifyCustomerWhenOrderStageChanges::class);

        // Assert — دفعٌ فاشلٌ لا يُرجع طلبيةً سُلّمت، وخبرٌ عن معاملةٍ تراجعت لا يُسحب.
        $this->assertInstanceOf(ShouldQueue::class, $listener);
        $this->assertTrue($listener->afterCommit);
        Event::assertListening(OrderStatusChanged::class, NotifyCustomerWhenOrderStageChanges::class);
    }
}
