<?php

declare(strict_types=1);

namespace Tests\Feature\DesignTickets;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * The migration that moves addressed, unaccepted tickets from «جديد» to «مُسنَد».
 *
 * The rows are put back into the shape they had before the status existed, then the migration's
 * own `up()` and `down()` are run against them.
 *
 * Arrange - Act - Assert.
 */
class DesignTicketAssignedMigrationTest extends DesignTicketTestCase
{
    private function migration(): Migration
    {
        return require database_path('migrations/2026_11_17_100000_mark_addressed_design_tickets_assigned.php');
    }

    private function statusOf(DesignTicket $ticket): string
    {
        return (string) DB::table('design_tickets')->where('id', $ticket->id)->value('status');
    }

    public function test_it_marks_only_addressed_unaccepted_new_tickets_and_reverses(): void
    {
        // Arrange — the old shape: an addressed ticket that is still «جديد».
        $designer = (int) User::factory()->create()->id;
        $addressed = DesignTicket::factory()->create();
        DB::table('design_tickets')->where('id', $addressed->id)
            ->update(['assigned_designer_id' => $designer, 'status' => 'new']);

        $unaddressed = DesignTicket::factory()->create();
        $taken = DesignTicket::factory()->acceptedBy($designer)->create();
        $cancelled = DesignTicket::factory()->cancelled()->create();
        DB::table('design_tickets')->where('id', $cancelled->id)->update(['assigned_designer_id' => $designer]);
        $stamp = DB::table('design_tickets')->where('id', $addressed->id)->value('status_changed_at');

        // Act
        $this->migration()->up();

        // Assert
        $this->assertSame('assigned', $this->statusOf($addressed));
        $this->assertSame('new', $this->statusOf($unaddressed));
        $this->assertSame('in_progress', $this->statusOf($taken));
        $this->assertSame('cancelled', $this->statusOf($cancelled));
        $this->assertSame($stamp, DB::table('design_tickets')->where('id', $addressed->id)->value('status_changed_at'));

        // Act — and back.
        $this->migration()->down();

        // Assert
        $this->assertSame('new', $this->statusOf($addressed));
        $this->assertSame('in_progress', $this->statusOf($taken));
    }
}
