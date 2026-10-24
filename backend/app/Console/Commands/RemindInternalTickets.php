<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\InternalTicket\Actions\RemindAwaitedParties;
use Illuminate\Console\Command;

/**
 * يذكّر مَن تأخّر ردّه في التذاكر الداخلية — مرّةً في اليوم، الساعة `internal_tickets.reminder.at`.
 *
 * نداءٌ لا يجد ما يفعله لا يكتب شيئاً، ونداءٌ ثانٍ في اليوم نفسه لا يذكّر أحداً مرّتين: كلُّ تذكرةٍ
 * تُسأل عن آخر كلامٍ وآخر تذكير قبل أن يُكتب شيء. السياسةُ في config/internal_tickets.php.
 */
class RemindInternalTickets extends Command
{
    protected $signature = 'internal-tickets:remind';

    protected $description = 'يذكّر من تأخّر ردّه في التذاكر الداخلية المفتوحة';

    public function handle(RemindAwaitedParties $remind): int
    {
        $sent = $remind();

        $this->info("أُرسل {$sent} تذكيراً");

        return self::SUCCESS;
    }
}
