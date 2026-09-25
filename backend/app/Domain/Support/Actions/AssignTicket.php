<?php

declare(strict_types=1);

namespace App\Domain\Support\Actions;

use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Models\SupportTicket;

/**
 * يضع التذكرة على مكتب موظف، أو يعيدها إلى الطابور بـ`null`.
 *
 * **فعلٌ مستقل وإن كان سطراً واحداً**، لأن للإسناد الآن أثراً خارج الصف: زملاءُ المكتب يرون
 * التذكرة تنتقل ساعةَ تنتقل. ولا حدثَ حين لا يتغيّر شيء — إسنادُها إلى من هي عنده ليس خبراً.
 */
final class AssignTicket
{
    public function __invoke(SupportTicket $ticket, ?int $userId): SupportTicket
    {
        if ($ticket->assigned_to === $userId) {
            return $ticket;
        }

        $ticket->update(['assigned_to' => $userId]);

        TicketChanged::dispatch((int) $ticket->getKey(), TicketChange::Assigned);

        return $ticket->refresh();
    }
}
