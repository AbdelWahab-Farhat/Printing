<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\UnsettleOrder;
use App\Domain\Order\Enums\OrderStatus;
use App\Support\Exceptions\DomainException;

/**
 * Money taken off a settled order so that it would owe again.
 *
 * **The mirror of {@see SettlementRequiresFullPayment}.** That one refuses to reach «تم التسوية»
 * while anything is owed; this refuses to make something owed while the order stands in it.
 * Without both, a reversal or a refund leaves an order reading «تم التسوية» beside «مدفوعة
 * جزئياً» — the combination the first rule exists to make impossible, reached from the other
 * side, and nothing on any screen would say so.
 *
 * **Refused, not quietly walked back.** Taking the order back to «تم الاستلام» on its own would
 * be a status change nobody pressed; {@see UnsettleOrder} is the button, it asks why, and it
 * writes the move on the order's timeline. So the message names that button.
 *
 * A refund of an overpayment still passes: it takes money off, but the order stays paid.
 */
final class SettledOrderMustBeUnsettledFirst extends DomainException
{
    public static function make(): self
    {
        $settled = OrderStatus::Settled->label();
        $delivered = OrderStatus::Delivered->label();

        return new self(
            "الطلبية في «{$settled}»، وهذه الحركة تجعلها مدينةً من جديد. "
            ."تراجع عن التسوية أولاً — ترجع الطلبية إلى «{$delivered}» — ثم أعد المحاولة",
        );
    }
}
