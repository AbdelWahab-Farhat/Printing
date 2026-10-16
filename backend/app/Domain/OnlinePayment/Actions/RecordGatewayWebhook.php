<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Actions;

use App\Domain\OnlinePayment\Jobs\ProcessEzonePayWebhook;
use App\Domain\OnlinePayment\Models\GatewayWebhookEvent;

/**
 * Keeps one call from the provider, once, and hands it to the queue.
 *
 * **Once by `(gateway, sha256 of the raw body)`** — a unique index, `insertOrIgnore`: EzonePay
 * delivering the same event twice is one row and one job (Primula had no event store, and replays
 * were stopped by state checks alone). The controller answers 200 at once; the work is the job's.
 */
final class RecordGatewayWebhook
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function __invoke(string $gateway, string $rawBody, array $payload): GatewayWebhookEvent
    {
        $key = hash('sha256', $rawBody);

        $inserted = GatewayWebhookEvent::query()->insertOrIgnore([
            'gateway' => $gateway,
            'event_key' => $key,
            'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE),
            'status' => GatewayWebhookEvent::RECEIVED,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $event = GatewayWebhookEvent::query()->where('gateway', $gateway)->where('event_key', $key)->firstOrFail();

        if ($inserted > 0) {
            ProcessEzonePayWebhook::dispatch((int) $event->getKey());
        }

        return $event;
    }
}
