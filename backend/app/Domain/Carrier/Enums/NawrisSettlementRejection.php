<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Enums;

/**
 * لماذا لن تتحرك طلبية من الملف. الرمز هوية يقرؤها التطبيق؛ النص يُكتب في التقييم لأنه يذكر أرقاماً.
 */
enum NawrisSettlementRejection: string
{
    /** عمود «الحالة» في الملف ليس «تم التسوية». */
    case StatusNotSettled = 'status_not_settled_in_file';

    case ReceiverNotUsable = 'receiver_not_usable';

    case OrderNotFound = 'order_not_found';

    case OrderDeleted = 'order_deleted';

    /** «تم التسوية» لا تُبلغ إلا من «تم الاستلام» — انظر `OrderStatus::allowedNext()`. */
    case OrderNotDelivered = 'order_not_delivered';

    /** باقٍ عليها مال، و`ChangeOrderStatus` كان سيرفضها. يُقال هنا قبل أن يضغط أحد. */
    case OrderHasBalance = 'order_has_balance';

    /**
     * لا طرد لها ولا مال عند النورس. الأكواد هنا أربعة أرقام، فرقمٌ شارد في عمود المستلم قد يصيب
     * طلبية حقيقية لا علاقة لها بالملف — ولولا هذا الشرط لسُوّيت بلا أي خطأ ظاهر.
     */
    case NotANawrisOrder = 'not_a_nawris_order';
}
