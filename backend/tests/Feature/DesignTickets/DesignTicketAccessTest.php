<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Models\Order;

/**
 * Who sees what — «تطبيق الصلاحيات بحيث لا يستطيع المصمم الوصول لما لا يخص عمله».
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketAccessTest extends DesignTicketTestCase
{
    public function test_an_unauthenticated_request_is_refused(): void
    {
        // Act
        $response = $this->getJson('/api/v1/design-tickets');

        // Assert
        $response->assertUnauthorized();
    }

    public function test_a_signed_in_user_without_the_grant_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->actor();

        // Act
        $response = $this->getJson('/api/v1/design-tickets', $headers);

        // Assert
        $response->assertForbidden();
    }

    public function test_a_designer_cannot_see_a_colleagues_ticket(): void
    {
        // Arrange — a ticket addressed to one designer, read by another.
        [, $employee] = $this->employee();
        [$mine] = $this->designer();
        [, $theirs] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $mine->id]),
                $employee,
            )->json('data.id'),
        );

        // Act
        $detail = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $theirs);
        $list = $this->getJson('/api/v1/design-tickets', $theirs);

        // Assert — a 404 rather than a 403, and the honest answer: «ليس لديك صلاحية» on a specific
        // id confirms that the ticket exists, which is the thing being withheld.
        $detail->assertNotFound();
        $list->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_a_designer_sees_the_unclaimed_pool(): void
    {
        // Arrange — work with nobody's name on it has to be findable, or it is never picked up.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $customer = $this->customer();

        $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
            ->assertCreated();

        // Act
        $response = $this->getJson('/api/v1/design-tickets?designer=none', $designer);

        // Assert
        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.is_in_shared_pool', true);
    }

    public function test_a_supervisor_with_view_all_sees_everything(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [$mine] = $this->designer();
        [, $supervisor] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ViewAllDesignTickets,
        );
        $customer = $this->customer();

        $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($customer, ['assigned_designer_id' => $mine->id]),
            $employee,
        )->assertCreated();

        // Act
        $response = $this->getJson('/api/v1/design-tickets', $supervisor);

        // Assert
        $response->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_a_designer_reads_the_customers_name_without_a_grant_on_customers(): void
    {
        // Arrange — the snapshot's whole purpose. `customers.view` opens that customer's orders
        // and money; a designer needs six words on a card.
        [, $employee] = $this->employee();
        [$designerUser, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson(
                '/api/v1/design-tickets',
                $this->payload($customer, ['assigned_designer_id' => $designerUser->id]),
                $employee,
            )->json('data.id'),
        );

        // Act
        $ticketRead = $this->getJson("/api/v1/design-tickets/{$ticket->id}", $designer);
        $customerRead = $this->getJson("/api/v1/customers/{$customer->id}", $designer);

        // Assert
        $ticketRead->assertOk()->assertJsonPath('data.customer_name', 'متجر إكس');
        $customerRead->assertForbidden();
    }

    public function test_a_designer_cannot_raise_or_review_a_ticket(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $customer = $this->customer();

        $ticket = DesignTicket::query()->find(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer), $employee)
                ->json('data.id'),
        );
        $this->ticketAwaitingReview($ticket, $designer);
        $version = $ticket->versions()->sole();

        // Act
        $raised = $this->postJson('/api/v1/design-tickets', $this->payload($customer), $designer);
        $reviewed = $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$version->id}/review",
            ['verdict' => 'approved'],
            $designer,
        );

        // Assert
        $raised->assertForbidden();
        $reviewed->assertForbidden();
    }

    public function test_naming_a_designer_without_the_assign_grant_is_dropped_not_refused(): void
    {
        // Arrange — the field is a preference on an otherwise valid request; refusing the whole
        // ticket would lose the employee's typing over a field they may not even have seen.
        [, $headers] = $this->actor(
            PermissionName::ViewDesignTickets,
            PermissionName::ManageDesignTickets,
        );
        [$designerUser] = $this->designer();
        $customer = $this->customer();

        // Act
        $response = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($customer, ['assigned_designer_id' => $designerUser->id]),
            $headers,
        );

        // Assert — created, and in the pool: every designer is told, and the first to accept
        // takes it.
        $response->assertCreated()
            ->assertJsonPath('data.is_in_shared_pool', true)
            ->assertJsonPath('data.designer', null);
    }

    public function test_a_ticket_cannot_be_raised_against_another_customers_order(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $customer = $this->customer();
        $other = $this->customer();

        $order = Order::factory()->create(['customer_id' => $other->id]);

        // Act
        $response = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($customer, ['order_id' => $order->id]),
            $employee,
        );

        // Assert — otherwise the approved artwork lands on an account the work was never done for.
        $response->assertStatus(422);
        $this->assertSame(0, DesignTicket::query()->count());
    }

    public function test_the_validation_refuses_a_ticket_with_no_customer_and_no_brief(): void
    {
        // Arrange
        [, $employee] = $this->employee();

        // Act
        $response = $this->postJson('/api/v1/design-tickets', [], $employee);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['customer_id', 'title', 'description']);
    }
}
