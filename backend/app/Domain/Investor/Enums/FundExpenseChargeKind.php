<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * أين وقع جزءٌ من مصروفٍ على البضاعة — Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md §٤.٤.
 */
enum FundExpenseChargeKind: string
{
    /** رفع تكلفةَ طبقةٍ على الرفّ — يحمله من يقاسم ربحَ بيعها لاحقاً، ولا يُكتب على أحدٍ الآن. */
    case Shelf = 'shelf';

    /** حصةُ ما بِيع قبل المصروف — تُكتب على فترة البيع، أو تُردّ إليها حين يُعكس المصروف. */
    case Consumer = 'consumer';

    /** فرقُ تقريب Δ إلى ثلاث منازل، حين لا مستهلكَ يأخذه — على فترة يوم المصروف. */
    case Rounding = 'rounding';

    public function label(): string
    {
        return match ($this) {
            self::Shelf => 'على البضاعة',
            self::Consumer => 'على المبيعات',
            self::Rounding => 'فرق تقريب',
        };
    }

    /** أيُكتب على المحافظ ونقد الصندوق؟ — ما على الرفّ لا يُكتب على أحد. */
    public function isCharged(): bool
    {
        return $this !== self::Shelf;
    }
}
