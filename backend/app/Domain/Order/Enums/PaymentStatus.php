<?php

declare(strict_types=1);

namespace App\Domain\Order\Enums;

use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;

/**
 * Where an order stands on the money.
 *
 * **Derived, never stored, and that is a deliberate difference from `status`.** An order's
 * workflow status is a decision somebody made and a column is the only honest home for it. How
 * much has been paid is arithmetic over two numbers, and both of them move: `grand_total`
 * changes whenever the lines change or a discount is granted, and `paid_amount` whenever the
 * ledger gains a row.
 *
 * A stored column would have to be rewritten by both of those paths, and the first one that
 * forgot would leave an order reading «مدفوعة بالكامل» after its total went up — a wrong answer
 * that looks exactly like a right one. Computing it makes that failure unrepresentable.
 *
 * **A payment axis independent of the workflow axis.** «جاهزة» says nothing about whether the
 * order is paid, and neither implies the other. That separation is why the two were never
 * merged into one enum.
 */
enum PaymentStatus: string
{
    case Unpaid = 'unpaid';

    /** The عربون case: something was paid, not all of it. */
    case PartiallyPaid = 'partially_paid';

    case Paid = 'paid';

    /**
     * More has been paid than the order costs.
     *
     * Not a mistake that got past the guard: `RecordOrderPayment` refuses a payment larger than
     * what is outstanding. This is what a *discount granted after payment* looks like — the
     * total dropped under money already taken, and nobody did anything wrong. It is reported so
     * somebody can refund the difference.
     */
    case Overpaid = 'overpaid';

    public function label(): string
    {
        return match ($this) {
            self::Unpaid => 'غير مدفوعة',
            self::PartiallyPaid => 'مدفوعة جزئياً',
            self::Paid => 'مدفوعة بالكامل',
            self::Overpaid => 'مدفوعة بالزيادة',
        };
    }

    /** Whether anything is still owed on it. */
    public function isOutstanding(): bool
    {
        return $this === self::Unpaid || $this === self::PartiallyPaid;
    }

    /**
     * Reads an order's two money columns and says where it stands.
     *
     * Compared with `bccomp` rather than `<`/`==`: these arrive as decimal strings precisely so
     * they are never floats, and casting them to compare would undo that in the one place it
     * matters most.
     */
    public static function for(Order $order): self
    {
        return self::between((string) $order->paid_amount, (string) $order->grand_total);
    }

    /**
     * The comparison against the total comes *before* the one against zero, so an order that
     * costs nothing — an office pickup with no lines yet — reads «مدفوعة بالكامل» rather than
     * «غير مدفوعة». Nothing is owed on it, and «غير مدفوعة» would put it in the list of orders
     * somebody is meant to chase.
     */
    public static function between(string $paid, string $grandTotal): self
    {
        return match (true) {
            bccomp($paid, $grandTotal, Money::SCALE) > 0 => self::Overpaid,
            bccomp($paid, $grandTotal, Money::SCALE) === 0 => self::Paid,
            bccomp($paid, '0', Money::SCALE) <= 0 => self::Unpaid,
            default => self::PartiallyPaid,
        };
    }

    /**
     * @return array<int, string>
     */
    public static function values(): array
    {
        return array_map(fn (self $status) => $status->value, self::cases());
    }
}
