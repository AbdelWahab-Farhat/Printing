<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\InternalTicket\DTOs\InternalTicketIdentifier;
use Illuminate\Support\Facades\DB;

/**
 * يحجز رقم التذكرة التالي ويبني كودها: TR-1، TR-2 …
 *
 * الآليةُ نفسها التي للعملاء والطلبيات وتذاكر التصميم — `nextval` على تسلسل الجدول قبل الإدراج،
 * فيحمل الصفُّ كوداً نهائياً فريداً. **و`TR-` كبريمولا**، لا حرفاً واحداً كـ`D` في تذاكر التصميم:
 * الطلبُ أن تكون كما هي هناك، والكودُ أوّل ما يقرؤه الموظف على الصف.
 */
final class AllocateInternalTicketIdentifier
{
    public function __invoke(): InternalTicketIdentifier
    {
        $id = (int) DB::scalar("select nextval(pg_get_serial_sequence('internal_tickets', 'id'))");

        return new InternalTicketIdentifier($id, 'TR-'.$id);
    }
}
