<?php

declare(strict_types=1);

namespace Tests\Feature\Api\V1\Client;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Support\Models\SupportTicket;
use App\Domain\Support\Models\TicketMessage;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Tests\TestCase;

/**
 * مرفقات المحادثة — صورةٌ أو PDF، ملفٌّ واحد في كل رسالة.
 *
 * **ثلاثة أشياء تُحرس هنا.** أن الملف يُعرف من بايتاته لا من اسمه (فلا SVG ولا ما يتنكّر في
 * امتداد صورة). وأنه يُحفظ على القرص الخاص باسمٍ يولّده الخادم، فلا يختار أحدٌ مساراً. وأن
 * الرسالة تقول شيئاً دائماً: كلاماً أو ملفاً أو كليهما — وقاعدة البيانات تقولها أيضاً.
 *
 * **ورمزُ العميل (`client_token`) يجعل الإعادة آمنة.** اتصالٌ انقطع بعد أن حُفظت الرسالة يترك
 * التطبيق لا يعرف هل وصلت، فيعيد — والإعادة بالرمز نفسه تُرجع الرسالة نفسها بدل نسخةٍ ثانية.
 *
 * Arrange - Act - Assert في كل حالة.
 */
class SupportAttachmentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake((string) config('media.ticket_attachments.disk'));

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }
    }

    private function customer(): Customer
    {
        return Customer::factory()->registered()->create();
    }

    /**
     * @return array<string, string>
     */
    private function bearerFor(Customer $customer): array
    {
        return ['Authorization' => 'Bearer '.$customer->createToken('app')->plainTextToken];
    }

    /**
     * @return array<string, string>
     */
    private function desk(): array
    {
        $user = User::factory()->create();
        $user->givePermissionTo([
            PermissionName::ViewSupportTickets->value,
            PermissionName::ManageSupportTickets->value,
        ]);

        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function pdf(string $name = 'design.pdf', int $kilobytes = 20): UploadedFile
    {
        // ترويسة %PDF حقيقية: التحقق يقرأ البايتات لا الاسم.
        return UploadedFile::fake()->createWithContent($name, "%PDF-1.4\n".str_repeat('a', $kilobytes * 1024));
    }

    private function replyAsCustomer(Customer $customer, SupportTicket $ticket, array $payload): TestResponse
    {
        return $this->withHeaders($this->bearerFor($customer))->post(
            "/api/v1/client/support/tickets/{$ticket->id}/messages",
            $payload,
            ['Accept' => 'application/json'],
        );
    }

    // ─────────────────────────── ما يُرسَل ───────────────────────────

    public function test_a_customer_sends_a_photo_with_no_words(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->replyAsCustomer($me, $ticket, [
            'file' => UploadedFile::fake()->image('receipt.jpg', 800, 600),
        ]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.0.from', 'me')
            ->assertJsonPath('data.messages.0.body', null)
            ->assertJsonPath('data.messages.0.attachment.kind', 'image')
            ->assertJsonPath('data.messages.0.attachment.name', 'receipt.jpg')
            ->assertJsonPath('data.messages.0.attachment.mime_type', 'image/jpeg')
            ->assertJsonPath('data.messages.0.attachment.width_px', 800)
            ->assertJsonPath('data.messages.0.attachment.height_px', 600);

        $this->assertNotEmpty($response->json('data.messages.0.attachment.url'));
        $this->assertGreaterThan(0, $response->json('data.messages.0.attachment.size_bytes'));
    }

    public function test_a_customer_sends_a_pdf_with_a_caption(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->replyAsCustomer($me, $ticket, [
            'body' => 'هذا التصميم النهائي',
            'file' => $this->pdf('final-design.pdf'),
        ]);

        // Assert — لا أبعاد لملف PDF: له صفحات لا بكسلات.
        $response->assertCreated()
            ->assertJsonPath('data.messages.0.body', 'هذا التصميم النهائي')
            ->assertJsonPath('data.messages.0.attachment.kind', 'pdf')
            ->assertJsonPath('data.messages.0.attachment.kind_label', 'PDF')
            ->assertJsonPath('data.messages.0.attachment.name', 'final-design.pdf')
            ->assertJsonPath('data.messages.0.attachment.width_px', null);
    }

    public function test_a_message_without_a_file_carries_no_attachment(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->replyAsCustomer($me, $ticket, ['body' => 'مرحباً']);

        // Assert
        $response->assertCreated()->assertJsonPath('data.messages.0.attachment', null);
    }

    public function test_a_reply_needs_words_or_a_file(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->replyAsCustomer($me, $ticket, ['body' => '']);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['body']);
        $this->assertSame(0, TicketMessage::query()->count());
    }

    /** SVG مستندُ HTML، ومستندٌ يُقدَّم من نطاقنا هو XSS مخزَّن. */
    public function test_an_svg_is_refused(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $svg = UploadedFile::fake()->createWithContent(
            'logo.svg',
            '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>',
        );

        // Act
        $response = $this->replyAsCustomer($me, $ticket, ['file' => $svg]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
    }

    /** الاسم لا يقرر شيئاً: ملفُّ PDF سُمّي `.jpg` يُعرف من بايتاته ويُحفظ على أنه PDF. */
    public function test_the_kind_is_read_from_the_bytes_not_the_name(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $path = tempnam(sys_get_temp_dir(), 'att');
        file_put_contents($path, "%PDF-1.4\n".str_repeat('a', 1024));
        $disguised = new UploadedFile($path, 'photo.jpg', null, null, true);

        // Act
        $response = $this->replyAsCustomer($me, $ticket, ['file' => $disguised]);

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.0.attachment.kind', 'pdf')
            ->assertJsonPath('data.messages.0.attachment.mime_type', 'application/pdf');
    }

    public function test_a_file_over_the_limit_is_refused(): void
    {
        // Arrange
        config(['media.ticket_attachments.max_kilobytes' => 10]);
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $response = $this->replyAsCustomer($me, $ticket, ['file' => $this->pdf(kilobytes: 40)]);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['file']);
    }

    /** اسمٌ يولّده الخادم: عميلان يرسلان «logo.pdf» لا يتصادمان، ولا يختار أحدٌ مساراً. */
    public function test_the_file_is_kept_on_the_private_disk_under_a_generated_name(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Act
        $this->replyAsCustomer($me, $ticket, ['file' => $this->pdf('logo.pdf')])->assertCreated();

        // Assert
        $message = TicketMessage::query()->latest('id')->firstOrFail();
        $this->assertSame(config('media.ticket_attachments.disk'), $message->attachment_disk);
        $this->assertStringStartsWith("ticket-attachments/{$ticket->id}/", (string) $message->attachment_path);
        $this->assertStringNotContainsString('logo', (string) $message->attachment_path);
        Storage::disk((string) $message->attachment_disk)->assertExists((string) $message->attachment_path);
    }

    // ─────────────────────────── الإعادة ───────────────────────────

    public function test_a_retry_with_the_same_token_returns_the_same_message(): void
    {
        // Arrange — أُرسلت، وانقطع الاتصال قبل أن يصل الرد، فيعيد التطبيق بالرمز نفسه.
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $token = (string) Str::uuid();
        $this->replyAsCustomer($me, $ticket, ['body' => 'هل وصلت؟', 'client_token' => $token])
            ->assertCreated();

        // Act
        $retry = $this->replyAsCustomer($me, $ticket, ['body' => 'هل وصلت؟', 'client_token' => $token]);

        // Assert
        $retry->assertCreated()
            ->assertJsonCount(1, 'data.messages')
            ->assertJsonPath('data.messages.0.client_token', $token);
        $this->assertSame(1, TicketMessage::query()->count());
    }

    public function test_a_retried_file_is_stored_once(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $token = (string) Str::uuid();
        $this->replyAsCustomer($me, $ticket, ['file' => $this->pdf(), 'client_token' => $token])
            ->assertCreated();

        // Act
        $this->replyAsCustomer($me, $ticket, ['file' => $this->pdf(), 'client_token' => $token])
            ->assertCreated();

        // Assert — لا صفّ ثانٍ ولا ملفّ ثانٍ على القرص.
        $this->assertSame(1, TicketMessage::query()->count());
        $this->assertCount(
            1,
            Storage::disk((string) config('media.ticket_attachments.disk'))->allFiles("ticket-attachments/{$ticket->id}"),
        );
    }

    /** الرمز يخصّ تذكرته: الرمز نفسه في تذكرةٍ أخرى رسالةٌ أخرى. */
    public function test_the_same_token_in_another_thread_is_another_message(): void
    {
        // Arrange
        $me = $this->customer();
        $first = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $second = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $token = (string) Str::uuid();
        $this->replyAsCustomer($me, $first, ['body' => 'أ', 'client_token' => $token])->assertCreated();

        // Act
        $response = $this->replyAsCustomer($me, $second, ['body' => 'ب', 'client_token' => $token]);

        // Assert
        $response->assertCreated();
        $this->assertSame(2, TicketMessage::query()->count());
    }

    // ─────────────────────────── ما يراه الطرفان ───────────────────────────

    public function test_the_desk_sees_the_customers_file(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $this->replyAsCustomer($me, $ticket, ['file' => $this->pdf('invoice.pdf')])->assertCreated();

        // Act
        $response = $this->withHeaders($this->desk())->getJson("/api/v1/support/tickets/{$ticket->id}");

        // Assert
        $response->assertOk()
            ->assertJsonPath('data.messages.0.attachment.kind', 'pdf')
            ->assertJsonPath('data.messages.0.attachment.name', 'invoice.pdf');
        $this->assertNotEmpty($response->json('data.messages.0.attachment.url'));
    }

    public function test_the_desk_can_send_a_file_too(): void
    {
        // Arrange
        $ticket = SupportTicket::factory()->create(['customer_id' => $this->customer()->id]);

        // Act
        $response = $this->withHeaders($this->desk())->post(
            "/api/v1/support/tickets/{$ticket->id}/messages",
            ['file' => UploadedFile::fake()->image('proof.png', 1200, 900)],
            ['Accept' => 'application/json'],
        );

        // Assert
        $response->assertCreated()
            ->assertJsonPath('data.messages.0.from', 'staff')
            ->assertJsonPath('data.messages.0.attachment.kind', 'image');
    }

    /** سطرُ المعاينة في القائمة يقول شيئاً حتى حين لا كلام: «صورة»، أو اسمُ الملف. */
    public function test_the_list_preview_names_a_file_sent_without_words(): void
    {
        // Arrange
        $me = $this->customer();
        $photo = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $document = SupportTicket::factory()->create(['customer_id' => $me->id]);
        $this->replyAsCustomer($me, $photo, ['file' => UploadedFile::fake()->image('a.jpg')])->assertCreated();
        $this->replyAsCustomer($me, $document, ['file' => $this->pdf('quote.pdf')])->assertCreated();

        // Act
        $response = $this->withHeaders($this->bearerFor($me))->getJson('/api/v1/client/support/tickets');

        // Assert
        $previews = collect($response->assertOk()->json('data'))->pluck('preview', 'id');
        $this->assertSame('صورة', $previews[$photo->id]);
        $this->assertSame('quote.pdf', $previews[$document->id]);
    }

    /** فتحُ تذكرة ما زال يحتاج كلاماً: السؤال الأول يُكتب، والملف يتبعه في المحادثة. */
    public function test_opening_a_ticket_still_needs_words(): void
    {
        // Act
        $response = $this->withHeaders($this->bearerFor($this->customer()))
            ->postJson('/api/v1/client/support/tickets', ['subject' => 'سؤال']);

        // Assert
        $response->assertStatus(422)->assertJsonValidationErrors(['body']);
    }

    /** رسالةٌ لا كلام فيها ولا ملف جملةٌ فارغة — وقاعدة البيانات ترفضها، لا التحقق وحده. */
    public function test_the_database_refuses_a_message_that_says_nothing(): void
    {
        // Arrange
        $me = $this->customer();
        $ticket = SupportTicket::factory()->create(['customer_id' => $me->id]);

        // Assert
        $this->expectException(QueryException::class);

        // Act
        DB::table('ticket_messages')->insert([
            'support_ticket_id' => $ticket->id,
            'customer_id' => $me->id,
            'body' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
