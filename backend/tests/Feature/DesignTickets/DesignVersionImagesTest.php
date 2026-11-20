<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\Customer\Models\CustomerDesign;
use App\Domain\DesignTicket\Enums\DesignSubmissionStatus;
use App\Domain\DesignTicket\Enums\DesignTicketStatus;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketFile;
use App\Domain\DesignTicket\Models\DesignTicketFileFace;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Order\Enums\OrderDesignStatus;
use App\Domain\Order\Enums\OrderFlow;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderDesign;
use Illuminate\Http\Testing\File;
use Illuminate\Http\UploadedFile;
use Illuminate\Testing\TestResponse;

/**
 * A design version is two images or more (DESIGN-VERSION-IMAGES.md, owner 2026-11-20): the
 * designer uploads them together, the employee approves them together, and every one of them
 * lands on the order as one design number.
 *
 * Arrange - Act - Assert throughout.
 */
class DesignVersionImagesTest extends DesignTicketTestCase
{
    private const BLACK = ['name' => 'أسود', 'code' => null, 'hex' => '#000000'];

    private const GOLD = ['name' => 'ذهبي', 'code' => null, 'hex' => '#C9A227'];

    /**
     * [$count] different images: a different size each, so no two share a checksum.
     *
     * @return list<File>
     */
    private function images(int $count): array
    {
        return array_map(
            fn (int $i): File => UploadedFile::fake()->image("face-{$i}.png", 400 + $i, 300),
            range(1, $count),
        );
    }

    /**
     * @return array<string, string>
     */
    private function foreman(): array
    {
        return $this->actor(...PermissionName::cases())[1];
    }

    private function orderFor(Customer $customer): Order
    {
        return Order::factory()->forCustomer($customer)->status(OrderStatus::ReadyToPrint)->create([
            'production_flow' => OrderFlow::Standard,
            'stock_deducted_at' => now(),
        ]);
    }

    /**
     * A ticket on [$order] (or on nobody's order), already taken by [$designer].
     *
     * @param  array<string, string>  $employee
     * @param  array<string, string>  $designer
     */
    private function takenTicket(array $employee, array $designer, ?Order $order = null): DesignTicket
    {
        $customer = $order === null ? $this->customer() : Customer::query()->findOrFail($order->customer_id);
        $overrides = $order === null ? [] : ['order_id' => $order->id, 'print_colors' => [self::BLACK]];

        $ticket = DesignTicket::query()->findOrFail(
            $this->postJson('/api/v1/design-tickets', $this->payload($customer, $overrides), $employee)
                ->assertCreated()
                ->json('data.id'),
        );

        $this->postJson("/api/v1/design-tickets/{$ticket->id}/acceptance", [], $designer)->assertOk();

        return $ticket;
    }

    /**
     * @param  array<string, mixed>  $body
     * @param  array<string, string>  $designer
     */
    private function upload(DesignTicket $ticket, array $body, array $designer): TestResponse
    {
        return $this->post(
            "/api/v1/design-tickets/{$ticket->id}/versions",
            $body,
            $designer + ['Accept' => 'application/json'],
        );
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

    // ───────────────────────────── the upload ─────────────────────────────

    public function test_a_version_of_one_image_is_refused(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->takenTicket($employee, $designer);

        // Act
        $response = $this->upload($ticket, ['files' => $this->images(1)], $designer);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['files' => 'أدخل صورتين على الأقل للتصميم']);
        $this->assertSame(0, DesignTicketFile::query()->count());
    }

    public function test_the_single_file_of_an_older_app_is_refused_with_a_sentence_saying_to_update(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->takenTicket($employee, $designer);

        // Act
        $response = $this->upload($ticket, ['file' => $this->image('v1.png')], $designer);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['file' => 'حدّث التطبيق — التصميم يحتاج صورتين على الأقل']);
    }

    public function test_a_pdf_is_not_one_of_the_images(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->takenTicket($employee, $designer);

        // Act
        $response = $this->upload($ticket, ['files' => [
            $this->image('front.png'),
            UploadedFile::fake()->create('print.pdf', 40, 'application/pdf'),
        ]], $designer);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['files.1' => 'صور التصميم يجب أن تكون JPG أو PNG أو WEBP']);
    }

    public function test_the_same_image_twice_is_refused(): void
    {
        // Arrange — identical dimensions draw identical bytes.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->takenTicket($employee, $designer);

        // Act
        $response = $this->upload($ticket, ['files' => [$this->image('a.png'), $this->image('b.png')]], $designer);

        // Assert
        $response->assertStatus(422)
            ->assertJsonValidationErrors(['files' => 'الصورة نفسها مكرّرة في التصميم']);
    }

    public function test_more_than_six_images_are_refused(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->takenTicket($employee, $designer);

        // Act
        $response = $this->upload($ticket, ['files' => $this->images(7)], $designer);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors('files');
    }

    public function test_three_images_are_one_version_with_three_faces(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $ticket = $this->takenTicket($employee, $designer);

        // Act
        $response = $this->upload($ticket, ['files' => $this->images(3)], $designer);

        // Assert — one version, numbered 1, and its faces in the order they were sent.
        $response->assertCreated()
            ->assertJsonPath('data.version', 1)
            ->assertJsonCount(3, 'data.faces')
            ->assertJsonPath('data.faces.0.position', 1)
            ->assertJsonPath('data.faces.2.position', 3)
            ->assertJsonPath('data.faces.1.original_filename', 'face-2.png');
        $this->assertSame(1, DesignTicketFile::query()->where('kind', 'submission')->count());
        $this->assertSame([2, 3], DesignTicketFileFace::query()->orderBy('position')->pluck('position')->all());

        // And the ticket screen draws them too.
        $this->getJson("/api/v1/design-tickets/{$ticket->id}", $employee)
            ->assertOk()
            ->assertJsonCount(3, 'data.versions.0.faces');
    }

    // ───────────────────────────── the approval ─────────────────────────────

    public function test_approving_puts_every_image_in_the_library_and_on_the_order_as_one_version(): void
    {
        // Arrange
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $ticket = $this->takenTicket($employee, $designer, $order);
        $versionId = (int) $this->upload(
            $ticket,
            ['files' => $this->images(3), 'print_colors' => [self::GOLD]],
            $designer,
        )->assertCreated()->json('data.id');

        // Act
        $this->approve($ticket, $versionId, $employee)->assertOk();

        // Assert — three library designs, each named by its face.
        $library = CustomerDesign::query()->orderBy('id')->get();
        $this->assertCount(3, $library);
        $this->assertSame((int) $ticket->refresh()->approved_customer_design_id, $library[0]->id);
        $this->assertSame(
            $library->pluck('id')->slice(1)->values()->all(),
            DesignTicketFileFace::query()->orderBy('position')->pluck('customer_design_id')->all(),
        );

        // Assert — one design number on the order, three faces, approved and in the version's
        // colours.
        $faces = OrderDesign::query()->where('order_id', $order->id)->orderBy('face')->get();
        $this->assertSame([1, 2, 3], $faces->pluck('face')->all());
        $this->assertCount(1, $faces->pluck('version')->unique());
        $this->assertSame($library->pluck('id')->all(), $faces->pluck('customer_design_id')->all());

        foreach ($faces as $face) {
            $this->assertSame(OrderDesignStatus::Approved, $face->status);
            $this->assertSame([self::GOLD], $face->print_colors);
        }

        // And the order says so, face by face.
        $sent = $this->getJson("/api/v1/orders/{$order->id}", $this->foreman())
            ->assertOk()
            ->assertJsonCount(3, 'data.designs');
        $this->assertEqualsCanonicalizing([1, 2, 3], $sent->json('data.designs.*.face'));
    }

    public function test_a_newer_approved_version_rejects_every_image_of_the_older_one(): void
    {
        // Arrange — two faces of version 1, approved together.
        $order = $this->orderFor($this->customer());
        foreach ([1, 2] as $face) {
            OrderDesign::factory()->create([
                'order_id' => $order->id,
                'version' => 1,
                'face' => $face,
                'status' => OrderDesignStatus::Approved,
                'print_colors' => [self::BLACK],
            ]);
        }
        $newer = OrderDesign::factory()->create([
            'order_id' => $order->id,
            'version' => 2,
            'face' => 1,
            'status' => OrderDesignStatus::Proposed,
            'print_colors' => [self::GOLD],
        ]);

        // Act
        $this->postJson(
            "/api/v1/orders/{$order->id}/designs/{$newer->id}/review",
            ['status' => OrderDesignStatus::Approved->value],
            $this->foreman(),
        )->assertOk();

        // Assert
        $this->assertSame(
            [OrderDesignStatus::Rejected, OrderDesignStatus::Rejected],
            OrderDesign::query()->where('version', 1)->orderBy('face')->pluck('status')->all(),
        );
        $this->assertSame(OrderDesignStatus::Approved, $newer->fresh()->status);
    }

    public function test_approving_one_image_by_hand_approves_the_whole_version(): void
    {
        // Arrange
        $order = $this->orderFor($this->customer());
        $faces = collect([1, 2])->map(fn (int $face) => OrderDesign::factory()->create([
            'order_id' => $order->id,
            'version' => 1,
            'face' => $face,
            'status' => OrderDesignStatus::Proposed,
            'print_colors' => [self::BLACK],
        ]));

        // Act — the second face, not the first.
        $this->postJson(
            "/api/v1/orders/{$order->id}/designs/{$faces[1]->id}/review",
            ['status' => OrderDesignStatus::Approved->value],
            $this->foreman(),
        )->assertOk();

        // Assert
        $this->assertSame(OrderDesignStatus::Approved, $faces[0]->fresh()->status);
        $this->assertSame(OrderDesignStatus::Approved, $faces[1]->fresh()->status);
    }

    public function test_a_one_file_version_from_before_the_change_is_still_approved(): void
    {
        // Arrange — a version written before faces existed: one row, no faces.
        [, $employee] = $this->employee();
        [, $designer] = $this->designer();
        $order = $this->orderFor($this->customer());
        $ticket = $this->takenTicket($employee, $designer, $order);
        $version = DesignTicketFile::factory()->submission()->create([
            'design_ticket_id' => $ticket->id,
            'print_colors' => [self::BLACK],
        ]);
        $ticket->forceFill(['status' => DesignTicketStatus::UnderReview])->save();

        // Act
        $this->approve($ticket, (int) $version->id, $employee)->assertOk();

        // Assert — one design on the order, as before.
        $face = OrderDesign::query()->where('order_id', $order->id)->sole();
        $this->assertSame(1, $face->face);
        $this->assertSame(OrderDesignStatus::Approved, $face->status);
    }

    // ───────────────────────────── the press ─────────────────────────────

    public function test_the_press_checks_the_colours_of_every_image(): void
    {
        // Arrange — face 2 of the approved version has no colours.
        $order = $this->orderFor($this->customer());
        OrderDesign::factory()->create([
            'order_id' => $order->id, 'version' => 1, 'face' => 1,
            'status' => OrderDesignStatus::Approved, 'print_colors' => [self::BLACK],
        ]);
        OrderDesign::factory()->create([
            'order_id' => $order->id, 'version' => 1, 'face' => 2,
            'status' => OrderDesignStatus::Approved, 'print_colors' => null,
        ]);

        // Act
        $response = $this->postJson(
            "/api/v1/orders/{$order->id}/status",
            ['status' => OrderStatus::Printing->value],
            $this->foreman(),
        );

        // Assert
        $response->assertStatus(422);
        $this->assertSame(OrderStatus::ReadyToPrint, $order->fresh()->status);
    }

    public function test_correcting_the_colours_of_one_image_corrects_the_whole_version(): void
    {
        // Arrange
        $order = $this->orderFor($this->customer());
        $order->forceFill(['status' => OrderStatus::Designing])->save();
        $faces = collect([1, 2])->map(fn (int $face) => OrderDesign::factory()->create([
            'order_id' => $order->id, 'version' => 1, 'face' => $face,
            'status' => OrderDesignStatus::Approved, 'print_colors' => [self::BLACK],
        ]));

        // Act
        $this->patchJson(
            "/api/v1/orders/{$order->id}/designs/{$faces[0]->id}/colors",
            ['print_colors' => [self::GOLD]],
            $this->foreman(),
        )->assertOk();

        // Assert
        $this->assertSame([self::GOLD], $faces[1]->fresh()->print_colors);
    }
}
