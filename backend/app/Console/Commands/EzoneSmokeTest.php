<?php

declare(strict_types=1);

namespace App\Console\Commands;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Gateway\EzonePay\EzonePayClient;
use App\Domain\OnlinePayment\Gateway\EzonePay\EzonePayGateway;
use Illuminate\Console\Command;

/**
 * Checks the integration against a real EzonePay account — the step the build could not take
 * without credentials. CUSTOMER-WALLET §٥ lists what it confirms.
 *
 * 1. Signs in (and so: the URL, the email, the password).
 * 2. Lists the merchant's methods beside ours, with their least and most — an id we have that
 *    EzonePay does not list, or one it lists that we do not know, is printed.
 * 3. Asks what each of our methods charges for 100 to reach the shop, and prints the rate, the
 *    charge and the fee.
 * 4. With `--transaction=ID`, prints the raw answer for one transaction, so the status and amount
 *    fields `EzonePayGateway::transaction()` reads can be checked against what EzonePay sends.
 *
 * Read-only: it starts no payment.
 */
class EzoneSmokeTest extends Command
{
    protected $signature = 'ezone:smoke-test {--transaction= : print the raw answer for one transaction id}';

    protected $description = 'Check the EzonePay integration against the configured account (read-only)';

    public function handle(EzonePayClient $client, EzonePayGateway $gateway): int
    {
        if (! $client->isConfigured()) {
            $this->error('EZONE_PAY_EMAIL و EZONE_PAY_PASSWORD مطلوبان في .env');

            return self::FAILURE;
        }

        $client->forgetTokens();

        $this->info('١. الطرق التي يعرضها حساب التاجر:');
        $offered = $gateway->methods();

        foreach ($offered as $id => $bounds) {
            $known = OnlineMethod::tryFrom($id);
            $this->line(sprintf('   %d  %s  الأدنى %s  الأعلى %s', $id, $known?->label() ?? '— غير معروفة لنا', $bounds['min'] ?? 'بلا', $bounds['max'] ?? 'بلا'));
        }

        foreach (OnlineMethod::cases() as $method) {
            if (! array_key_exists($method->value, $offered)) {
                $this->warn("   {$method->value} ({$method->label()}) عندنا وليست في حساب التاجر");
            }
        }

        $this->info('٢. العمولة على ١٠٠ دينار:');

        foreach (OnlineMethod::cases() as $method) {
            if (! array_key_exists($method->value, $offered)) {
                continue;
            }

            // Reversed, as a top-up asks: what is charged so 100 reaches the shop.
            $quote = rescue(fn () => $gateway->quote($method, '100.00', reverse: true), null, report: false);
            $this->line($quote === null
                ? sprintf('   %-28s تعذّر', $method->label())
                : sprintf('   %-28s %s %%  يُخصم %s  عمولة %s', $method->label(), bcmul($quote->rate, '100', 2), $quote->charge, $quote->fee));
        }

        if ($id = $this->option('transaction')) {
            $this->info("٣. المعاملة {$id} كما يرسلها EzonePay:");
            $transaction = $gateway->transaction((int) $id);
            $this->line(json_encode($transaction->raw, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) ?: '');
            $this->line(sprintf('   قرأناها: مدفوعة=%s فاشلة=%s المبلغ=%s العمولة=%s',
                $transaction->paid ? 'نعم' : 'لا',
                $transaction->failed ? 'نعم' : 'لا',
                $transaction->amount ?? '؟',
                $transaction->fee ?? '؟',
            ));

            if ($transaction->unclear !== null) {
                $this->warn("   غير واضحة: {$transaction->unclear}");
            }
        }

        $this->info('انتهى — التفاصيل الكاملة في storage/logs/ezone-*.log');

        return self::SUCCESS;
    }
}
