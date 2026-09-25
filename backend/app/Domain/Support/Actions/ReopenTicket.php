<?php

declare(strict_types=1);

namespace App\Domain\Support\Actions;

use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Enums\TicketStatus;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\Models\SupportTicket;

/**
 * يعيد المكتبُ فتحَ تذكرةٍ أغلقها، عن قصد.
 *
 * **هذه هي الخطوة التي يطلبها {@see PostTicketMessage} من الموظف ولم يكن لها زر**: لا يكتب
 * الموظف في تذكرةٍ مغلقة، فإن كان عنده ما يضيفه أعاد فتحها أولاً. وردُّ العميل ما زال يعيد فتحها
 * بنفسه — ذاك طريقٌ آخر يحمل سببه معه.
 *
 * **تعود «قيد المعالجة» لا «مفتوحة».** «مفتوحة» تعني أن أحداً لم يجب بعد، وهذه تذكرةٌ أجاب عنها
 * المحل وقرّر موظفٌ أن يتابعها: هي على مكتب.
 *
 * يُمحى من أغلقها ومتى، كما يمحوهما ردُّ العميل: تذكرةٌ مفتوحة تحمل اسمَ من أغلقها تكذب.
 *
 * وككلّ ما يُضغط زرُّه مرتين: إعادةُ فتح المفتوحة لا تكتب شيئاً ولا تُعدّ خطأ.
 */
final class ReopenTicket
{
    public function __invoke(SupportTicket $ticket): SupportTicket
    {
        if ($ticket->status !== TicketStatus::Closed) {
            return $ticket;
        }

        $ticket->status = TicketStatus::InProgress;
        $ticket->closed_at = null;
        $ticket->closed_by = null;
        $ticket->save();

        TicketChanged::dispatch((int) $ticket->getKey(), TicketChange::Reopened);

        return $ticket->refresh();
    }
}
