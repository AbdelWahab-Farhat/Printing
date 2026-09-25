<?php

declare(strict_types=1);

namespace Tests\Feature\Support;

use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * الترحيل الذي جعل مؤشّر القراءة رقمَ رسالة — وما يجب ألا يتغيّر في الطريق.
 *
 * **كل تذكرةٍ تخرج منه بالمقروء نفسه الذي دخلت به.** المؤشّر القديم ساعةٌ: ما كُتب حتى تلك
 * الساعة مقروء، وما بعدها لا. فالمؤشّر الجديد يُملأ بآخر رسالةٍ كُتبت حتى تلك الساعة — لا
 * بآخر رسالةٍ في الخيط، وإلا صار ردٌّ لم يُقرأ مقروءاً، وانطفأت شارته عند العميل بلا سبب.
 *
 * `DatabaseMigrations` لا `RefreshDatabase`: هذا الاختبار يشغّل DDL بنفسه.
 *
 * Arrange - Act - Assert.
 */
class ReadMarksMigrationTest extends TestCase
{
    use DatabaseMigrations;

    /** يرجع حتى يعود المؤشّر ساعةً وحدها، ولا يفترض أنه على خطوةٍ واحدة. */
    private function rollBackToTheSchemaWithOnlyReadTimes(): void
    {
        $mostSteps = count(glob(database_path('migrations/*.php')) ?: []);

        for ($step = 0; $step < $mostSteps; $step++) {
            if (! Schema::hasColumn('support_tickets', 'customer_read_message_id')) {
                return;
            }

            Artisan::call('migrate:rollback', ['--step' => 1]);
        }
    }

    public function test_each_side_keeps_exactly_what_it_had_read(): void
    {
        // Arrange — تذكرةٌ فيها ثلاث رسائل: العميل قرأ حتى الثانية، والمحل حتى الأولى.
        $this->rollBackToTheSchemaWithOnlyReadTimes();
        $this->assertFalse(Schema::hasColumn('support_tickets', 'customer_read_message_id'));

        $customerId = DB::table('customers')->insertGetId([
            'code' => 'C-1', 'name' => 'عميل', 'phone' => '0911111111',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $userId = DB::table('users')->insertGetId([
            'name' => 'موظف', 'email' => 'm@example.com', 'phone' => '0922222222', 'password' => 'x',
            'created_at' => now(), 'updated_at' => now(),
        ]);

        $ticketId = DB::table('support_tickets')->insertGetId([
            'customer_id' => $customerId,
            'subject' => 'سؤال',
            'status' => 'open',
            'customer_read_at' => '2026-09-20 10:05:00',
            'staff_read_at' => '2026-09-20 10:01:00',
            'created_at' => '2026-09-20 10:00:00',
            'updated_at' => '2026-09-20 10:00:00',
        ]);

        $message = fn (array $author, string $at): int => DB::table('ticket_messages')->insertGetId([
            'support_ticket_id' => $ticketId,
            'body' => 'رسالة',
            'created_at' => $at,
            'updated_at' => $at,
            ...$author,
        ]);

        $first = $message(['customer_id' => $customerId], '2026-09-20 10:00:00');
        $second = $message(['user_id' => $userId], '2026-09-20 10:04:00');
        $message(['user_id' => $userId], '2026-09-20 10:09:00');

        $neverRead = DB::table('support_tickets')->insertGetId([
            'customer_id' => $customerId,
            'subject' => 'لم يُفتح',
            'status' => 'open',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Act
        Artisan::call('migrate');

        // Assert
        $ticket = DB::table('support_tickets')->find($ticketId);
        $this->assertSame($second, (int) $ticket->customer_read_message_id);
        $this->assertSame($first, (int) $ticket->staff_read_message_id);

        $untouched = DB::table('support_tickets')->find($neverRead);
        $this->assertNull($untouched->customer_read_message_id);
        $this->assertNull($untouched->staff_read_message_id);
    }
}
