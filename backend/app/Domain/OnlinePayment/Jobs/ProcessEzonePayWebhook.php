<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Jobs;

use App\Domain\OnlinePayment\Actions\SettleTopUp;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Models\GatewayWebhookEvent;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

/**
 * One EzonePay event, worked on the queue.
 *
 * - Event `2` («Paid») is the only one EzonePay sends; anything else is kept and ignored.
 * - The attempt is found by EzonePay's transaction id, else by **our own reference** — generated
 *   by the server and unique, so there is no guessing between twins (Primula's «twin row» logic).
 * - A card-link attempt learns its transaction id here.
 * - **EzonePay is then asked about the transaction itself** — the body alone is never credited —
 *   and the answer goes through {@see SettleTopUp}, which credits once whoever asks.
 *
 * Retried three times with growing waits; one that still fails is marked `failed` with its error,
 * and the five-minute recheck picks the attempt up anyway.
 */
final class ProcessEzonePayWebhook implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    /** @var list<int> */
    public array $backoff = [10, 60, 300];

    public function __construct(public readonly int $eventId) {}

    public function handle(OnlinePaymentGateway $gateway, SettleTopUp $settle): void
    {
        $event = GatewayWebhookEvent::query()->find($this->eventId);

        if ($event === null || $event->processed_at !== null) {
            return;
        }

        $event->forceFill(['attempts' => $event->attempts + 1])->save();

        $payload = $event->payload;
        $transactionId = is_numeric($payload['transactionId'] ?? null) ? (int) $payload['transactionId'] : null;
        $reference = is_string($payload['orderReference'] ?? null) ? $payload['orderReference'] : null;

        if ((int) ($payload['event'] ?? 0) !== 2) {
            $this->finish($event, GatewayWebhookEvent::IGNORED, 'ليس حدث دفع');

            return;
        }

        $intent = $this->find($transactionId, $reference);

        if ($intent === null || $transactionId === null) {
            $this->finish($event, GatewayWebhookEvent::IGNORED, 'لا محاولة دفع تطابق هذا الحدث');

            return;
        }

        if ($intent->provider_transaction_id === null) {
            $intent->forceFill(['provider_transaction_id' => $transactionId])->save();
        }

        $settle($intent, $gateway->transaction($transactionId));

        $this->finish($event, GatewayWebhookEvent::PROCESSED, null);
    }

    /** The last try failed too: kept with its error, for the events screen and the recheck. */
    public function failed(Throwable $error): void
    {
        GatewayWebhookEvent::query()->whereKey($this->eventId)->update([
            'status' => GatewayWebhookEvent::FAILED,
            'error' => mb_substr($error->getMessage(), 0, 1000),
            'updated_at' => now(),
        ]);
    }

    private function find(?int $transactionId, ?string $reference): ?PaymentIntent
    {
        $byTransaction = $transactionId === null
            ? null
            : PaymentIntent::query()->where('provider_transaction_id', $transactionId)->first();

        return $byTransaction ?? ($reference === null
            ? null
            : PaymentIntent::query()->where('our_reference', $reference)->first());
    }

    private function finish(GatewayWebhookEvent $event, string $status, ?string $error): void
    {
        $event->forceFill(['status' => $status, 'error' => $error, 'processed_at' => now()])->save();
    }
}
