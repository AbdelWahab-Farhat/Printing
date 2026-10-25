<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\InternalTicket\Actions\CloseSilentInternalTickets;
use Illuminate\Console\Command;

/**
 * يُغلق التذاكر الداخلية التي لم يكتب فيها أحدُ الطرفين `internal_tickets.close_after_silence.days`
 * يوماً — كل ساعة. نداءٌ لا يجد ما يغلقه لا يكتب شيئاً. السياسةُ في config/internal_tickets.php.
 */
class CloseSilentInternalTicketsCommand extends Command
{
    protected $signature = 'internal-tickets:close-silent';

    protected $description = 'يغلق التذاكر الداخلية التي لم يردّ فيها أحد منذ ثلاثة أيام';

    public function handle(CloseSilentInternalTickets $close): int
    {
        $closed = $close();

        $this->info("أُغلقت {$closed} تذكرة");

        return self::SUCCESS;
    }
}
