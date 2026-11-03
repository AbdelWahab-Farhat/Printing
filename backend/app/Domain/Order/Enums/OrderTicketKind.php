<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\Support\Models\SupportTicket;

/**
 * أيُّ صفٍّ من صفوف التذاكر الثلاثة تقف عليه تذكرةٌ مرتبطة بطلبية.
 *
 * **ثلاثةُ جداول لا جدولٌ واحد**: تذاكرُ الموظفين وتذاكرُ التصميم وتذاكرُ العملاء تعيش كلٌّ في
 * سياقها بحالاتها وقواعد رؤيتها، ولا يجمعها إلا `order_id`. فقسمُ «التذاكر المرتبطة» يضعها في
 * قائمةٍ واحدة، وكلُّ صفٍّ يحمل نوعه — طلبُ المالك ٢٠٢٦-١٠-٢٨: «اعرض كل الأنواع بالنوع بجانبها».
 */
enum OrderTicketKind: string
{
    /** موظفٌ كتب إلى زميل — {@see InternalTicket}. */
    case Internal = 'internal';

    /** طلبُ تصميمٍ إلى المصمّمين — {@see DesignTicket}. */
    case Design = 'design';

    /** ما سأله العميل من تطبيقه — {@see SupportTicket}. */
    case Support = 'support';

    /** الكلمةُ بجانب التذكرة، بأسماء تبويبات «التذاكر» نفسها. */
    public function label(): string
    {
        return match ($this) {
            self::Internal => 'موظفين',
            self::Design => 'تصميم',
            self::Support => 'عميل',
        };
    }
}
