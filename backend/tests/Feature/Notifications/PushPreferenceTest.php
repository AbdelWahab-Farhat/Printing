<?php

declare(strict_types=1);

namespace Tests\Feature\Notifications;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\Role;
use App\Domain\Identity\Models\User;
use App\Domain\Notification\Actions\PublishNotification;
use App\Domain\Notification\DTOs\PendingNotification;
use App\Domain\Notification\Enums\DevicePlatform;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\Jobs\DeliverPushNotification;
use App\Domain\Notification\Models\DeviceToken;
use App\Domain\Notification\Models\NotificationPreference;
use App\Domain\Notification\Models\NotificationRecipient;
use App\Domain\Order\Enums\OrderStatus;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;
use Tests\TestCase;

/**
 * Per-employee push switches — Docs/notifications/PUSH-PREFERENCES.md.
 *
 * The bell always fills; a switch only decides whether the phone is woken, and only for a group
 * delivery. `Queue::fake()` throughout, so no push leaves the test (RULES.md §9).
 *
 * Arrange - Act - Assert throughout.
 */
class PushPreferenceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        // PushChannel sends nothing on an unconfigured box, so give it a project to aim at. The
        // queue is faked, so nothing is ever signed or sent.
        config()->set('services.fcm.project_id', 'test-project');
        config()->set('services.fcm.credentials', 'unused.json');

        Queue::fake();
    }

    /**
     * A real token, not `Sanctum::actingAs` (RULES.md §6).
     *
     * @return array<string, string>
     */
    private function auth(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function employeeWith(PermissionName ...$permissions): User
    {
        $role = Role::findOrCreate('push-pref-'.uniqid(), 'web');
        $role->givePermissionTo(array_map(fn (PermissionName $p) => $p->value, $permissions));

        $user = User::factory()->create(['is_active' => true]);
        $user->assignRole($role);
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        return $user;
    }

    private function admin(): User
    {
        $admin = User::factory()->create(['is_active' => true]);
        $admin->assignRole(Role::findOrCreate(RoleName::Admin->value, 'web'));
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        return $admin;
    }

    private function deviceFor(User $user): DeviceToken
    {
        $device = new DeviceToken;
        $device->user_id = (int) $user->getKey();
        $device->token = 'token-'.uniqid();
        $device->platform = DevicePlatform::Android;
        $device->save();

        return $device;
    }

    private function mute(User $user, NotificationType $type, string $scope = ''): void
    {
        $row = new NotificationPreference;
        $row->forceFill([
            'user_id' => $user->getKey(),
            'type' => $type,
            'scope' => $scope,
            'push' => false,
        ])->save();
    }

    private function publish(NotificationType $type, array $payload): int
    {
        return (int) app(PublishNotification::class)->handle(new PendingNotification(
            type: $type,
            payload: $payload,
        ))->getKey();
    }

    /**
     * @return list<int> the device ids a push job was queued for
     */
    private function pushedDevices(): array
    {
        return Queue::pushed(DeliverPushNotification::class)
            ->map(fn (DeliverPushNotification $job) => (fn () => $this->deviceTokenId)->call($job))
            ->values()
            ->all();
    }

    private function bellHolds(User $user, int $notificationId): bool
    {
        return NotificationRecipient::query()
            ->where('user_id', $user->getKey())
            ->where('notification_id', $notificationId)
            ->exists();
    }

    // ── delivery ────────────────────────────────────────────────────────────────────────────

    public function test_a_muted_employee_gets_the_bell_but_not_the_push(): void
    {
        // Arrange
        $muted = $this->employeeWith(PermissionName::ViewOrders);
        $other = $this->employeeWith(PermissionName::ViewOrders);
        $mutedDevice = $this->deviceFor($muted);
        $otherDevice = $this->deviceFor($other);
        $this->mute($muted, NotificationType::OrderShortage);

        // Act
        $id = $this->publish(NotificationType::OrderShortage, ['order_id' => 7, 'order_code' => 'O7']);

        // Assert — the bell is never switched off; only the phone stays quiet.
        $this->assertTrue($this->bellHolds($muted, $id));
        $this->assertTrue($this->bellHolds($other, $id));
        $this->assertSame([(int) $otherDevice->getKey()], $this->pushedDevices());
        $this->assertNotContains((int) $mutedDevice->getKey(), $this->pushedDevices());
    }

    public function test_an_order_status_is_muted_per_status(): void
    {
        // Arrange — the warehouse keeps «جاهزة» and silences «تم التسوية».
        $user = $this->employeeWith(PermissionName::ViewOrders);
        $device = $this->deviceFor($user);
        $this->mute($user, NotificationType::OrderStatusChanged, OrderStatus::Settled->value);

        // Act
        $this->publish(NotificationType::OrderStatusChanged, ['order_id' => 1, 'to_status' => OrderStatus::Settled->value]);
        $settledPushes = $this->pushedDevices();
        $this->publish(NotificationType::OrderStatusChanged, ['order_id' => 2, 'to_status' => OrderStatus::Ready->value]);

        // Assert
        $this->assertSame([], $settledPushes);
        $this->assertSame([(int) $device->getKey()], $this->pushedDevices());
    }

    public function test_a_switch_set_on_another_type_mutes_nothing_here(): void
    {
        // Arrange
        $user = $this->employeeWith(PermissionName::ViewOrders);
        $device = $this->deviceFor($user);
        $this->mute($user, NotificationType::OrderStatusChanged, OrderStatus::Settled->value);

        // Act
        $this->publish(NotificationType::OrderShortage, ['order_id' => 7]);

        // Assert
        $this->assertSame([(int) $device->getKey()], $this->pushedDevices());
    }

    public function test_a_notification_addressed_to_the_employee_by_name_always_pushes(): void
    {
        // Arrange — the same type is muted, but this ticket is on their desk.
        $user = $this->employeeWith(PermissionName::ManageSupportTickets);
        $device = $this->deviceFor($user);
        $this->mute($user, NotificationType::SupportCustomerMessage);

        // Act
        $this->publish(NotificationType::SupportCustomerMessage, [
            'ticket_id' => 3,
            'subject' => 'سؤال',
            'customer_name' => 'أحمد',
            'assignee_id' => (int) $user->getKey(),
            'is_opening' => true,
        ]);

        // Assert
        $this->assertSame([(int) $device->getKey()], $this->pushedDevices());
    }

    public function test_the_same_type_to_the_queue_respects_the_switch(): void
    {
        // Arrange
        $user = $this->employeeWith(PermissionName::ManageSupportTickets);
        $this->deviceFor($user);
        $this->mute($user, NotificationType::SupportCustomerMessage);

        // Act
        $this->publish(NotificationType::SupportCustomerMessage, [
            'ticket_id' => 3,
            'subject' => 'سؤال',
            'customer_name' => 'أحمد',
            'assignee_id' => null,
            'is_opening' => true,
        ]);

        // Assert
        $this->assertSame([], $this->pushedDevices());
    }

    // ── the settings endpoints ──────────────────────────────────────────────────────────────

    public function test_the_list_shows_only_what_the_employee_can_receive(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);

        // Act
        $response = $this->getJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            $this->auth($this->admin()),
        );

        // Assert — order status and shortage, not order review, support or salaries.
        $response->assertOk();
        $this->assertSame(
            [NotificationType::OrderShortage->value, NotificationType::OrderStatusChanged->value],
            array_column($response->json('data'), 'type'),
        );
    }

    public function test_order_status_lists_one_switch_per_status_that_rings(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);
        $this->mute($employee, NotificationType::OrderStatusChanged, OrderStatus::Settled->value);

        // Act
        $groups = collect($this->getJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            $this->auth($this->admin()),
        )->json('data'))->keyBy('type');

        // Assert
        $switches = collect($groups[NotificationType::OrderStatusChanged->value]['switches'])->keyBy('scope');
        $this->assertTrue($switches->has(OrderStatus::Ready->value));
        $this->assertFalse($switches->has(OrderStatus::Printing->value), 'a silent status has no switch');
        $this->assertFalse($switches[OrderStatus::Settled->value]['push']);
        $this->assertTrue($switches[OrderStatus::Ready->value]['push']);
        $this->assertSame(OrderStatus::Ready->label(), $switches[OrderStatus::Ready->value]['label']);

        $shortage = $groups[NotificationType::OrderShortage->value]['switches'];
        $this->assertSame([['scope' => '', 'label' => 'نواقص طلبية', 'push' => true]], $shortage);
    }

    public function test_an_admin_target_sees_every_group_type(): void
    {
        // Act
        $target = $this->admin();
        $types = array_column($this->getJson(
            "/api/v1/users/{$target->getKey()}/notification-preferences",
            $this->auth($this->admin()),
        )->json('data'), 'type');

        // Assert
        $this->assertCount(7, $types);
        $this->assertNotContains(NotificationType::Announcement->value, $types);
        $this->assertNotContains(NotificationType::InternalTicketMessage->value, $types);
    }

    public function test_switching_off_and_back_on_flips_one_row(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);
        $headers = $this->auth($this->admin());
        $url = "/api/v1/users/{$employee->getKey()}/notification-preferences";

        // Act
        $off = $this->putJson($url, ['type' => 'order.status', 'scope' => 'settled', 'push' => false], $headers);
        $on = $this->putJson($url, ['type' => 'order.status', 'scope' => 'settled', 'push' => true], $headers);

        // Assert — the history reads as one switch moving, not rows coming and going.
        $off->assertOk();
        $on->assertOk();
        $this->assertSame(1, NotificationPreference::query()->count());
        $this->assertTrue(NotificationPreference::query()->sole()->push);
    }

    public function test_switching_on_an_untouched_switch_writes_nothing(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);

        // Act
        $this->putJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            ['type' => 'order.shortage', 'push' => true],
            $this->auth($this->admin()),
        )->assertOk();

        // Assert
        $this->assertSame(0, NotificationPreference::query()->count());
    }

    public function test_the_change_returns_the_settings_after_it(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);

        // Act
        $response = $this->putJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            ['type' => 'order.shortage', 'push' => false],
            $this->auth($this->admin()),
        );

        // Assert
        $shortage = collect($response->json('data'))->firstWhere('type', 'order.shortage');
        $this->assertFalse($shortage['switches'][0]['push']);
    }

    public function test_a_type_that_always_pushes_has_no_switch(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);

        // Act
        $response = $this->putJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            ['type' => 'announcement.manual', 'push' => false],
            $this->auth($this->admin()),
        );

        // Assert
        $response->assertStatus(422);
        $this->assertSame(0, NotificationPreference::query()->count());
    }

    public function test_a_status_that_never_rings_has_no_switch(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);
        $headers = $this->auth($this->admin());
        $url = "/api/v1/users/{$employee->getKey()}/notification-preferences";

        // Act
        $silent = $this->putJson($url, ['type' => 'order.status', 'scope' => 'printing', 'push' => false], $headers);
        $missing = $this->putJson($url, ['type' => 'order.status', 'push' => false], $headers);
        $extra = $this->putJson($url, ['type' => 'order.shortage', 'scope' => 'ready', 'push' => false], $headers);

        // Assert
        $silent->assertStatus(422);
        $missing->assertStatus(422);
        $extra->assertStatus(422);
        $this->assertSame(0, NotificationPreference::query()->count());
    }

    public function test_an_unknown_type_is_a_validation_error(): void
    {
        // Arrange
        $employee = $this->employeeWith(PermissionName::ViewOrders);

        // Act
        $response = $this->putJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            ['type' => 'order.nonsense', 'push' => false],
            $this->auth($this->admin()),
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('type');
    }

    public function test_only_users_manage_may_read_or_change_the_settings(): void
    {
        // Arrange — an employee may not silence their own pushes, nor read anyone's.
        $employee = $this->employeeWith(PermissionName::ViewOrders, PermissionName::ViewUsers);
        $url = "/api/v1/users/{$employee->getKey()}/notification-preferences";
        $headers = $this->auth($employee);

        // Act
        $read = $this->getJson($url, $headers);
        $write = $this->putJson($url, ['type' => 'order.shortage', 'push' => false], $headers);

        // Assert
        $read->assertForbidden();
        $write->assertForbidden();
        $this->assertSame(0, NotificationPreference::query()->count());
    }

    public function test_a_manager_with_users_manage_may_change_them(): void
    {
        // Arrange
        $manager = $this->employeeWith(PermissionName::ManageUsers);
        $employee = $this->employeeWith(PermissionName::ViewOrders);

        // Act
        $response = $this->putJson(
            "/api/v1/users/{$employee->getKey()}/notification-preferences",
            ['type' => 'order.shortage', 'push' => false],
            $this->auth($manager),
        );

        // Assert
        $response->assertOk();
        $this->assertFalse(NotificationPreference::query()->sole()->push);
    }
}
