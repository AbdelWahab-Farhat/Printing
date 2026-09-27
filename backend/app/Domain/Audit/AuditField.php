<?php

declare(strict_types=1);

namespace App\Domain\Audit;

use App\Domain\Audit\Enums\AuditSubject;

/**
 * One column on one kind of record — what a history screen's field search picks.
 *
 * **The subject is part of the name, and has to be.** A label is not a column: «التصنيف» is
 * `product_category_id` on a product and `stock_item_group_id` everywhere else, and `name` is
 * «اسم العميل» on one record and «اسم المنتج» on the next. An order's history holds the order,
 * its lines and its payments at once, so «سعر الوحدة» alone would not say whose price. The key
 * the API speaks is therefore `order_item:unit_price` — the alias and the column, nothing to
 * translate back.
 *
 * Only a column that has a label and is not hidden can be named. The label is what the person
 * picked from, and a hidden column is one the screen would not draw anyway — a search for it
 * would bring up cards with nothing on them.
 */
final readonly class AuditField
{
    private function __construct(
        public AuditSubject $subject,
        public string $column,
    ) {}

    /**
     * The field this key names, or null if it names none — the caller turns that into a 422.
     *
     * The column is checked against a fixed dictionary before it goes anywhere near a query,
     * which is also what makes it safe to put inside a JSON path.
     */
    public static function tryFromKey(string $key): ?self
    {
        [$alias, $column] = array_pad(explode(':', $key, 2), 2, '');

        return self::tryFrom($alias, $column);
    }

    public static function tryFrom(string $alias, string $column): ?self
    {
        $subject = AuditSubject::tryFrom($alias);

        if ($subject === null
            || ! array_key_exists($column, AuditAttributeLabels::for($subject))
            || AuditHiddenAttributes::hides($column, $subject)) {
            return null;
        }

        return new self($subject, $column);
    }

    public function key(): string
    {
        return $this->subject->value.':'.$this->column;
    }

    public function label(): string
    {
        return AuditAttributeLabels::for($this->subject)[$this->column];
    }

    /**
     * What a picker shows: the label, and whose it is for the times two labels read alike.
     *
     * @return array{key: string, label: string, subject_label: string}
     */
    public function toArray(): array
    {
        return [
            'key' => $this->key(),
            'label' => $this->label(),
            'subject_label' => $this->subject->label(),
        ];
    }
}
