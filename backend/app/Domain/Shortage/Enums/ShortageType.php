<?php

declare(strict_types=1);

namespace App\Domain\Shortage\Enums;

use App\Domain\Shortage\Actions\SyncShortagesFromOrder;

/**
 * What kind of thing is short — «ورق طباعة» as against «كيس شحن ٢٥*٣٥».
 *
 * **A second axis beside {@see ShortageSource}, and the two answer different questions.** `source`
 * says who wrote the row down and therefore who owns its numbers; this says what the shop is out
 * of. A shortage of paper somebody typed by hand is both «يدوي» and «ورق طباعة», and collapsing
 * the pair into one column would make «أرِني كل نواقص الورق» unanswerable without also knowing
 * who entered each one.
 *
 * **{@see Order} is the server's to assign and nobody else's.** It is stamped by
 * {@see SyncShortagesFromOrder} on every order-born row and refused on the manual form, with a
 * CHECK on the table saying the same thing a third time — see the migration. Letting a clerk type
 * it onto a roll of tape would put «نقص طلبية» on the board beside no order at all, and the one
 * column the list screen reads would start lying.
 *
 * The rest are the workshop's own vocabulary and will grow. When adding one: a case here, a label
 * below, and nothing else — the CHECK names only `order`, so a new category needs no migration.
 */
enum ShortageType: string
{
    /**
     * Something an order needs and the shelf could not cover.
     *
     * Never chosen by a person: `source = order` and `type = order` are two halves of one fact,
     * held together by the table's own constraint.
     */
    case Order = 'order';

    case PrintingPaper = 'printing_paper';
    case Ink = 'ink';

    /** Spare parts, belts, blades — what keeps the press running rather than what it prints on. */
    case Maintenance = 'maintenance';

    /**
     * The honest default for the manual form.
     *
     * **Offered rather than hidden**, for the reason `ShortageData::$productId` is optional: what
     * gets written down by hand is very often what no list anticipated, and forcing the nearest
     * wrong category to get past the field puts a wrong answer in the column that reports «على
     * ماذا ننفق؟». See SHORTAGES-DESIGN §٢٫١.
     */
    case Other = 'other';

    public function label(): string
    {
        return match ($this) {
            self::Order => 'نقص طلبية',
            self::PrintingPaper => 'ورق طباعة',
            self::Ink => 'حبر',
            self::Maintenance => 'صيانة وقطع غيار',
            self::Other => 'أخرى',
        };
    }

    /**
     * Whether a person may put this on a shortage they are writing themselves.
     *
     * Everything but {@see Order}, which belongs to the sync. The form reads this rather than
     * naming the exception, so a case added later is selectable without anybody remembering to
     * add it in a second place.
     */
    public function isSelectableByHand(): bool
    {
        return $this !== self::Order;
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $type) => $type->value, self::cases());
    }

    /**
     * What the manual form may offer.
     *
     * @return array<int, self>
     */
    public static function selectableByHand(): array
    {
        return array_values(array_filter(
            self::cases(),
            fn (self $type): bool => $type->isSelectableByHand(),
        ));
    }
}
