<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\OnlinePayment\Gateway\EzonePay\EzonePayGateway;
use Illuminate\Console\Command;

/**
 * Registers our webhook URL with EzonePay (event 2, «Paid») and prints the `SecretKey` it answers
 * with — to be put in `.env` as `EZONE_PAY_WEBHOOK_SECRET`. Run once per environment.
 */
class EzoneWebhookSubscribe extends Command
{
    protected $signature = 'ezone:webhook-subscribe {url? : defaults to APP_URL/api/v1/webhooks/ezonepay}';

    protected $description = 'Register our webhook with EzonePay and print the secret for .env';

    public function handle(EzonePayGateway $gateway): int
    {
        $url = (string) ($this->argument('url') ?: rtrim((string) config('app.url'), '/').'/api/v1/webhooks/ezonepay');

        $answer = $gateway->subscribeWebhook($url);
        $secret = $answer['secretKey'] ?? $answer['SecretKey'] ?? null;

        $this->info("سُجّل الـ webhook: {$url}");

        if (is_string($secret) && $secret !== '') {
            $this->line('ضع هذا في .env:');
            $this->line("EZONE_PAY_WEBHOOK_SECRET={$secret}");
        } else {
            $this->warn('لم يُرجع EzonePay مفتاحاً — راجع سجل ezone.');
        }

        return self::SUCCESS;
    }
}
