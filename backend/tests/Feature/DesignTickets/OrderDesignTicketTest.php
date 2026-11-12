<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Actions\AttachApprovedTicketDesigns;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use Illuminate\Testing\TestResponse;

/**
 * «تصميم طلبية» — a design ticket opened from an order (PRINT-COLORS.md §10), whose approval
 * puts the design on the order as «معتمد» (§11).
 *
 * Arrange - Act - Assert throughout.
 */
class OrderDesignTicketTest extends DesignTicketTestCase
{
    private const BLACK = ['name' => 'أسود', 'code' => null, 'hex' => '#000000'];

    private const GOLD = ['name' => 'ذهبي', 'code' => null, 'hex' => '#C9A227'];

    private function orderFor(Customer $customer, OrderStatus $status = OrderStatus::ReadyToPrint, OrderFlow $flow = OrderFlow::Standard): Order
    {
        return Order::factory()->forCustomer($customer)->status($status)->create([
            'production_flow' => $flow,
            'stock_deducted_at' => now(),
        ]);
    }

    /**
     * @param  array<string, string>  $employee
     * @param  array<string, mixed>  $overrides
     */
    private function raise(Order $order, array $employee, array $overrides = []): TestResponse
    {
        return $this->postJson(
            '/api/v1/design-tickets',
            $this->payload(Customer::query()->findOrFail($order->customer_id), array_merge([
                'order_id' => $order->id,
                'print_colors' => [self::BLACK],
            ], $overrides)),
            $employee,
        );
    }

    /**
     * Raised, taken, a version submitted in [$colors] — and its id.
     *
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     * @param  list<array<string, mixed>>  $colors
     * @return array{DesignTicket, int}
     */
    private function versionFor(Order $order, array $employee, array $designer, array $colors): array
    {
        $ticket = DesignTicket::query()->findOrFail($this->raise($order, $employee)->assertCreated()->json('data.id'));
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        $versionId = (int) $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v1.png'), 'print_colors' => $colors],
            $designer + ['Accept' => 'application/json'],
        )->assertCreated()->json('data.id');

        return [$ticket, $versionId];
    }

    /**
     * @param  array<string, string>  $employee
     */
    private function approve(DesignTicket $ticket, int $versionId, array $employee): TestResponse
    {
        return $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$versionId}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        );
    }

    /**
     * @return array<string, string>
     */
    private function foreman(): array
    {
        return $this->actor(...PermissionName::cases())[1];
    }

    private function move(Order $order, OrderStatus $to): TestResponse
    {
        return $this->postJson("/api/v1/orders/{$order->id}/status", ['status' => $to->value], $this->foreman());
    }

    // ───────────────────────────── raising one ─────────────────────────────

    public function test_a_ticket_raised_from_an_order_is_linked_to_it_and_says_its_colours_are_required(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $order = $this->orderFor($this->customer());

        // Act
        $response = $this->raise($order, $employee);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.order_id', $order->id)
            ->assertJsonPath('data.print_colors_required', true);
    }

    public function test_a_print_order_ticket_needs_its_colours(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $order = $this->orderFor($this->customer());

        // Act — a name without its swatch.
        $response = $this->raise($order, $employee, ['print_colors' => [['name' => 'أزرق']]]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
        $this->assertDatabaseCount('design_tickets', 0);
    }

    public function test_an_outsourced_order_ticket_may_leave_the_colours_to_the_designer(): void
    {
        // Arrange — the vendor prints from the file.
        [, $employee] = $this->employee();
        $order = $this->orderFor($this->customer(), OrderStatus::New, OrderFlow::Outsourced);

        // Act
        $response = $this->raise($order, $employee, ['print_colors' => []]);

        // Assert
        $response->assertCreated()->assertJsonPath('data.print_colors_required', false);
    }

    public function test_an_order_already_at_the_press_takes_no_ticket(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $order = $this->orderFor($this->customer(), OrderStatus::Printing);

        // Act
        $response = $this->raise($order, $employee);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('order_id');
    }

    public function test_a_version_for_a_print_order_needs_its_colours(): void
    {
        // Arrange — a brief left with colours, a version sent with a bare name.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $ticket = DesignTicket::query()->findOrFail($this->raise($order, $employee)->json('data.id'));
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        // Act
        $response = $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v1.png'), 'print_colors' => [['name' => 'أزرق']]],
            $designer + ['Accept' => 'application/json'],
        );

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('print_colors');
    }

    // ───────────────────────────── the press gate ─────────────────────────────

    public function test_the_order_cannot_reach_the_press_while_its_ticket_is_open(): void
    {
        // Arrange — the order has a coloured version already; the ticket is the reason to wait.
        [, $employee] = $this->employee();
        $order = $this->orderFor($this->customer());
        $code = $this->raise($order, $employee)->json('data.code');
        OrderDesign::factory()->create([
            'order_id' => $order->id,
            'status' => OrderDesignStatus::Approved,
            'print_colors' => [self::BLACK],
        ]);

        // Act
        $response = $this->move($order, OrderStatus::Printing);

        // Assert — the message names the ticket.
        $response->assertStatus(422)->assertJsonValidationErrors('design_ticket');
        $this->assertStringContainsString((string) $code, $response->json('message'));
    }

    public function test_a_cancelled_ticket_does_not_hold_the_press(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        $order = $this->orderFor($this->customer());
        $id = $this->raise($order, $employee)->json('data.id');
        // Written directly: cancelling a ticket nobody took 500s today in the progress
        // notification (recipient 0), which is not what this test is about.
        DesignTicket::query()->findOrFail($id)
            ->forceFill(['status' => DesignTicketStatus::Cancelled, 'cancellation_reason' => 'فُتحت بالخطأ'])
            ->save();
        OrderDesign::factory()->create([
            'order_id' => $order->id,
            'status' => OrderDesignStatus::Approved,
            'print_colors' => [self::BLACK],
        ]);

        // Act
        $response = $this->move($order, OrderStatus::Printing);

        // Assert
        $response->assertOk()->assertJsonPath('data.status', 'printing');
    }

    // ───────────────────────────── approval ─────────────────────────────

    public function test_approval_puts_the_design_on_the_order_approved_and_in_the_versions_colours(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->versionFor($order, $employee, $designer, [self::BLACK, self::GOLD]);

        // Act
        $this->approve($ticket, $versionId, $employee)->assertOk();

        // Assert
        $ticket->refresh();
        $version = OrderDesign::query()->where('order_id', $order->id)->sole();
        $this->assertSame((int) $ticket->approved_customer_design_id, (int) $version->customer_design_id);
        $this->assertSame(OrderDesignStatus::Approved, $version->status);
        $this->assertSame([self::BLACK, self::GOLD], $version->print_colors);
    }

    public function test_once_approved_the_order_goes_to_the_press(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->versionFor($order, $employee, $designer, [self::BLACK]);
        $this->approve($ticket, $versionId, $employee)->assertOk();

        // Act
        $response = $this->move($order->fresh(), OrderStatus::Printing);

        // Assert — the ticket closed, and the design it produced carries the colours.
        $response->assertOk()->assertJsonPath('data.status', 'printing');
    }

    public function test_approval_supersedes_a_version_approved_before(): void
    {
        // Arrange — a customer file was approved on the order; our design replaces it.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $earlier = OrderDesign::factory()->create([
            'order_id' => $order->id,
            'version' => 1,
            'status' => OrderDesignStatus::Approved,
            'print_colors' => [self::BLACK],
        ]);
        [$ticket, $versionId] = $this->versionFor($order, $employee, $designer, [self::GOLD]);

        // Act
        $this->approve($ticket, $versionId, $employee)->assertOk();

        // Assert — the order's own rule: one approved version.
        $this->assertSame(OrderDesignStatus::Rejected, $earlier->fresh()->status);
        $this->assertSame([self::GOLD], $order->fresh()->designForPress()?->print_colors);
    }

    public function test_approved_while_the_order_is_short_it_lands_when_the_order_comes_back(): void
    {
        // Arrange — the ticket is raised while the order takes artwork, then the order goes
        // short, which does not; approval happens there.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer(), OrderStatus::New);
        [$ticket, $versionId] = $this->versionFor($order, $employee, $designer, [self::BLACK]);
        $order->forceFill(['status' => OrderStatus::Shortage])->save();

        // Act — approved in «نواقص»: nothing lands yet.
        $this->approve($ticket, $versionId, $employee)->assertOk();
        $this->assertSame(0, OrderDesign::query()->where('order_id', $order->id)->count());

        // Act — the order returns to a status that takes artwork.
        $order->forceFill(['status' => OrderStatus::New, 'stock_deducted_at' => null])->save();
        app(AttachApprovedTicketDesigns::class)($order->fresh());

        // Assert
        $version = OrderDesign::query()->where('order_id', $order->id)->sole();
        $this->assertSame(OrderDesignStatus::Approved, $version->status);
        $this->assertSame([self::BLACK], $version->print_colors);
    }

    public function test_attaching_twice_adds_the_design_once(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        [$ticket, $versionId] = $this->versionFor($order, $employee, $designer, [self::BLACK]);
        $this->approve($ticket, $versionId, $employee)->assertOk();

        // Act
        app(AttachApprovedTicketDesigns::class)($order->fresh());

        // Assert
        $this->assertSame(1, OrderDesign::query()->where('order_id', $order->id)->count());
    }

    public function test_a_ticket_with_no_order_attaches_nothing(): void
    {
        // Arrange — a business card before any order exists.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = DesignTicket::query()->findOrFail(
            $this->postJson('/api/v1/design-tickets', $this->payload($this->customer()), $employee)->json('data.id'),
        );
        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();
        $versionId = (int) $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $this->image('v1.png')],
            $designer + ['Accept' => 'application/json'],
        )->json('data.id');

        // Act
        $response = $this->approve($ticket, $versionId, $employee);

        // Assert
        $response->assertOk();
        $this->assertDatabaseCount('order_designs', 0);
    }
}
