<?php

declare(strict_types=1);

namespace Tests\Feature\InternalTickets;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Enums\RoleName;
use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Notification\DTOs\RenderedNotification;
use App\Domain\Notification\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Testing\File;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Testing\TestResponse;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

/**
 * ما يحتاجه كلُّ اختبارٍ للتذاكر الداخلية: موظفون بلا صلاحية، ومدير، وتذكرةٌ مفتوحة عبر المسار.
 *
 * **الموظفون بلا أيّ صلاحية عمداً**: التذاكر الداخلية لا تطلب صلاحية، كبريمولا — واختبارٌ يمنح
 * صلاحياتٍ كان سيخفي يوم يتسلّل `can:` إلى أحد المسارات.
 */
abstract class InternalTicketTestCase extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (PermissionName::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        Storage::fake((string) config('media.internal_ticket_attachments.disk'));
    }

    /**
     * موظفٌ عاديّ بلا صلاحيات، ورأسُ طلبٍ برمزٍ حقيقيّ (RULES §٦).
     *
     * @return array{0: User, 1: array<string, string>}
     */
    protected function employee(string $name = 'موظف'): array
    {
        $user = User::factory()->create(['name' => $name]);

        return [$user, $this->headersOf($user)];
    }

    /**
     * @return array{0: User, 1: array<string, string>}
     */
    protected function admin(): array
    {
        $user = User::factory()->create(['name' => 'المدير']);
        Role::findOrCreate(RoleName::Admin->value, 'web');
        $user->syncRoles([RoleName::Admin->value]);

        return [$user, $this->headersOf($user)];
    }

    /**
     * @return array<string, string>
     */
    protected function headersOf(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    /**
     * يفتح تذكرةً عبر المسار — فتولد كما يولدها الإنتاج: كودٌ، وأولى رسائلها، ومؤشّرُ صاحبها.
     *
     * @param  array<string, string>  $openerHeaders
     * @param  array<string, mixed>  $overrides
     */
    protected function open(array $openerHeaders, User $assignee, array $overrides = []): InternalTicket
    {
        $response = $this->postJson('/api/v1/internal-tickets', array_merge([
            'assignee_id' => $assignee->id,
            'title' => 'الطلبية ١٢٢٠ متأخرة',
            'description' => 'هل وصلت الأكياس من المطبعة؟',
        ], $overrides), $openerHeaders);

        $response->assertCreated();

        return InternalTicket::query()->findOrFail((int) $response->json('data.id'));
    }

    /**
     * @param  array<string, string>  $headers
     * @param  array<string, mixed>  $payload
     */
    protected function say(InternalTicket $ticket, array $headers, array $payload): TestResponse
    {
        return $this->postJson("/api/v1/internal-tickets/{$ticket->id}/messages", $payload, $headers);
    }

    /** صورةٌ حقيقية، فيقرأ finfo نوعها من بايتاتها. */
    protected function image(string $name = 'shelf.jpg'): File
    {
        return UploadedFile::fake()->image($name, 800, 600);
    }

    /** رسالةٌ صوتية m4a — نوعها `audio/mp4`. */
    protected function voice(int $kilobytes = 60): File
    {
        return UploadedFile::fake()->create('voice.m4a', $kilobytes);
    }

    /** الجرسُ كما يُقرأ: الصفُّ يحفظ الحمولة، والنصُّ يُرسم منها ساعةَ العرض. */
    protected function rendered(Notification $notification): RenderedNotification
    {
        return app($notification->type->definition())->render($notification->payload);
    }
}
