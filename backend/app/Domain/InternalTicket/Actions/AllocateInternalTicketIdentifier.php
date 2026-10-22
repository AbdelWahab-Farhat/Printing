<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\InternalTicket\DTOs\InternalTicketIdentifier;
use Illuminate\Support\Facades\DB;

/**
 * يحجز رقم التذكرة التالي ويبني كودها: T1، T2 …
 *
 * الآليةُ نفسها التي للعملاء والطلبيات وتذاكر التصميم — `nextval` على تسلسل الجدول قبل الإدراج،
 * فيحمل الصفُّ كوداً نهائياً فريداً. **وحرفٌ واحدٌ ثم الرقم**، كـ`C7` للعميل و`D7` لتذكرة التصميم:
 * كان `TR-` كبريمولا، وطلب المالك ٢٠٢٦-١٠-٢٣ كوداً أبسط.
 */
final class AllocateInternalTicketIdentifier
{
    public function __invoke(): InternalTicketIdentifier
    {
        $id = (int) DB::scalar("select nextval(pg_get_serial_sequence('internal_tickets', 'id'))");

        return new InternalTicketIdentifier($id, 'T'.$id);
    }
}
