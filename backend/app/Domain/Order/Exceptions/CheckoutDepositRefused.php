<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\PlaceOrderWithDeposit;
use App\Support\Exceptions\DomainException;

/**
 * The عربون chosen in the basket cannot be taken — see {@see PlaceOrderWithDeposit}.
 *
 * Reported under `deposit.amount` or `deposit`, the field the app drew, so the message lands
 * under the box the customer has to change. Nothing is written: the order is refused whole.
 */
final class CheckoutDepositRefused extends DomainException
{
    private function __construct(string $message, private readonly string $field)
    {
        parent::__construct($message);
    }

    /**
     * The basket priced differently from what the app showed — a line became «حسب الطلب», or a
     * product moved to a vendor — and the order has to be reviewed first.
     */
    public static function notOffered(): self
    {
        return new self('لا يمكن دفع عربون على هذه الطلبية الآن — أرسلها للمراجعة وسنحدّد المبلغ معك', 'deposit');
    }

    /**
     * An accepted order whose عربون can no longer be chosen from the app — staff moved it on, or it
     * already names one, or money is already on it. See `ChooseOrderDeposit`.
     */
    public static function noLongerOffered(): self
    {
        return new self('لم يعد اختيار العربون متاحاً لهذه الطلبية — حدّث الصفحة', 'deposit');
    }

    /** [$field] is where the request carried the amount — `deposit.amount` in the basket. */
    public static function belowMinimum(string $minimum, string $field = 'deposit.amount'): self
    {
        return new self('أقل عربون '.bcadd($minimum, '0', 0).' د.ل (ربع قيمة الطلبية)', $field);
    }

    /** [$maximum] is the goods rounded down to the dinar — see `CheckoutDeposit::maximum()`. */
    public static function aboveTotal(string $maximum, string $field = 'deposit.amount'): self
    {
        return new self('أكثر عربون '.bcadd($maximum, '0', 0).' د.ل (قيمة الطلبية)', $field);
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
