<?php

declare(strict_types=1);

namespace App\Domain\Order\Exceptions;

use App\Domain\Order\Enums\PaymentStatus;
use App\Support\Exceptions\DomainException;

/**
 * Somebody typed 500 where they meant 50 — or the customer really did hand over 100 for 99.
 *
 * **Refused unless the person confirmed it** (`accept_overpayment`). The ordinary cause of a
 * figure beyond the debt used to be a slipped keystroke, and the confirmation is still what
 * catches that while the customer is standing there. Confirmed, the payment is taken whole and
 * the part beyond the debt is owed back to the customer — `excess_amount`, see
 * Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md.
 *
 * **The rule binds at the moment of recording, not forever.** An order whose total is later cut
 * by a discount can end up paid more than it costs without anybody having done anything wrong —
 * that is {@see PaymentStatus::Overpaid}, which is reported so the difference can be refunded.
 * Enforcing "paid may never exceed total" as a standing invariant would make granting that
 * discount impossible.
 */
final class PaymentExceedsRemaining extends DomainException
{
    private string $field = 'amount';

    /**
     * @param  string  $field  where the refusal is filed — `fields.payment_amount` on the status
     *                         screen, whose fields hang off `fields`
     */
    public static function make(string $amount, string $remaining, string $field = 'amount'): self
    {
        $exception = new self("المبلغ ({$amount}) أكبر من المتبقي على الطلبية ({$remaining}) — أكّد تسجيل الزائد إيراداً");
        $exception->field = $field;

        return $exception;
    }

    /**
     * @return array<string, array<int, string>>
     */
    public function fieldErrors(): array
    {
        return [$this->field => [$this->getMessage()]];
    }
}
