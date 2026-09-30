<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Customer\Models\Customer;
use App\Domain\Notification\DTOs\CustomerPush;
use App\Domain\Notification\Enums\DevicePlatform;
use App\Domain\Notification\Enums\FcmSendResult;
use App\Domain\Notification\Jobs\DeliverCustomerPush;
use App\Domain\Notification\Models\CustomerDeviceToken;
use App\Domain\Notification\NotificationService;
use App\Domain\Notification\Support\FcmClient;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

/**
 * الدفعُ إلى هاتف العميل — من الباب الواحد `pushToCustomer()` إلى طلب HTTP الذي يخرج إلى Firebase.
 *
 * **لا صفَّ إشعارٍ خلفه**، وهذا ما يفرّقه عن دفع الموظفين: العميل لا صندوق بريد له ولا جرس، فالعنوان
 * والنص والوجهة تسافر في المهمّة نفسها، ولا `notification_id` في بيانات الرسالة يبحث عنه التطبيق.
 *
 * `Http::fake()` في كل اختبارٍ يُرسل، فلا شيء هنا يصل إلى Google. والرمزُ مخبّأٌ في `setUp` كما في
 * {@see PushNotificationTest}، فلا يُوقَّع شيء.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class CustomerPushTest extends TestCase
{
    use RefreshDatabase;

    private string $credentialsPath;

    protected function setUp(): void
    {
        parent::setUp();

        $this->credentialsPath = tempnam(sys_get_temp_dir(), 'fcm').'.json';
        file_put_contents($this->credentialsPath, (string) json_encode([
            'client_email' => 'test@example.iam.gserviceaccount.com',
            'private_key' => 'unused',
        ]));

        config()->set('services.fcm.project_id', 'test-project');
        config()->set('services.fcm.credentials', $this->credentialsPath);
        config()->set('services.fcm.dry_run', false);
        config()->set('services.fcm.log_channel', null);

        Cache::put('fcm.access_token', 'test-access-token', 3600);
    }

    protected function tearDown(): void
    {
        @unlink($this->credentialsPath);

        parent::tearDown();
    }

    private function deviceFor(Customer $customer, DevicePlatform $platform = DevicePlatform::Android): CustomerDeviceToken
    {
        $device = new CustomerDeviceToken;
        $device->customer_id = (int) $customer->getKey();
        $device->token = 'token-'.uniqid();
        $device->platform = $platform;
        $device->save();

        return $device;
    }

    private function pushTo(Customer $customer): CustomerPush
    {
        return new CustomerPush(
            customerId: (int) $customer->getKey(),
            title: 'طلبيتك جاهزة',
            body: 'O7 · جاهزة — سنتواصل معك للتسليم',
            route: '/orders/7',
        );
    }

    private function fakeFcm(int $status = 200, array $body = ['name' => 'projects/test/messages/1']): void
    {
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'tok', 'expires_in' => 3600]),
            'fcm.googleapis.com/*' => Http::response($body, $status),
        ]);
    }

    /**
     * رسالةُ FCM الوحيدة التي خرجت.
     *
     * @return array<string, mixed>
     */
    private function sentMessage(): array
    {
        $sent = Http::recorded(fn (Request $request) => str_contains($request->url(), 'fcm.googleapis.com'));

        $this->assertCount(1, $sent);

        return (array) $sent->first()[0]->data()['message'];
    }

    // ───────────────────────────── الباب: pushToCustomer ─────────────────────────────

    public function test_one_job_is_queued_per_device_of_that_customer_alone(): void
    {
        // Arrange
        Queue::fake();
        $me = Customer::factory()->create();
        $somebodyElse = Customer::factory()->create();
        $android = $this->deviceFor($me);
        $iphone = $this->deviceFor($me, DevicePlatform::Ios);
        $this->deviceFor($somebodyElse);

        // Act
        app(NotificationService::class)->pushToCustomer($this->pushTo($me));

        // Assert — مهمّةٌ لكل جهاز، فرمزٌ ميّت يفشل وحده ولا يسقط معه الآخر.
        Queue::assertPushed(DeliverCustomerPush::class, 2);
        $queued = Queue::pushed(DeliverCustomerPush::class)
            ->map(fn (DeliverCustomerPush $job) => $job->customerDeviceTokenId)
            ->sort()->values()->all();
        $this->assertSame([(int) $android->getKey(), (int) $iphone->getKey()], $queued);
        Queue::assertPushed(DeliverCustomerPush::class, fn (DeliverCustomerPush $job) => $job->title === 'طلبيتك جاهزة'
            && $job->body === 'O7 · جاهزة — سنتواصل معك للتسليم'
            && $job->route === '/orders/7');
    }

    public function test_a_customer_with_no_device_queues_nothing(): void
    {
        // Arrange
        Queue::fake();
        $me = Customer::factory()->create();

        // Act
        app(NotificationService::class)->pushToCustomer($this->pushTo($me));

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_nothing_is_queued_while_firebase_is_not_configured(): void
    {
        // Arrange — حالُ كل خادمٍ حتى يُملأ FCM_PROJECT_ID.
        Queue::fake();
        config()->set('services.fcm.project_id', null);
        $me = Customer::factory()->create();
        $this->deviceFor($me);

        // Act
        app(NotificationService::class)->pushToCustomer($this->pushTo($me));

        // Assert — لا مهمّةَ تفشل ثلاث مرات وتدفن الأعطال الحقيقية في `failed_jobs`.
        Queue::assertNothingPushed();
    }

    public function test_nothing_is_queued_without_the_credentials_file(): void
    {
        // Arrange
        Queue::fake();
        config()->set('services.fcm.credentials', '');
        $me = Customer::factory()->create();
        $this->deviceFor($me);

        // Act
        app(NotificationService::class)->pushToCustomer($this->pushTo($me));

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_a_deactivated_customer_is_not_woken(): void
    {
        // Arrange
        Queue::fake();
        $me = Customer::factory()->inactive()->create();
        $this->deviceFor($me);

        // Act
        app(NotificationService::class)->pushToCustomer($this->pushTo($me));

        // Assert — حسابٌ أوقفه المحل لا يتلقّى أخبارَه.
        Queue::assertNothingPushed();
    }

    public function test_a_deleted_customer_is_not_woken(): void
    {
        // Arrange
        Queue::fake();
        $me = Customer::factory()->create();
        $this->deviceFor($me);
        $push = $this->pushTo($me);
        $me->delete();

        // Act
        app(NotificationService::class)->pushToCustomer($push);

        // Assert
        Queue::assertNothingPushed();
    }

    public function test_a_customer_who_does_not_exist_is_silently_skipped(): void
    {
        // Arrange
        Queue::fake();

        // Act
        app(NotificationService::class)->pushToCustomer(new CustomerPush(999999, 'عنوان', 'نص', '/orders/1'));

        // Assert — لا شيء يُقال، ولا شيء يُرمى.
        Queue::assertNothingPushed();
    }

    // ───────────────────────────── المهمّة: DeliverCustomerPush ─────────────────────────────

    public function test_the_push_carries_the_route_and_no_notification_id(): void
    {
        // Arrange
        $this->fakeFcm();
        $device = $this->deviceFor(Customer::factory()->create());

        // Act
        (new DeliverCustomerPush((int) $device->getKey(), 'طلبيتك جاهزة', 'O7', '/orders/7'))
            ->handle(app(FcmClient::class));

        // Assert — لا صفَّ إشعارٍ للعميل، فلا رقمَ يبحث عنه التطبيق.
        $message = $this->sentMessage();
        $this->assertSame($device->token, $message['token']);
        $this->assertSame(['title' => 'طلبيتك جاهزة', 'body' => 'O7'], $message['notification']);
        $this->assertSame(['route' => '/orders/7'], $message['data']);
        $this->assertArrayNotHasKey('notification_id', $message['data']);
    }

    public function test_an_iphone_push_has_sound_but_no_badge(): void
    {
        // Arrange
        $this->fakeFcm();
        $device = $this->deviceFor(Customer::factory()->create(), DevicePlatform::Ios);

        // Act
        (new DeliverCustomerPush((int) $device->getKey(), 'ردٌّ من الدعم', 'استفسار', '/support/3'))
            ->handle(app(FcmClient::class));

        // Assert — لا جرسَ للعميل يُعدّ منه رقمٌ على أيقونة التطبيق.
        $message = $this->sentMessage();
        $this->assertSame(['sound' => 'default'], $message['apns']['payload']['aps']);
    }

    public function test_a_delivered_push_touches_the_device(): void
    {
        // Arrange
        $this->fakeFcm();
        Carbon::setTestNow('2026-09-26 10:00:00');
        $device = $this->deviceFor(Customer::factory()->create());

        // Act
        (new DeliverCustomerPush((int) $device->getKey(), 'عنوان', 'نص', '/orders/1'))
            ->handle(app(FcmClient::class));

        // Assert
        $this->assertSame('2026-09-26 10:00:00', $device->refresh()->last_used_at?->toDateTimeString());
        Carbon::setTestNow();
    }

    public function test_a_dead_token_is_deleted_rather_than_retried(): void
    {
        // Arrange
        $this->fakeFcm(404, ['error' => ['status' => 'NOT_FOUND', 'details' => [['errorCode' => 'UNREGISTERED']]]]);
        $device = $this->deviceFor(Customer::factory()->create());

        // Act
        (new DeliverCustomerPush((int) $device->getKey(), 'عنوان', 'نص', '/orders/1'))
            ->handle(app(FcmClient::class));

        // Assert — تطبيقٌ أُزيل لا يملأ `failed_jobs` بمحاولاتٍ لن تنجح.
        $this->assertDatabaseMissing('customer_device_tokens', ['id' => $device->getKey()]);
    }

    public function test_a_device_released_before_the_job_runs_sends_nothing(): void
    {
        // Arrange
        Http::fake();

        // Act — رقمُ جهازٍ لم يعد موجوداً، وهو ما ينتجه طابورٌ متأخر بعد خروج العميل.
        (new DeliverCustomerPush(999999, 'عنوان', 'نص', '/orders/1'))->handle(app(FcmClient::class));

        // Assert
        Http::assertNothingSent();
    }

    public function test_the_job_retries_like_the_staff_one(): void
    {
        // Act
        $job = new DeliverCustomerPush(1, 'عنوان', 'نص', '/orders/1');

        // Assert
        $this->assertSame(3, $job->tries);
        $this->assertSame([30, 300], $job->backoff);
    }

    // ───────────────────────────── FcmClient: الموظفون لم يتغيّر لهم شيء ─────────────────────────────

    public function test_a_staff_push_still_carries_its_notification_id_as_a_string(): void
    {
        // Arrange
        $this->fakeFcm();

        // Act
        $result = app(FcmClient::class)->send(
            deviceToken: 'abc',
            platform: DevicePlatform::Android,
            title: 'عنوان',
            body: 'نص',
            route: '/orders/7',
            notificationId: 7,
        );

        // Assert — قيمُ `data` نصوصٌ لا أرقام، وإلا رفض FCM الرسالة كلها.
        $this->assertSame(FcmSendResult::Delivered, $result);
        $this->assertSame(['notification_id' => '7', 'route' => '/orders/7'], $this->sentMessage()['data']);
    }

    public function test_a_push_with_neither_id_nor_route_sends_no_data_block(): void
    {
        // Arrange
        $this->fakeFcm();

        // Act
        app(FcmClient::class)->send(
            deviceToken: 'abc',
            platform: DevicePlatform::Android,
            title: 'عنوان',
            body: 'نص',
            route: null,
            notificationId: null,
        );

        // Assert — مصفوفةٌ فارغة تُكتب `[]` في JSON لا `{}`، وFCM يرفض `data` ليست خريطة.
        $this->assertArrayNotHasKey('data', $this->sentMessage());
    }
}
