<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\OnlinePayment\Actions\RecheckTopUp;
use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\PaymentFlow;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Console\Command;

/**
 * Every five minutes: asks EzonePay about each attempt still waiting — **a lost webhook never
 * loses a payment** (Primula had nothing like this). CUSTOMER-WALLET §٥.
 *
 * An OTP or QR attempt waiting ten minutes, and a card link waiting thirty, are asked about;
 * paid ones are credited through the one settle path, unpaid ones past their time expire. An
 * attempt that fails to be asked about is reported and the sweep moves on — the next run tries
 * again. Does nothing while online payments are off.
 */
class ReconcileOnlinePayments extends Command
{
    protected $signature = 'payments:reconcile';

    protected $description = 'Ask EzonePay about pending online top-ups — credit the paid, expire the stale';

    public function handle(OnlinePaymentGateway $gateway, RecheckTopUp $recheck): int
    {
        if (! $gateway->isEnabled()) {
            $this->line('الدفع الإلكتروني مطفأ — لا شيء يُسأل عنه.');

            return self::SUCCESS;
        }

        $after = (int) config('ezone_pay.reconcile_after_minutes', 10);
        $credited = 0;
        $expired = 0;

        PaymentIntent::query()
            ->whereIn('status', [IntentStatus::Pending->value, IntentStatus::Created->value])
            ->where(fn ($q) => $q
                ->where(fn ($quick) => $quick
                    ->where('flow', '<>', PaymentFlow::Link->value)
                    ->where('created_at', '<=', now()->subMinutes($after)))
                ->orWhere(fn ($link) => $link
                    ->where('flow', PaymentFlow::Link->value)
                    ->where('created_at', '<=', now()->subMinutes(30))))
            ->orderBy('id')
            ->each(function (PaymentIntent $intent) use ($recheck, &$credited, &$expired): void {
                // One attempt EzonePay cannot answer about must not stop the others — reported, and
                // asked again on the next run. The probe RULES §5 allows `rescue` for.
                $after = rescue(fn () => $recheck($intent), null, report: true);

                match ($after?->status) {
                    IntentStatus::Succeeded => $credited++,
                    IntentStatus::Expired => $expired++,
                    default => null,
                };
            });

        $this->info("شُحنت {$credited} وانتهت {$expired}.");

        return self::SUCCESS;
    }
}
