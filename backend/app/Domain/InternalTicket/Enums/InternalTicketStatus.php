<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Enums;

/**
 * أين وصلت تذكرةٌ بين موظفَين.
 *
 * **اثنتان فقط، كبريمولا.** التذكرة الداخلية تولد «قيد المعالجة»: زميلٌ يكتب لزميلٍ يعرف أن هناك
 * من ينتظره، فلا معنى لـ«جديدة لم يلمسها أحد» كالتي في تذاكر الدعم. والإغلاق نهائيّ — مَن أراد
 * المتابعة يفتح تذكرةً جديدة — فلا خريطة انتقالات تُحرس هنا: الانتقال الوحيد في `CloseInternalTicket`.
 */
enum InternalTicketStatus: string
{
    case InProgress = 'in_progress';

    /** لا يُكتب فيها ولا تُعاد فتحها. */
    case Closed = 'closed';

    public function label(): string
    {
        return match ($this) {
            self::InProgress => 'قيد المعالجة',
            self::Closed => 'مغلقة',
        };
    }

    public function isOpen(): bool
    {
        return $this !== self::Closed;
    }
}
