<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

/**
 * Why an order is being sent out for free — «طلبية تعويض».
 *
 * A closed set for the reason {@see AdditionalCostReason} is one: «كم كلّفتنا أخطاء الطباعة هذا
 * الشهر؟» can only be answered from a column a report can group by. The words beside it are the
 * detail. See Docs/orders/ORDER-COMPENSATION.md §4.
 */
enum CompensationReason: string
{
    case PrintDefect = 'print_defect';
    case WrongItem = 'wrong_item';
    case DeliveryDamage = 'delivery_damage';
    case PreviousShortage = 'previous_shortage';
    case Goodwill = 'goodwill';
    /** The one reason that must bring its own words, as with every «أخرى». */
    case Other = 'other';

    public function label(): string
    {
        return match ($this) {
            self::PrintDefect => 'خطأ طباعة',
            self::WrongItem => 'منتج أو مقاس خاطئ',
            self::DeliveryDamage => 'تلف في التوصيل',
            self::PreviousShortage => 'نقص في طلبية سابقة',
            self::Goodwill => 'مجاملة',
            self::Other => 'أخرى',
        };
    }

    public function needsNote(): bool
    {
        return $this === self::Other;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $reason) => $reason->value, self::cases());
    }
}
