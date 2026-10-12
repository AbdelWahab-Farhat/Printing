<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Actions;

use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Events\WalletToppedUpOnline;
use App\Domain\OnlinePayment\Gateway\ProviderTransaction;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\OnlinePayment\Support\FeeCalculator;
use App\Domain\Order\Models\Order;
use App\Domain\Order\OrderService;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;
use App\Domain\Wallet\WalletService;
use Illuminate\Support\Facades\DB;

/**
 * **The one place a wallet is credited for an online payment** — whoever learnt of it first: the
 * OTP confirmation, the QR answer, the webhook or the five-minute recheck. CUSTOMER-WALLET §٥.
 *
 * - **Only on the provider's own word.** `$confirmed` is what the provider answered when asked
 *   about the transaction directly; a webhook body alone is never enough.
 * - **Once.** The attempt is locked and its status read under the lock; a settled attempt is
 *   returned as it is. Underneath, `payment_intents.wallet_entry_id` is unique.
 * - **Never on a different amount.** A charge other than the total we asked for is not credited:
 *   the attempt waits for a person («تحتاج مراجعة»).
 * - **Never on a doubt.** An answer that half-says «paid» is held, not credited ({@see holdUnclear()}).
 * - **The quoted net, exactly** — what the provider really kept is the shop's concern.
 * - **A paid answer revives** an attempt we had marked failed or expired.
 *
 * Then, outside the transaction: the customer is told, and — «اشحن وادفع» — the order the attempt
 * names is paid from the wallet. That payment is a follow-up: an order cancelled meanwhile does not
 * undo the top-up, the money simply stays in the wallet.
 */
final class SettleTopUp
{
    public function __construct(
        private readonly WalletService $wallet,
        private readonly TreasuryService $treasury,
        private readonly FeeCalculator $fees,
    ) {}

    public function __invoke(PaymentIntent $intent, ProviderTransaction $confirmed): PaymentIntent
    {
        if (! $confirmed->paid) {
            return match (true) {
                $confirmed->unclear !== null => $this->holdUnclear($intent, $confirmed),
                $confirmed->failed => $this->markFailed($intent, $confirmed),
                default => $intent->refresh(),
            };
        }

        $credited = DB::transaction(function () use ($intent, $confirmed): ?PaymentIntent {
            $locked = PaymentIntent::query()->whereKey($intent->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->status->canBeSettled()) {
                return null;
            }

            if (! $confirmed->amountMatches((string) $locked->gross_amount)) {
                $locked->forceFill([
                    'status' => IntentStatus::NeedsReview,
                    'provider_transaction_id' => $locked->provider_transaction_id ?? $confirmed->transactionId,
                    'failure_reason' => "المبلغ المخصوم ({$confirmed->amount}) غير المطلوب ({$locked->gross_amount})",
                    'provider_response' => $confirmed->raw,
                ])->save();

                return null;
            }

            $fee = $confirmed->fee ?? $this->fees->expectedFee((string) $locked->gross_amount, (string) $locked->fee_rate);

            $entry = $this->wallet->creditOnlineTopUp(
                (int) $locked->customer_id,
                (string) $locked->net_amount,
                (string) $locked->gross_amount,
                $fee,
                (int) $this->treasury->systemAccount(TreasuryAccount::EZONE)->getKey(),
                (string) $locked->our_reference,
                now(),
            );

            $locked->forceFill([
                'status' => IntentStatus::Succeeded,
                'succeeded_at' => now(),
                'provider_fee' => $fee,
                'provider_transaction_id' => $locked->provider_transaction_id ?? $confirmed->transactionId,
                'wallet_entry_id' => $entry->getKey(),
                'provider_response' => $confirmed->raw,
                'failure_reason' => null,
            ])->save();

            event(new WalletToppedUpOnline((int) $locked->getKey()));

            return $locked;
        });

        if ($credited !== null && $credited->order_id !== null) {
            $this->payTheOrder($credited);
        }

        return $intent->refresh();
    }

    /**
     * «اشحن وادفع». **Wrapped in `rescue()`**, the escape RULES §5 allows for a side effect: the
     * top-up is done and committed; an order that cannot be paid now — cancelled, already paid —
     * leaves the money in the wallet, which is where the customer can see it. Keyed by the attempt,
     * so a second settlement path cannot pay the order twice.
     */
    private function payTheOrder(PaymentIntent $intent): void
    {
        $order = Order::query()->find($intent->order_id);

        if ($order === null || (int) $order->customer_id !== (int) $intent->customer_id) {
            return;
        }

        rescue(
            fn () => app(OrderService::class)->payFromWallet($order, null, null, "intent-{$intent->uuid}"),
            null,
            report: false,
        );
    }

    /**
     * The provider half-says «paid». Nothing is credited: while the attempt has time it keeps
     * waiting — the next ask may be clear — and once its time is up, or it had been given up on,
     * a person decides («تحتاج مراجعة») rather than the sweep expiring money that may have moved.
     */
    private function holdUnclear(PaymentIntent $intent, ProviderTransaction $confirmed): PaymentIntent
    {
        return DB::transaction(function () use ($intent, $confirmed): PaymentIntent {
            $locked = PaymentIntent::query()->whereKey($intent->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->status->canBeSettled()) {
                return $locked;
            }

            $waiting = ($locked->status === IntentStatus::Pending || $locked->status === IntentStatus::Created)
                && ! $locked->isExpired();

            $locked->forceFill($waiting
                ? ['provider_response' => $confirmed->raw]
                : [
                    'status' => IntentStatus::NeedsReview,
                    'provider_transaction_id' => $locked->provider_transaction_id ?? $confirmed->transactionId,
                    'failure_reason' => (string) $confirmed->unclear,
                    'provider_response' => $confirmed->raw,
                ])->save();

            return $locked;
        });
    }

    private function markFailed(PaymentIntent $intent, ProviderTransaction $confirmed): PaymentIntent
    {
        return DB::transaction(function () use ($intent, $confirmed): PaymentIntent {
            $locked = PaymentIntent::query()->whereKey($intent->getKey())->lockForUpdate()->firstOrFail();

            // Only from waiting: a webhook's «paid» that got here first is never overwritten.
            if ($locked->status === IntentStatus::Pending || $locked->status === IntentStatus::Created) {
                $locked->forceFill([
                    'status' => IntentStatus::Failed,
                    'failed_at' => now(),
                    'failure_reason' => 'رفض مزوّد الدفع العملية',
                    'provider_response' => $confirmed->raw,
                ])->save();
            }

            return $locked;
        });
    }
}
