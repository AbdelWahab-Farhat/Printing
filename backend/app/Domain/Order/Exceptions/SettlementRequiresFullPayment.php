<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentStatus;
use App\Support\Exceptions\DomainException;

/**
 * «تم التسوية» asked for on an order that still owes money.
 *
 * **The end of the line is about the money, so it may not be reached without it.** «تم الاستلام»
 * says the customer has the bags; «تم التسوية» says the cash they were sent out to collect came
 * back and was agreed. An order standing in the second while its payment status reads «غير
 * مدفوعة» is a contradiction the two axes can express and the business cannot: it is the one
 * combination that closes an order and loses the debt at the same moment.
 *
 * **Refused rather than hidden from the list of moves.** The rule is fixable by the same person
 * at the same desk — record the payment, settle the order — so the message names what is still
 * owed and the button stays where the accountant expects it. A move that quietly disappeared
 * would leave them looking for it.
 *
 * @see PaymentStatus::isOutstanding()
 */
final class SettlementRequiresFullPayment extends DomainException
{
    public static function make(string $remaining): self
    {
        $settled = OrderStatus::Settled->label();

        return new self("لا يمكن نقل الطلبية إلى «{$settled}» قبل تحصيل قيمتها — المتبقي {$remaining}");
    }
}
