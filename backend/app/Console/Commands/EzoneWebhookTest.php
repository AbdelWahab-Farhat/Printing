<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\OnlinePayment\Gateway\EzonePay\EzonePayGateway;
use Illuminate\Console\Command;

/**
 * Asks EzonePay to send a test «Paid» event to our webhook — then check `gateway_webhook_events`
 * (it should hold one row) and the `ezone` log.
 */
class EzoneWebhookTest extends Command
{
    protected $signature = 'ezone:webhook-test';

    protected $description = 'Ask EzonePay to fire a test event at our webhook';

    public function handle(EzonePayGateway $gateway): int
    {
        $gateway->fireTestWebhook();

        $this->info('طُلب حدثٌ تجريبي — انظر gateway_webhook_events وسجل ezone.');

        return self::SUCCESS;
    }
}
