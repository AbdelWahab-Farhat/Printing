<?php

declare(strict_types=1);

namespace Tests\Feature\Orders;

use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Order\Models\Order;
use App\Domain\Support\Models\SupportTicket;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

/**
 * «التذاكر المرتبطة» — `GET orders/{order}/tickets`: الأنواع الثلاثة في قائمةٍ واحدة، المفتوحةُ
 * أولاً، وما لا يراه القارئ في قائمة نوعه لا يراه هنا.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class OrderTicketsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    /**
     * قارئُ طلبياتٍ بما يُمنح فوق `orders.view`.
     *
     * @return array{0: User, 1: array<string, string>}
     */
    private function reader(PermissionName ...$permissions): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo(array_map(
            fn (PermissionName $p) => $p->value,
            [PermissionName::ViewOrders, ...$permissions],
        ));

        return [$user, $this->headersOf($user)];
    }

    /**
     * @return array<string, string>
     */
    private function headersOf(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_it_lists_every_kind_with_its_label_open_first_then_most_recent(): void
    {
        // Arrange
        [$me, $headers] = $this->reader(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
            PermissionName::ViewSupportTickets,
        );
        $order = Order::factory()->create();
        $closed = InternalTicket::factory()->between($me, User::factory()->create())->closed()
            ->create(['order_id' => $order->id, 'last_message_at' => now()->subMinute()]);
        $staff = InternalTicket::factory()->between(User::factory()->create(), $me)
            ->create(['order_id' => $order->id, 'last_message_at' => now()->subHours(3)]);
        $design = DesignTicket::factory()
            ->create(['order_id' => $order->id, 'status' => DesignTicketStatus::ChangesRequested, 'updated_at' => now()->subHour()]);
        $support = SupportTicket::factory()
            ->create(['order_id' => $order->id, 'last_message_at' => now()->subHours(2)]);
        InternalTicket::factory()->between($me, User::factory()->create())->create();

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}/tickets", $headers);

        // Assert
        $response->assertOk();
        $this->assertSame(
            [['design', $design->id], ['support', $support->id], ['internal', $staff->id], ['internal', $closed->id]],
            array_map(fn (array $row): array => [$row['kind'], $row['id']], $response->json('data')),
        );
        $response
            ->assertJsonPath('data.0.kind_label', 'تصميم')
            ->assertJsonPath('data.0.code', $design->code)
            ->assertJsonPath('data.0.status_label', 'تعديل مطلوب')
            ->assertJsonPath('data.1.kind_label', 'عميل')
            ->assertJsonPath('data.1.code', null)
            ->assertJsonPath('data.1.title', $support->subject)
            ->assertJsonPath('data.2.kind_label', 'موظفين')
            ->assertJsonPath('data.2.code', $staff->code)
            ->assertJsonPath('data.3.is_open', false)
            ->assertJsonPath('data.3.status_label', 'مغلقة');
    }

    public function test_a_staff_ticket_shows_only_to_its_two_parties_and_the_admin(): void
    {
        // Arrange
        [, $outsiderHeaders] = $this->reader(...PermissionName::cases());
        $admin = User::factory()->create();
        Role::findOrCreate(RoleName::Admin->value, 'web');
        $admin->syncRoles([RoleName::Admin->value]);
        $order = Order::factory()->create();
        $ticket = InternalTicket::factory()->create(['order_id' => $order->id]);

        // Act
        $outsider = $this->getJson("/api/v1/orders/{$order->id}/tickets", $outsiderHeaders);
        $asAdmin = $this->getJson("/api/v1/orders/{$order->id}/tickets", $this->headersOf($admin));

        // Assert
        $outsider->assertOk()->assertJsonCount(0, 'data');
        $asAdmin->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $ticket->id);
    }

    public function test_design_and_customer_tickets_need_the_grant_of_their_own_list(): void
    {
        // Arrange
        [, $headers] = $this->reader();
        $order = Order::factory()->create();
        DesignTicket::factory()->create(['order_id' => $order->id]);
        SupportTicket::factory()->create(['order_id' => $order->id]);

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}/tickets", $headers);

        // Assert
        $response->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_a_designer_without_view_all_sees_only_the_design_tickets_they_are_part_of(): void
    {
        // Arrange
        [$me, $headers] = $this->reader(PermissionName::ViewDesignTickets);
        $order = Order::factory()->create();
        $mine = DesignTicket::factory()->create(['order_id' => $order->id, 'requested_by_user_id' => $me->id]);
        DesignTicket::factory()->assignedTo(User::factory()->create()->id)->create(['order_id' => $order->id]);

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}/tickets", $headers);

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $mine->id);
    }

    public function test_it_is_refused_to_somebody_who_may_not_read_orders(): void
    {
        // Arrange
        $order = Order::factory()->create();

        // Act
        $response = $this->getJson("/api/v1/orders/{$order->id}/tickets", $this->headersOf(User::factory()->create()));

        // Assert
        $response->assertForbidden();
    }

    public function test_an_archived_order_answers_only_with_the_archive_grant(): void
    {
        // Arrange
        [$me, $viewer] = $this->reader();
        [, $archivist] = $this->reader(PermissionName::ViewOrderArchive);
        $order = Order::factory()->create();
        InternalTicket::factory()->between($me, User::factory()->create())->create(['order_id' => $order->id]);
        $order->delete();

        // Act
        $refused = $this->getJson("/api/v1/orders/{$order->id}/tickets", $viewer);
        $allowed = $this->getJson("/api/v1/orders/{$order->id}/tickets", $archivist);

        // Assert
        $refused->assertForbidden();
        $allowed->assertOk();
    }
}
