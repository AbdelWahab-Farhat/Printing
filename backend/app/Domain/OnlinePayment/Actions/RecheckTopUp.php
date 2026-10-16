<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Actions;

use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Support\Facades\DB;

/**
 * Asks the provider about one attempt and acts on the answer — the «إعادة التحقق» button and the
 * five-minute `payments:reconcile`. **A lost webhook therefore never loses a payment** (Primula had
 * no such sweep).
 *
 * - **A card link with no transaction yet** — its webhook never came — is looked up by the link:
 *   EzonePay lists what was paid on it, and the transaction found is settled like any other. A
 *   link paid more than once, or paid with no transaction number, waits for a person.
 * - Paid → credited, through {@see SettleTopUp} like every other path — even an attempt we had
 *   marked failed or expired.
 * - Not paid and past its time → `expired`; a card link a quarter of an hour later still, so a
 *   payment made in its last minute is seen first. An attempt the provider never started (no
 *   transaction and no link) is `expired` too once its time is up.
 * - Credited or waiting for a person → left alone.
 */
final class RecheckTopUp
{
    public function __construct(
        private readonly OnlinePaymentGateway $gateway,
        private readonly SettleTopUp $settle,
    ) {}

    public function __invoke(PaymentIntent $intent): PaymentIntent
    {
        if ($intent->status === IntentStatus::Succeeded || $intent->status === IntentStatus::NeedsReview) {
            return $intent;
        }

        if ($intent->provider_transaction_id === null && $intent->provider_link_id !== null) {
            $intent = $this->findOnTheLink($intent);

            if ($intent->status === IntentStatus::NeedsReview) {
                return $intent;
            }
        }

        if ($intent->provider_transaction_id !== null) {
            $settled = ($this->settle)($intent, $this->gateway->transaction((int) $intent->provider_transaction_id));

            if ($settled->status !== IntentStatus::Pending && $settled->status !== IntentStatus::Created) {
                return $settled;
            }
        }

        return $this->pastItsTime($intent) ? $this->expire($intent) : $intent->refresh();
    }

    /** The transaction paid on the attempt's card link, written onto the attempt. */
    private function findOnTheLink(PaymentIntent $intent): PaymentIntent
    {
        $payments = $this->gateway->linkPayments((int) $intent->provider_link_id);

        if ($payments === []) {
            return $intent;
        }

        $ids = array_values(array_unique(array_filter(array_column($payments, 'transaction_id'))));

        if (count($ids) !== 1 || count($payments) !== 1) {
            return $this->review($intent, $ids === []
                ? 'رابط البطاقة مدفوعٌ عند EzonePay ولم يُعرف رقم العملية'
                : 'دُفع رابط البطاقة '.count($payments).' مرات — لم يُشحن شيء');
        }

        $intent->forceFill(['provider_transaction_id' => $ids[0]])->save();

        return $intent;
    }

    private function pastItsTime(PaymentIntent $intent): bool
    {
        if ($intent->flow !== PaymentFlow::Link || $intent->expires_at === null) {
            return $intent->isExpired();
        }

        return $intent->expires_at->copy()->addMinutes((int) config('ezone_pay.link_grace_minutes', 15))->isPast();
    }

    private function review(PaymentIntent $intent, string $reason): PaymentIntent
    {
        return DB::transaction(function () use ($intent, $reason): PaymentIntent {
            $locked = PaymentIntent::query()->whereKey($intent->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->status->canBeSettled()) {
                $locked->forceFill(['status' => IntentStatus::NeedsReview, 'failure_reason' => $reason])->save();
            }

            return $locked;
        });
    }

    private function expire(PaymentIntent $intent): PaymentIntent
    {
        return DB::transaction(function () use ($intent): PaymentIntent {
            $locked = PaymentIntent::query()->whereKey($intent->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->status === IntentStatus::Pending || $locked->status === IntentStatus::Created) {
                $locked->forceFill(['status' => IntentStatus::Expired, 'failed_at' => now()])->save();
            }

            return $locked;
        });
    }
}
