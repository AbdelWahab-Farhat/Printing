<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Actions\UndoOrderDelivery;
use App\Support\Exceptions\DomainException;

/**
 * A delivery that {@see UndoOrderDelivery} will not take back, and why.
 *
 * **Refused rather than half-done.** Each case is a delivery that did more than change a status,
 * and undoing only the status would leave the rest standing as if it had not happened.
 */
final class DeliveryCannotBeUndone extends DomainException
{
    /**
     * Some bags came back at the door. The invoice shrank to what was taken and the rest went
     * onto a shelf or was written off; taking that back means drawing stock again at today's
     * cost and restoring an invoice, which is work somebody should look at, not a button.
     */
    public static function becauseItWasPartial(): self
    {
        return new self('كان التسليم جزئياً — أُنقصت الفاتورة ورجع الباقي إلى المخزن. هذا لا يُتراجع عنه بزرّ، يُصحَّح يدوياً');
    }

    /** The timeline does not say where the order came from, so there is nowhere to send it. */
    public static function becauseTheTimelineIsSilent(): self
    {
        return new self('لا يذكر سجلّ الطلبية من أين وصلت إلى «تم الاستلام»، فلا وجهةَ ترجع إليها');
    }
}
