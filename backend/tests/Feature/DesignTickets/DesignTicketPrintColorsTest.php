<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use Illuminate\Http\UploadedFile;

/**
 * «ألوان الطباعة» through a design ticket — PRINT-COLORS.md.
 *
 * The brief asks for colors, the designer says what each version was drawn in, and the approved
 * version's colors land in the customer's library with the file.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignTicketPrintColorsTest extends DesignTicketTestCase
{
    private const RED = ['name' => 'أحمر الشعار', 'code' => 'PANTONE 186 C', 'hex' => '#E4002B'];

    private const BLUE = ['name' => 'أزرق', 'code' => 'PANTONE 286 C', 'hex' => '#0033A0'];

    /**
     * A ticket raised by [$employee] and taken by [$designer], ready for a version.
     *
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     * @param  array<string, mixed>  $overrides
     */
    private function acceptedTicket(array $employee, array $designer, array $overrides = []): DesignTicket
    {
        $ticket = DesignTicket::query()->findOrFail(
            $this->postJson('/api/v1/design-tickets', $this->payload($this->customer(), $overrides), $employee)
                ->assertCreated()
                ->json('data.id'),
        );

        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        return $ticket;
    }

    /**
     * @param  array<string, string>  $designer
     * @param  array<string, mixed>  $extra
     */
    private function submit(DesignTicket $ticket, array $designer, array $extra = [], ?UploadedFile $file = null): int
    {
        return (int) $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            ['file' => $file ?? $this->image('v1.png')] + $extra,
            $designer + ['Accept' => 'application/json'],
        )->assertCreated()->json('data.id');
    }

    /**
     * @param  array<string, string>  $employee
     */
    private function approve(DesignTicket $ticket, int $versionId, array $employee): void
    {
        $this->postJson(
            "/api/v1/design-tickets/{$ticket->id}/versions/{$versionId}/review",
            ['verdict' => DesignSubmissionStatus::Approved->value],
            $employee,
        )->assertOk();
    }

    public function test_the_brief_carries_the_colors_the_customer_asked_for(): void
    {
        // Arrange
        [, $headers] = $this->employee();

        // Act
        $response = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), ['print_colors' => [self::RED]]),
            $headers,
        );

        // Assert
        $response->assertCreated()->assertJsonPath('data.print_colors', [self::RED]);
    }

    public function test_the_colors_travel_in_a_multipart_brief_with_attachments(): void
    {
        // Arrange
        [, $headers] = $this->employee();

        // Act — the same body the app sends when the brief has files.
        $response = $this->post(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), [
                'print_colors' => [self::RED],
                'files' => [$this->image('logo.png')],
            ]),
            $headers + ['Accept' => 'application/json'],
        );

        // Assert
        $response->assertCreated()->assertJsonPath('data.print_colors', [self::RED]);
    }

    public function test_editing_the_brief_without_colors_keeps_them(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $id = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), ['print_colors' => [self::RED]]),
            $headers,
        )->json('data.id');

        // Act — an app that predates the field sends the PUT without it.
        $response = $this->putJson(
            "/api/v1/design-tickets/{$id}",
            ['title' => 'عنوان آخر', 'description' => 'وصف آخر'],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.print_colors', [self::RED]);
    }

    public function test_editing_the_brief_can_change_the_colors(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $id = $this->postJson(
            '/api/v1/design-tickets',
            $this->payload($this->customer(), ['print_colors' => [self::RED]]),
            $headers,
        )->json('data.id');

        // Act
        $response = $this->putJson(
            "/api/v1/design-tickets/{$id}",
            ['title' => 'عنوان', 'description' => 'وصف', 'print_colors' => [self::BLUE]],
            $headers,
        );

        // Assert
        $response->assertOk()->assertJsonPath('data.print_colors', [self::BLUE]);
    }

    public function test_a_version_carries_the_colors_it_was_drawn_in(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->acceptedTicket($employee, $designer, ['print_colors' => [self::RED]]);

        // Act
        $versionId = $this->submit($ticket, $designer, ['print_colors' => [self::BLUE]]);

        // Assert — and the ticket's own request is left as it was asked.
        $this->assertSame([self::BLUE], DesignTicketFile::query()->findOrFail($versionId)->print_colors);
        $this->assertSame([self::RED], $ticket->fresh()->print_colors);
    }

    public function test_approval_puts_the_versions_colors_on_the_customers_design(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->acceptedTicket($employee, $designer, ['print_colors' => [self::RED]]);
        $versionId = $this->submit($ticket, $designer, ['print_colors' => [self::BLUE]]);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert — what the designer said they drew, not what was first asked for.
        $this->assertSame([self::BLUE], CustomerDesign::query()->sole()->print_colors);
    }

    public function test_a_version_sent_without_colors_falls_back_to_the_brief(): void
    {
        // Arrange — a designer on an app that predates the field.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->acceptedTicket($employee, $designer, ['print_colors' => [self::RED]]);
        $versionId = $this->submit($ticket, $designer);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame([self::RED], CustomerDesign::query()->sole()->print_colors);
    }

    public function test_approving_a_file_already_in_the_library_fills_empty_colors_and_reaches_open_orders(): void
    {
        // Arrange — the same file uploaded by hand last week, with no colors, already on an order.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->acceptedTicket($employee, $designer);
        $file = $this->image('same.png');
        $existing = CustomerDesign::factory()->for($ticket->customer)->create([
            'checksum' => hash_file('sha256', $file->getRealPath()),
            'print_colors' => null,
        ]);
        $order = Order::factory()->forCustomer($ticket->customer)->status(OrderStatus::New)->create();
        $version = OrderDesign::factory()->create([
            'order_id' => $order->id,
            'customer_design_id' => $existing->id,
            'print_colors' => null,
        ]);
        $versionId = $this->submit($ticket, $designer, ['print_colors' => [self::RED]], $file);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame([self::RED], $existing->fresh()->print_colors);
        $this->assertSame([self::RED], $version->fresh()->print_colors);
    }

    public function test_approving_a_file_already_in_the_library_never_overwrites_its_colors(): void
    {
        // Arrange — somebody already wrote the colors against this exact file.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->acceptedTicket($employee, $designer);
        $file = $this->image('same.png');
        $existing = CustomerDesign::factory()->for($ticket->customer)->create([
            'checksum' => hash_file('sha256', $file->getRealPath()),
            'print_colors' => [self::RED],
        ]);
        $versionId = $this->submit($ticket, $designer, ['print_colors' => [self::BLUE]], $file);

        // Act
        $this->approve($ticket, $versionId, $employee);

        // Assert
        $this->assertSame([self::RED], $existing->fresh()->print_colors);
    }
}
