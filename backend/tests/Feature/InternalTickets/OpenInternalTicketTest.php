<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketAttachment;
use App\Domain\InternalTicket\Models\InternalTicketCategory;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\Storage;
use PHPUnit\Framework\Attributes\DataProvider;

/**
 * «تذكرة جديدة»: الحقول، والصور، ومَن يُفتح معه — وورقة «مع مَن؟» وقائمة الأنواع.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class OpenInternalTicketTest extends InternalTicketTestCase
{
    public function test_an_employee_without_any_permission_opens_a_ticket_to_a_colleague(): void
    {
        // Arrange
        [$me, $headers] = $this->employee('سالم');
        [$colleague] = $this->employee('هدى');
        $category = InternalTicketCategory::query()->where('name', 'طلبية')->firstOrFail();

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $colleague->id,
            'title' => 'الطلبية ١٢٢٠ متأخرة',
            'description' => 'هل وصلت الأكياس من المطبعة؟',
            'category_id' => $category->id,
            'priority' => 'high',
        ], $headers);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('status', true)
            ->assertJsonPath('message', 'تم فتح التذكرة')
            ->assertJsonPath('data.status', 'in_progress')
            ->assertJsonPath('data.status_label', 'قيد المعالجة')
            ->assertJsonPath('data.priority', 'high')
            ->assertJsonPath('data.category.name', 'طلبية')
            ->assertJsonPath('data.opener.name', 'سالم')
            ->assertJsonPath('data.assignee.name', 'هدى')
            ->assertJsonPath('data.counterpart.name', 'هدى')
            ->assertJsonPath('data.i_opened_it', true)
            ->assertJsonPath('data.can_reply', true)
            ->assertJsonPath('data.messages.0.body', 'هل وصلت الأكياس من المطبعة؟')
            ->assertJsonPath('data.messages.0.is_mine', true);

        $ticket = InternalTicket::query()->firstOrFail();
        $this->assertSame('TR-'.$ticket->id, $ticket->code);
        $this->assertSame($me->id, $ticket->opened_by);
        // مَن كتب فقد قرأ ما كتب.
        $this->assertSame(InternalTicketMessage::query()->value('id'), $ticket->opener_read_message_id);
        $this->assertNull($ticket->assignee_read_message_id);
    }

    public function test_the_priority_defaults_to_medium(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();

        // Act
        $ticket = $this->open($headers, $colleague);

        // Assert
        $this->assertSame('medium', $ticket->priority->value);
        $this->assertNull($ticket->category_id);
    }

    public function test_up_to_four_photos_ride_on_the_first_message(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();

        // Act
        $ticket = $this->open($headers, $colleague, [
            'images' => [$this->image('a.jpg'), $this->image('b.png'), $this->image('c.jpg'), $this->image('d.jpg')],
        ]);

        // Assert
        $message = InternalTicketMessage::query()->where('internal_ticket_id', $ticket->id)->sole();
        $attachments = InternalTicketAttachment::query()->where('message_id', $message->id)->orderBy('id')->get();
        $this->assertCount(4, $attachments);
        $this->assertSame('image', $attachments[0]->kind->value);
        $this->assertSame(800, $attachments[0]->width_px);
        Storage::disk((string) config('media.internal_ticket_attachments.disk'))->assertExists($attachments[0]->path);
        $this->assertStringStartsWith("internal-ticket-attachments/{$ticket->id}/", $attachments[0]->path);
    }

    public function test_a_fifth_photo_is_refused(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $colleague->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
            'images' => array_map(fn (int $i) => $this->image("{$i}.jpg"), range(1, 5)),
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['images']);
        $this->assertSame(0, InternalTicket::query()->count());
    }

    public function test_a_voice_note_cannot_be_attached_to_the_form(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $colleague->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
            'images' => [$this->voice()],
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['images.0']);
    }

    public function test_a_ticket_cannot_be_opened_with_myself(): void
    {
        // Arrange
        [$me, $headers] = $this->employee();

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $me->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
        ], $headers);

        // Assert
        $response->assertUnprocessable()
            ->assertJsonPath('errors.assignee_id.0', 'لا تُفتح تذكرة مع نفسك');
    }

    public function test_a_ticket_cannot_be_opened_with_a_deactivated_colleague(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        $gone = User::factory()->create(['is_active' => false]);

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $gone->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['assignee_id']);
    }

    public function test_an_inactive_category_cannot_be_chosen(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();
        $retired = InternalTicketCategory::factory()->inactive()->create();

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $colleague->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
            'category_id' => $retired->id,
        ], $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors(['category_id']);
    }

    /**
     * @return array<string, array{0: array<string, mixed>, 1: string}>
     */
    public static function invalidFields(): array
    {
        return [
            'no title' => [['title' => ''], 'title'],
            'title too long' => [['title' => str_repeat('ع', 256)], 'title'],
            'no description' => [['description' => ''], 'description'],
            'description too short' => [['description' => 'هل'], 'description'],
            'unknown priority' => [['priority' => 'urgent'], 'priority'],
            'unknown customer' => [['customer_id' => 999999], 'customer_id'],
            'unknown order' => [['order_id' => 999999], 'order_id'],
        ];
    }

    /**
     * @param  array<string, mixed>  $override
     */
    #[DataProvider('invalidFields')]
    public function test_each_field_is_validated(array $override, string $field): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', array_merge([
            'assignee_id' => $colleague->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
        ], $override), $headers);

        // Assert
        $response->assertUnprocessable()->assertJsonValidationErrors([$field]);
    }

    public function test_the_ticket_links_a_customer(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        [$colleague] = $this->employee();
        $customer = Customer::factory()->create(['name' => 'متجر الأمل']);

        // Act
        $response = $this->postJson('/api/v1/internal-tickets', [
            'assignee_id' => $colleague->id,
            'title' => 'عنوان',
            'description' => 'تفاصيل كافية',
            'customer_id' => $customer->id,
        ], $headers);

        // Assert
        $response->assertCreated()->assertJsonPath('data.customer.name', 'متجر الأمل');
    }

    public function test_server_assigned_fields_cannot_be_supplied(): void
    {
        // Arrange
        [$me, $headers] = $this->employee();
        [$colleague] = $this->employee();
        [$third] = $this->employee();

        // Act
        $ticket = $this->open($headers, $colleague, [
            'code' => 'TR-1',
            'status' => 'closed',
            'opened_by' => $third->id,
        ]);

        // Assert
        $this->assertSame('TR-'.$ticket->id, $ticket->code);
        $this->assertSame('in_progress', $ticket->status->value);
        $this->assertSame($me->id, $ticket->opened_by);
    }

    public function test_opening_needs_a_token(): void
    {
        // Act
        $response = $this->postJson('/api/v1/internal-tickets', []);

        // Assert
        $response->assertUnauthorized();
    }

    public function test_the_database_refuses_a_ticket_with_one_person(): void
    {
        // Arrange
        $me = User::factory()->create();

        // Assert
        $this->expectException(QueryException::class);

        // Act
        InternalTicket::factory()->between($me, $me)->create();
    }

    // ─────────────────────────── «مع مَن؟» والأنواع ───────────────────────────

    public function test_the_picker_lists_active_colleagues_with_the_busiest_first(): void
    {
        // Arrange
        [$me, $headers] = $this->employee('أنا');
        [$alia] = $this->employee('عالية');
        [$basem, $basemHeaders] = $this->employee('باسم');
        User::factory()->create(['name' => 'معطّل', 'is_active' => false]);
        $this->open($basemHeaders, $me);
        $this->open($headers, $basem);

        // Act
        $response = $this->getJson('/api/v1/internal-tickets/colleagues', $headers);

        // Assert
        $response->assertOk();
        $names = array_column($response->json('data'), 'name');
        $this->assertSame(['باسم', 'عالية'], $names);
        $this->assertSame(2, $response->json('data.0.open_tickets_with_me'));
        $this->assertSame(0, $response->json('data.1.open_tickets_with_me'));
        $this->assertNotContains('أنا', $names);
        $this->assertSame($alia->id, $response->json('data.1.id'));
    }

    public function test_the_categories_are_the_seeded_active_ones_in_order(): void
    {
        // Arrange
        [, $headers] = $this->employee();
        InternalTicketCategory::factory()->inactive()->create(['name' => 'موقوف']);

        // Act
        $response = $this->getJson('/api/v1/internal-tickets/categories', $headers);

        // Assert
        $response->assertOk();
        $this->assertSame(
            ['طلبية', 'طباعة وإنتاج', 'مخزون', 'حسابات ومدفوعات', 'توصيل', 'أخرى'],
            array_column($response->json('data'), 'name'),
        );
    }
}
