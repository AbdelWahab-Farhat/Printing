<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Broadcast;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * من يحقّ له أن يستمع إلى أيّ قناة.
 *
 * **القناةُ الخاصة لا تُفتح إلا بتوقيعٍ من هذا الخادم**، وهذان البابان — باب الموظفين وباب
 * العملاء — هما من يوقّع. فكلُّ ما يحرسه `auth:sanctum` و`auth:customer` على بقية المسارات يجب أن
 * يُحرس هنا أيضاً، وإلا صار المقبس طريقاً جانبياً إلى محادثات الناس.
 *
 * **مُذيع الاختبارات `null` يُجيز كلَّ قناةٍ بلا سؤال**، فلا يختبر شيئاً. لذلك تبدّل هذه الحالةُ
 * المُذيعَ إلى `reverb` بمفاتيح وهمية، وتسجّل القنوات عليه من جديد: التسجيل يقع على المُذيع
 * الافتراضي ساعةَ الإقلاع، والافتراضيُّ حينها كان `null`.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class RealtimeChannelAuthTest extends TestCase
{
    use RefreshDatabase;

    private const KEY = 'test-key';

    private const SECRET = 'test-secret';

    /** بصيغة Pusher: رقمان بينهما نقطة. */
    private const SOCKET_ID = '1234.5678';

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        config([
            'broadcasting.default' => 'reverb',
            'broadcasting.connections.reverb.key' => self::KEY,
            'broadcasting.connections.reverb.secret' => self::SECRET,
            'broadcasting.connections.reverb.app_id' => 'test-app',
            'broadcasting.connections.reverb.options.host' => '127.0.0.1',
            'broadcasting.connections.reverb.options.port' => 1,
            'broadcasting.connections.reverb.options.scheme' => 'http',
            'broadcasting.connections.reverb.options.useTLS' => false,
        ]);

        Broadcast::forgetDrivers();

        require base_path('routes/channels.php');
    }

    /**
     * @return array<string, string>
     */
    private function staff(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    /** التوقيع الذي يتحقق منه خادم Reverb — بصيغة Pusher حرفياً. */
    private function signatureFor(string $channel): string
    {
        return self::KEY.':'.hash_hmac('sha256', self::SOCKET_ID.':'.$channel, self::SECRET);
    }

    // ─────────────────────────── مكتب الدعم ───────────────────────────

    public function test_staff_who_read_the_queue_may_listen_to_the_desk(): void
    {
        // Arrange
        $headers = $this->staff(PermissionName::ViewSupportTickets);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-support.desk',
        ]);

        // Assert
        $response->assertOk()->assertExactJson(['auth' => $this->signatureFor('private-support.desk')]);
    }

    public function test_staff_without_the_view_permission_may_not_listen_to_the_desk(): void
    {
        // Arrange
        $headers = $this->staff();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-support.desk',
        ]);

        // Assert
        $response->assertForbidden();
    }

    public function test_the_staff_door_needs_a_token(): void
    {
        // Act
        $response = $this->postJson('/api/v1/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-support.desk',
        ]);

        // Assert
        $response->assertUnauthorized();
    }

    /**
     * رمزُ العميل رمزُ Sanctum كرمز الموظف، ولا يفرّقهما إلا مزوّد الحارس. فهذا الباب يجب أن
     * يرفضه كما ترفضه بقيةُ مسارات الموظفين — `CustomerAuthTest` يحرس الجدار نفسه هناك.
     */
    public function test_a_customer_token_is_refused_at_the_staff_door(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($customer))->postJson('/api/v1/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-support.desk',
        ]);

        // Assert
        $response->assertUnauthorized();
    }

    // ─────────────────────────── قناة العميل ───────────────────────────

    public function test_a_customer_may_listen_to_their_own_channel(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();
        $channel = "private-customers.{$customer->id}";

        // Act
        $response = $this->withHeaders($this->bearerFor($customer))->postJson('/api/v1/client/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => $channel,
        ]);

        // Assert
        $response->assertOk()->assertExactJson(['auth' => $this->signatureFor($channel)]);
    }

    public function test_a_customer_may_not_listen_to_another_customers_channel(): void
    {
        // Arrange
        $me = Customer::factory()->registered()->create();
        $them = Customer::factory()->registered()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->postJson('/api/v1/client/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => "private-customers.{$them->id}",
        ]);

        // Assert
        $response->assertForbidden();
    }

    /**
     * **ولا يفتح بابُ العملاء قناةَ المكتب**، وإن حمل رمزاً صالحاً: قناةُ المكتب تسأل حارسَ
     * الموظفين وحده، ورمزُ العميل ليس رمزاً عنده.
     */
    public function test_a_customer_may_not_listen_to_the_desk(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($customer))->postJson('/api/v1/client/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-support.desk',
        ]);

        // Assert
        $response->assertForbidden();
    }

    public function test_a_staff_token_is_refused_at_the_customer_door(): void
    {
        // Arrange
        $headers = $this->staff(PermissionName::ViewSupportTickets);
        $customer = Customer::factory()->registered()->create();

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/client/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => "private-customers.{$customer->id}",
        ]);

        // Assert
        $response->assertUnauthorized();
    }

    /**
     * رقمُ عميلٍ ليس رقماً لا يصل إلى المقارنة أصلاً — ولا يصير خطأً ٥٠٠ في الطريق.
     */
    public function test_a_channel_named_for_no_customer_is_refused(): void
    {
        // Arrange
        $customer = Customer::factory()->registered()->create();

        // Act
        $response = $this->withHeaders($this->bearerFor($customer))->postJson('/api/v1/client/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-customers.abc',
        ]);

        // Assert
        $response->assertForbidden();
    }

    // ─────────────────────────── الطلب نفسه ───────────────────────────

    /**
     * مكتبة Pusher ترمي استثناءً على رقم مقبسٍ مشوّه، فيصير الطلبُ ٥٠٠ لو وصلها. يُرفض هنا ٤٢٢
     * قبل أن يصل.
     */
    public function test_a_malformed_socket_id_is_a_validation_error(): void
    {
        // Arrange
        $headers = $this->staff(PermissionName::ViewSupportTickets);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/broadcasting/auth', [
            'socket_id' => 'not-a-socket',
            'channel_name' => 'private-support.desk',
        ]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['socket_id']);
    }

    public function test_a_channel_nobody_declared_is_refused(): void
    {
        // Arrange
        $headers = $this->staff(PermissionName::ViewSupportTickets);

        // Act
        $response = $this->withHeaders($headers)->postJson('/api/v1/broadcasting/auth', [
            'socket_id' => self::SOCKET_ID,
            'channel_name' => 'private-orders.all',
        ]);

        // Assert
        $response->assertForbidden();
    }
}
