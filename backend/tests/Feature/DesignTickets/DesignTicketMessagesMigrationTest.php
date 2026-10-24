<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * الترحيل الذي جعل محادثة التذكرة رسائل — وما لا يجوز أن يسقط في الطريق (DESIGN-TICKET-CHAT §٤).
 *
 * **كلُّ ملاحظةٍ حيّة على تذكرة تصميم تصير رسالةً نصية**، بكاتبها ووقتها و«معدّلة» إن كانت،
 * بترتيبها. والمحذوفةُ لا تعود، وملاحظاتُ العميل لا تُلمس، والأصولُ تبقى في جدولها كما هي.
 *
 * `DatabaseMigrations` لا `RefreshDatabase`: هذا الاختبار يشغّل DDL بنفسه.
 *
 * Arrange - Act - Assert.
 */
class DesignTicketMessagesMigrationTest extends TestCase
{
    use DatabaseMigrations;

    /** يرجع حتى يختفي جدول الرسائل، ولا يفترض أنه على خطوةٍ واحدة. */
    private function rollBackToTheSchemaWithOnlyComments(): void
    {
        $mostSteps = count(glob(database_path('migrations/*.php')) ?: []);

        for ($step = 0; $step < $mostSteps; $step++) {
            if (! Schema::hasTable('design_ticket_messages')) {
                return;
            }

            Artisan::call('migrate:rollback', ['--step' => 1]);
        }
    }

    public function test_every_live_note_on_a_ticket_becomes_a_message(): void
    {
        // Arrange
        $this->rollBackToTheSchemaWithOnlyComments();
        $this->assertFalse(Schema::hasTable('design_ticket_messages'));

        $user = fn (string $name, string $phone): int => DB::table('users')->insertGetId([
            'name' => $name, 'email' => "{$phone}@example.test", 'phone' => $phone, 'password' => 'x',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $employee = $user('سالم', '0911111111');
        $designer = $user('هدى', '0922222222');

        $customer = DB::table('customers')->insertGetId([
            'code' => 'C900', 'name' => 'متجر إكس', 'phone' => '0910000000', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $ticket = DB::table('design_tickets')->insertGetId([
            'code' => 'D900', 'customer_id' => $customer, 'customer_name' => 'متجر إكس',
            'title' => 'كيس شحن', 'description' => 'الشعار في المنتصف', 'status' => 'in_progress',
            'requested_by_user_id' => $employee, 'accepted_by_user_id' => $designer, 'accepted_at' => '2026-10-01 09:01:00',
            'created_at' => '2026-10-01 09:00:00', 'updated_at' => '2026-10-01 09:00:00',
        ]);

        $note = fn (string $type, int $owner, int $author, string $body, string $at, array $extra = []): int => DB::table('comments')->insertGetId([
            'commentable_type' => $type, 'commentable_id' => $owner, 'user_id' => $author, 'body' => $body,
            'created_at' => $at, 'updated_at' => $at, ...$extra,
        ]);
        $note('design_ticket', $ticket, $employee, 'الشعار في المرفقات', '2026-10-01 09:05:00');
        $note('design_ticket', $ticket, $designer, 'وصلني', '2026-10-01 09:10:00', ['edited_at' => '2026-10-01 09:12:00']);
        $note('design_ticket', $ticket, $employee, 'كُتبت خطأً', '2026-10-01 09:15:00', ['deleted_at' => '2026-10-01 09:16:00']);
        $note('customer', $customer, $employee, 'لا يردّ إلا على واتساب', '2026-10-01 09:20:00');

        // Act
        Artisan::call('migrate');

        // Assert
        $messages = DB::table('design_ticket_messages')->orderBy('id')->get();
        $this->assertCount(2, $messages);

        $this->assertSame($ticket, (int) $messages[0]->design_ticket_id);
        $this->assertSame($employee, (int) $messages[0]->user_id);
        $this->assertSame('الشعار في المرفقات', $messages[0]->body);
        $this->assertSame('2026-10-01 09:05:00', (string) $messages[0]->created_at);
        $this->assertNull($messages[0]->edited_at);

        $this->assertSame($designer, (int) $messages[1]->user_id);
        $this->assertSame('وصلني', $messages[1]->body);
        $this->assertSame('2026-10-01 09:12:00', (string) $messages[1]->edited_at);
        $this->assertNull($messages[1]->retracted_at);

        // الأصولُ في مكانها، كلُّها.
        $this->assertSame(4, DB::table('comments')->count());
    }

    public function test_rolling_back_loses_nothing_that_was_there_before(): void
    {
        // Arrange
        $this->rollBackToTheSchemaWithOnlyComments();
        Artisan::call('migrate');
        $this->assertTrue(Schema::hasTable('design_ticket_messages'));
        $this->assertTrue(Schema::hasColumn('design_tickets', 'designer_read_message_id'));

        // Act
        $this->rollBackToTheSchemaWithOnlyComments();

        // Assert — يحذف ما أضافه وحده: الجدولين والمؤشّرين.
        $this->assertFalse(Schema::hasTable('design_ticket_message_attachments'));
        $this->assertFalse(Schema::hasColumn('design_tickets', 'requester_read_message_id'));
        $this->assertFalse(Schema::hasColumn('design_tickets', 'designer_read_message_id'));
        $this->assertTrue(Schema::hasTable('comments'));
    }
}
