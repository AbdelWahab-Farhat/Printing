<?php

declare(strict_types=1);

namespace App\Domain\Investor\Enums;

/**
 * كلُّ طريقٍ يتحرّك به عددُ وحدات مستثمر — والاتجاهُ لا يسكن إشارةً.
 *
 * العددُ على الصفّ موجبٌ دائماً، كما في كل دفترٍ آخر هنا، وهذا الـ enum يقول ما يعنيه الصفّ.
 */
enum UnitEntryType: string
{
    /** وحداتٌ اشتراها إيداعٌ بسعر اليوم. */
    case Issue = 'issue';

    /** وحداتٌ أُلغيت لأن صاحبها سحب رأسَ ماله. */
    case Cancel = 'cancel';

    /** يُبطل صفّاً واحداً سابقاً، حاملاً عددَه كما هو. */
    case Reversal = 'reversal';

    public function label(): string
    {
        return match ($this) {
            self::Issue => 'إصدار وحدات',
            self::Cancel => 'إلغاء وحدات',
            self::Reversal => 'عكس حركة',
        };
    }

    /**
     * أيزيد هذا الصفُّ الوحداتِ أم ينقصها.
     *
     * والعكسُ بلا اتجاهٍ خاصّ — يأخذ نقيضَ اتجاه الصفّ الذي يُبطله، فيُجيب `0` ولا يُقرأ منه
     * شيء: قارئُه الوحيد يمرّ على `reversedEntry` أولاً.
     */
    public function direction(): int
    {
        return match ($this) {
            self::Issue => 1,
            self::Cancel => -1,
            self::Reversal => 0,
        };
    }
}
