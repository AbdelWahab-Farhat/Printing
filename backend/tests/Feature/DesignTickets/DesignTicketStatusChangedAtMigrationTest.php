<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use Illuminate\Foundation\Testing\DatabaseMigrations;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

/**
 * The migration that adds `design_tickets.status_changed_at`, and how it dates the tickets that
 * already exist: the latest of `created_at`, `accepted_at`, `completed_at` and the newest audit
 * entry that changed the status.
 *
 * `DatabaseMigrations` rather than `RefreshDatabase`: this test runs DDL itself.
 *
 * Arrange - Act - Assert.
 */
class DesignTicketStatusChangedAtMigrationTest extends TestCase
{
    use DatabaseMigrations;

    private function rollBackToBeforeTheColumn(): void
    {
        $mostSteps = count(glob(database_path('migrations/*.php')) ?: []);

        for ($step = 0; $step < $mostSteps; $step++) {
            if (! Schema::hasColumn('design_tickets', 'status_changed_at')) {
                return;
            }

            Artisan::call('migrate:rollback', ['--step' => 1]);
        }
    }

    private function ticket(int $customer, string $code, array $columns = []): int
    {
        return DB::table('design_tickets')->insertGetId([
            'code' => $code, 'customer_id' => $customer, 'customer_name' => 'متجر إكس',
            'title' => 'كيس شحن', 'description' => 'الشعار في المنتصف', 'status' => 'new',
            'created_at' => '2026-10-01 09:00:00', 'updated_at' => '2026-10-05 09:00:00',
            ...$columns,
        ]);
    }

    /** @param array<string, mixed> $changed */
    private function logged(string $subjectType, int $subjectId, array $changed, string $at): void
    {
        DB::table('activity_log')->insert([
            'log_name' => 'design_ticket', 'description' => 'updated', 'event' => 'updated',
            'subject_type' => $subjectType, 'subject_id' => $subjectId,
            'attribute_changes' => json_encode(['attributes' => $changed, 'old' => []]),
            'created_at' => $at, 'updated_at' => $at,
        ]);
    }

    private function stampOf(int $ticket): string
    {
        return (string) DB::table('design_tickets')->where('id', $ticket)->value('status_changed_at');
    }

    public function test_existing_tickets_are_dated_by_their_last_status_change(): void
    {
        // Arrange
        $this->rollBackToBeforeTheColumn();
        $this->assertFalse(Schema::hasColumn('design_tickets', 'status_changed_at'));

        $designer = DB::table('users')->insertGetId([
            'name' => 'هدى', 'email' => '0922222222@example.test', 'phone' => '0922222222', 'password' => 'x',
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $customer = DB::table('customers')->insertGetId([
            'code' => 'C900', 'name' => 'متجر إكس', 'phone' => '0910000000', 'is_active' => true,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $accepted = ['status' => 'in_progress', 'accepted_by_user_id' => $designer, 'accepted_at' => '2026-10-02 10:00:00'];

        // Untouched since it was raised: its creation.
        $untouched = $this->ticket($customer, 'D901');

        // Taken and later submitted: the audit entry for the submission.
        $submitted = $this->ticket($customer, 'D902', [...$accepted, 'status' => 'under_review']);
        $this->logged('design_ticket', $submitted, ['status' => 'under_review'], '2026-10-03 11:00:00');

        // Taken, then only renamed: acceptance, because a rename is not a status change.
        $renamed = $this->ticket($customer, 'D903', $accepted);
        $this->logged('design_ticket', $renamed, ['title' => 'اسم جديد'], '2026-10-04 12:00:00');

        // Another kind of record that happens to share the id must not count.
        $this->logged('design_ticket_file', $untouched, ['status' => 'proposed'], '2026-10-04 13:00:00');

        // Act
        Artisan::call('migrate');

        // Assert
        $this->assertSame('2026-10-01 09:00:00', $this->stampOf($untouched));
        $this->assertSame('2026-10-03 11:00:00', $this->stampOf($submitted));
        $this->assertSame('2026-10-02 10:00:00', $this->stampOf($renamed));
    }
}
