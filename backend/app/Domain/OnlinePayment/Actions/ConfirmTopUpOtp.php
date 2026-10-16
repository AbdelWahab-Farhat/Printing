<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Actions;

use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Exceptions\OnlinePaymentRefused;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Support\Facades\DB;

/**
 * The code the provider texted the customer, sent back to finish an OTP payment.
 *
 * - **The attempt is the customer's own** — the controller finds it through the customer, so a
 *   wrong code typed by someone else can fail nobody's payment (Primula's gap).
 * - **A wrong code is not the end**: the attempt stays waiting until its attempts run out or it
 *   expires. In Primula one wrong code failed the payment for good.
 * - **The attempt is counted before the provider is asked**, committed, so a code guessed over and
 *   over runs out whatever the provider answers.
 * - On a yes, the provider is asked about the transaction itself, and that answer is credited.
 */
final class ConfirmTopUpOtp
{
    public function __construct(
        private readonly OnlinePaymentGateway $gateway,
        private readonly SettleTopUp $settle,
    ) {}

    public function __invoke(PaymentIntent $intent, string $otp): PaymentIntent
    {
        if (($known = $this->alreadyPaid($intent)) !== null) {
            return $known;
        }

        $counted = DB::transaction(function () use ($intent): PaymentIntent {
            $locked = PaymentIntent::query()->whereKey($intent->getKey())->lockForUpdate()->firstOrFail();

            if ($locked->flow !== PaymentFlow::Otp
                || $locked->status !== IntentStatus::Pending
                || $locked->provider_transaction_id === null
                || $locked->isExpired()) {
                throw OnlinePaymentRefused::notWaitingForOtp();
            }

            if ($locked->otp_attempts >= (int) config('ezone_pay.otp_max_attempts', 3)) {
                $locked->forceFill([
                    'status' => IntentStatus::Failed,
                    'failed_at' => now(),
                    'failure_reason' => 'انتهت محاولات رمز التحقق',
                ])->save();

                return $locked;
            }

            $locked->forceFill(['otp_attempts' => $locked->otp_attempts + 1])->save();

            return $locked;
        });

        if ($counted->status === IntentStatus::Failed) {
            throw OnlinePaymentRefused::otpAttemptsExhausted();
        }

        // A wrong code is the provider's refusal, thrown from here with its own words; the
        // attempt stays waiting with one try fewer.
        $this->gateway->completeOtp((int) $counted->provider_transaction_id, $counted->method, $otp);

        // Taken: whatever the confirmation says next, no second code is asked for.
        $counted->forceFill(['otp_accepted_at' => now()])->save();

        return ($this->settle)($counted, $this->gateway->transaction((int) $counted->provider_transaction_id));
    }

    /**
     * **A code sent before may already have paid.** EzonePay finishes a payment on the first right
     * code and answers any later one «السجل غير موجود» — so before a second code is sent, it is
     * asked where the payment stands (the sandbox, 2026-10-11). Paid: credited, and no code sent.
     * Paid but not yet clear: the customer is told it is being confirmed. Otherwise null — the
     * code goes on as usual.
     */
    private function alreadyPaid(PaymentIntent $intent): ?PaymentIntent
    {
        if ($intent->otp_attempts < 1 || $intent->provider_transaction_id === null || $intent->status !== IntentStatus::Pending) {
            return null;
        }

        $known = $this->gateway->transaction((int) $intent->provider_transaction_id);

        if (! $known->paid && $known->unclear === null) {
            // A code EzonePay already took is never sent again — it would answer «السجل غير موجود».
            if ($intent->isConfirming()) {
                throw OnlinePaymentRefused::beingConfirmed();
            }

            return null;
        }

        $settled = ($this->settle)($intent, $known);

        if ($settled->status === IntentStatus::Pending) {
            throw OnlinePaymentRefused::beingConfirmed();
        }

        return $settled;
    }
}
