<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Enums;

/**
 * ما يستحق نظرة ولا يمنع التسوية.
 */
enum NawrisSettlementWarning: string
{
    /** كود الملف بلاحقة غير سلسلة إعادة الإرسال، مثل 4306969R. */
    case CodeSuffix = 'code_suffix';

    /** النورس أعاد إنشاء الطرد بكود جديد غالباً — المرجع هو المستلم لا الكود. */
    case CodeMismatch = 'code_mismatch';

    /** الملف يذكر كوداً وليس للطلبية طرد عندنا. */
    case CodeMissing = 'code_missing';

    /** عمود المستلم لا يصلح، فعُرفت الطلبية من كود الطرد. */
    case MatchedByCode = 'matched_by_code';

    /** الأجرة علينا ولا نعرف قدرها. */
    case FeeUnknown = 'fee_unknown';

    /** للطلبية مال عند سائق أيضاً، وتسويتها تنقله مع مال النورس. */
    case OtherCustody = 'other_custody';

    /** آخر تعديل مبلغ لم يصل النورس. */
    case MoneyOutOfSync = 'money_out_of_sync';

    /** تعارض تسليم مفتوح على الطرد. */
    case OpenConflict = 'open_conflict';
}
