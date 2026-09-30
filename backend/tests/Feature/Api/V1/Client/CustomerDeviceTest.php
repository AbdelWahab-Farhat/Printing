<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Enums\DevicePlatform;
use App\Domain\Notification\Models\CustomerDeviceToken;
use App\Domain\Notification\Models\DeviceToken;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * هاتفُ العميل يطلب أن يُوقَظ، ويطلب أن يُنسى.
 *
 * **جدولٌ خاصٌّ بالعملاء لا `device_tokens`**: ذاك مفتاحه `users.id`، والعميل ليس موظفاً. والقرار
 * مأخوذ: العميل يأخذ الدفع وحده — لا صندوق بريد ولا جرس — فلا شيء في جداول الموظفين يُعمَّم لأجله.
 *
 * **والتسجيلُ استبدالٌ على الرمز لا إضافة**، كما عند الموظفين: هاتفٌ انتقل من عميلٍ إلى آخر لا يبقى
 * يوقظ الأوّل بطلبيات الثاني.
 *
 * Arrange - Act - Assert في كل اختبار.
 */
class CustomerDeviceTest extends TestCase
{
    use RefreshDatabase;

    private const ENDPOINT = '/api/v1/client/notifications/devices';

    private function customer(string $phone = '0911111111'): Customer
    {
        return Customer::factory()->registered()->create(['phone' => $phone]);
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    private function fcmToken(string $seed = 't'): string
    {
        return str_repeat($seed, 40);
    }

    public function test_registering_a_device_remembers_it_for_the_signed_in_customer(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android']);

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('message', 'تم تسجيل الجهاز')
            ->assertJsonPath('data', null);

        $device = CustomerDeviceToken::query()->sole();
        $this->assertSame((int) $me->getKey(), (int) $device->customer_id);
        $this->assertSame($this->fcmToken(), $device->token);
        $this->assertSame(DevicePlatform::Android, $device->platform);
        $this->assertNotNull($device->last_used_at);
    }

    public function test_a_token_registered_by_another_customer_moves_to_the_new_one(): void
    {
        // Arrange — هاتفٌ واحد، سجّل فيه عميلٌ ثم خرج ودخل غيره.
        $first = $this->customer('0911111111');
        $second = $this->customer('0922222222');

        $this->withHeaders($this->bearerFor($first))
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android'])
            ->assertOk();

        // الحارسُ يبقى على العميل الأوّل داخل الاختبار الواحد ما لم يُنسَ (RULES.md §6).
        $this->app->get('auth')->forgetGuards();

        // Act
        $response = $this->withHeaders($this->bearerFor($second))
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'ios']);

        // Assert — صفٌّ واحد، وهو الآن للثاني. صفّان كانا سيوقظان الأوّل بطلبيات الثاني.
        $response->assertOk();
        $this->assertSame(1, CustomerDeviceToken::query()->count());
        $this->assertDatabaseHas('customer_device_tokens', [
            'token' => $this->fcmToken(),
            'customer_id' => $second->getKey(),
            'platform' => 'ios',
        ]);
    }

    public function test_registering_the_same_token_twice_keeps_one_row(): void
    {
        // Arrange — FCM يعيد الرمز نفسه عند كل تشغيل، والتطبيق يسجّله كل مرة.
        $me = $this->customer();
        $headers = $this->bearerFor($me);
        $this->withHeaders($headers)->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android']);

        // Act
        $response = $this->withHeaders($headers)
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android']);

        // Assert
        $response->assertOk();
        $this->assertSame(1, CustomerDeviceToken::query()->count());
    }

    public function test_a_customer_device_never_lands_in_the_staff_table(): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $this->withHeaders($this->bearerFor($me))
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android'])
            ->assertOk();

        // Assert — جدولُ الموظفين مفتاحه `users.id`، وصفٌّ للعميل فيه كان سيوقظ موظفاً رقمه رقمُ العميل.
        $this->assertSame(0, DeviceToken::query()->count());
    }

    /**
     * @return array<string, array{0: array<string, mixed>, 1: string, 2: string}>
     */
    public static function invalidRegistrations(): array
    {
        return [
            'no token' => [['platform' => 'android'], 'token', 'رمز الجهاز مطلوب'],
            'no platform' => [['token' => str_repeat('t', 40)], 'platform', 'نوع الجهاز مطلوب'],
            'unknown platform' => [['token' => str_repeat('t', 40), 'platform' => 'blackberry'], 'platform', 'نوع الجهاز غير صحيح'],
        ];
    }

    /**
     * @param  array<string, mixed>  $body
     */
    #[DataProvider('invalidRegistrations')]
    public function test_an_invalid_registration_is_refused_with_a_field_error(array $body, string $field, string $message): void
    {
        // Arrange
        $me = $this->customer();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson(self::ENDPOINT, $body);

        // Assert
        $response->assertStatus(422)
            ->assertJsonPath('status', false)
            ->assertJsonPath('message', 'البيانات المدخلة غير صحيحة')
            ->assertJsonPath('data', null)
            ->assertJsonPath("errors.{$field}.0", $message);
        $this->assertSame(0, CustomerDeviceToken::query()->count());
    }

    public function test_a_token_too_short_or_too_long_is_refused(): void
    {
        // Arrange
        $headers = $this->bearerFor($this->customer());

        // Act
        $short = $this->withHeaders($headers)->postJson(self::ENDPOINT, ['token' => 'abc', 'platform' => 'ios']);
        $long = $this->withHeaders($headers)->postJson(self::ENDPOINT, ['token' => str_repeat('t', 256), 'platform' => 'ios']);

        // Assert
        $short->assertStatus(422)->assertJsonValidationErrors('token');
        $long->assertStatus(422)->assertJsonValidationErrors('token');
    }

    public function test_releasing_my_device_removes_it(): void
    {
        // Arrange
        $me = $this->customer();
        $headers = $this->bearerFor($me);
        $this->withHeaders($headers)->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'ios']);

        // Act
        $response = $this->withHeaders($headers)->deleteJson(self::ENDPOINT, ['token' => $this->fcmToken()]);

        // Assert
        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('message', 'تم إلغاء تسجيل الجهاز')
            ->assertJsonPath('data', null);
        $this->assertDatabaseMissing('customer_device_tokens', ['token' => $this->fcmToken()]);
    }

    public function test_releasing_an_unknown_token_is_still_a_success(): void
    {
        // Arrange — خروجٌ مرتين، أو نسخةٌ لم تسجّل قط.
        $headers = $this->bearerFor($this->customer());

        // Act
        $response = $this->withHeaders($headers)->deleteJson(self::ENDPOINT, ['token' => $this->fcmToken('x')]);

        // Assert
        $response->assertOk()->assertJsonPath('message', 'تم إلغاء تسجيل الجهاز');
    }

    public function test_releasing_somebody_elses_token_leaves_it_where_it_is(): void
    {
        // Arrange
        $owner = $this->customer('0911111111');
        $stranger = $this->customer('0922222222');
        $this->withHeaders($this->bearerFor($owner))
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android']);
        $this->app->get('auth')->forgetGuards();

        // Act
        $response = $this->withHeaders($this->bearerFor($stranger))
            ->deleteJson(self::ENDPOINT, ['token' => $this->fcmToken()]);

        // Assert — لا يُنسى هاتفُ أحدٍ بتخمين رمزه.
        $response->assertOk();
        $this->assertDatabaseHas('customer_device_tokens', [
            'token' => $this->fcmToken(),
            'customer_id' => $owner->getKey(),
        ]);
    }

    public function test_releasing_without_a_token_is_refused(): void
    {
        // Arrange
        $headers = $this->bearerFor($this->customer());

        // Act
        $response = $this->withHeaders($headers)->deleteJson(self::ENDPOINT, []);

        // Assert
        $response->assertStatus(422)->assertJsonPath('errors.token.0', 'رمز الجهاز مطلوب');
    }

    public function test_a_guest_is_refused(): void
    {
        // Act
        $register = $this->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android']);
        $release = $this->deleteJson(self::ENDPOINT, ['token' => $this->fcmToken()]);

        // Assert
        $register->assertUnauthorized()->assertJsonPath('status', false);
        $release->assertUnauthorized();
        $this->assertSame(0, CustomerDeviceToken::query()->count());
    }

    public function test_a_staff_token_cannot_register_a_customer_device(): void
    {
        // Arrange
        $staff = User::factory()->create(['is_active' => true]);
        $headers = ['Authorization' => 'Bearer '.$staff->createToken('staff')->plainTextToken];

        // Act
        $response = $this->withHeaders($headers)
            ->postJson(self::ENDPOINT, ['token' => $this->fcmToken(), 'platform' => 'android']);

        // Assert — الحارسُ `auth:customer`، فرمزُ الموظف لا يفتح بابَ العملاء ولو كان صحيحاً.
        $response->assertUnauthorized();
        $this->assertSame(0, CustomerDeviceToken::query()->count());
        $this->assertSame(0, DeviceToken::query()->count());
    }
}
