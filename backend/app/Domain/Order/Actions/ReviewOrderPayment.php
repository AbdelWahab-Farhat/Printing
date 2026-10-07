<?php

declare(strict_types=1);

namespace App\Domain\Order\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\Order\Exceptions\PaymentNeedsNoReview;
use App\Domain\Order\Models\OrderPayment;

/**
 * «مراجعة الدفعة» — somebody holding the grant saying they checked an entry and it is right, or
 * taking that back. **Their own entries included**: the owner chose (2026-10-04) not to demand a
 * second person, unlike the deposit confirmation. The stamp says who reviewed, so it is visible.
 *
 * **The only writer of `reviewed_at` and `reviewed_by`**, and the one sanctioned update to a
 * ledger row: the money columns stay exactly as they were written, and both directions land in the
 * audit log. The twin of {@see ConfirmDepositReceipt}, built the same way for the same reasons —
 * one action for both directions, because the un-review is the correction of a stray tap on the
 * review.
 *
 * **Marking twice keeps the first review.** Somebody opening a row a colleague already checked
 * and tapping again has added nothing, and overwriting the name would erase who actually did the
 * check.
 *
 * **It gates nothing.** No status change, no settlement and no treasury figure reads the review.
 * What it feeds is the reviewer's own queue — see {@see PaymentReviewQueue}.
 */
final class ReviewOrderPayment
{
    /**
     * @param  bool  $reviewed  true stamps the review and the actor; false clears both.
     */
    public function __invoke(OrderPayment $payment, bool $reviewed, ?User $actor = null): OrderPayment
    {
        if (! $reviewed) {
            // Open to anybody holding the grant. An exempt row has no review to withdraw.
            if (! $payment->requires_review) {
                throw PaymentNeedsNoReview::make();
            }

            $payment->forceFill(['reviewed_at' => null, 'reviewed_by' => null])->save();

            return $payment;
        }

        if ($payment->isReviewed()) {
            return $payment;
        }

        $refusal = $payment->reviewRefusal();

        if ($refusal !== null) {
            throw $refusal;
        }

        // `forceFill`: neither column is fillable, deliberately. A request that could post them
        // could put a colleague's name against a check they never made.
        $payment->forceFill([
            'reviewed_at' => now(),
            'reviewed_by' => $actor?->getKey(),
        ])->save();

        return $payment;
    }
}
