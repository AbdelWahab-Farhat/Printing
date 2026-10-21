<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Enums;

/**
 * «الأولوية» في نموذج «تذكرة جديدة»: منخفضة / متوسطة / عالية، والافتراضيّ متوسطة — كبريمولا.
 *
 * **تعدادٌ لا جدول**، بخلاف بريمولا التي تحفظها جدولاً. ثلاث درجاتٍ ثابتة لا يضيف إليها أحدٌ
 * رابعة، والجدول كان سيعني ربطاً في كل صفٍّ من القائمة ليقول كلمةً واحدة.
 */
enum InternalTicketPriority: string
{
    case Low = 'low';
    case Medium = 'medium';
    case High = 'high';

    public function label(): string
    {
        return match ($this) {
            self::Low => 'منخفضة',
            self::Medium => 'متوسطة',
            self::High => 'عالية',
        };
    }
}
