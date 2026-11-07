<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Enums;

/**
 * ما يحدث لطلبية واحدة من ملف تسوية النورس.
 *
 * ثلاث نتائج لا أكثر. والتحفّظ ({@see NawrisSettlementWarning}) ليس نتيجة — يرافق أيّاً منها.
 */
enum NawrisSettlementOutcome: string
{
    case Settled = 'settled';

    /** كانت «تم التسوية» قبل الرفع، أو تكررت في الملف — لهذا يكون رفع الملف مرتين آمناً. */
    case AlreadySettled = 'already_settled';

    case Rejected = 'rejected';

    /**
     * كانت صالحة، وتركها الموظف لأن مالها لم يصل بعد. تبقى «تم الاستلام» ومالها في عهدة النورس،
     * ورفع الملف نفسه بعد وصوله يسوّيها.
     */
    case LeftOut = 'left_out';

    public function label(): string
    {
        return match ($this) {
            self::Settled => 'تُسوّى',
            self::AlreadySettled => 'مسوّاة سلفاً',
            self::Rejected => 'لن تتحرك',
            self::LeftOut => 'تُركت لتحويل لاحق',
        };
    }
}
