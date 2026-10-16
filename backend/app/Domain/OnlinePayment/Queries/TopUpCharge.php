<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Queries;

use App\Domain\OnlinePayment\Enums\FeePayer;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Exceptions\GatewayRejected;
use App\Domain\OnlinePayment\Exceptions\OnlinePaymentRefused;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Support\FeeCalculator;
use App\Domain\OnlinePayment\Support\Money;
use Illuminate\Support\Facades\Cache;

/**
 * What one top-up costs — **EzonePay's own quote, at the real amount**, for the screen and the
 * start alike. CUSTOMER-WALLET §٥.
 *
 * - **The customer pays the fee**: EzonePay is asked in reverse — what to charge so `net` reaches
 *   the shop — and works it out by its own rule for the method (EdfaLi under 100 included). The
 *   charge rounds **up** to the hundredth: it is sent at two places, and the shop never receives
 *   less than the wallet is given.
 * - **The shop pays it**: the customer is charged `net`, and EzonePay says what it keeps of that.
 *
 * Kept a quarter of an hour by method, payer and amount, so the start charges exactly what the
 * screen showed. Then the method's own bounds at EzonePay: the least and the most one payment may
 * charge.
 */
final class TopUpCharge
{
    public function __construct(
        private readonly OnlinePaymentGateway $gateway,
        private readonly MethodRates $rates,
        private readonly FeeCalculator $fees,
    ) {}

    /**
     * @return array{gross: string, fee: string, rate: string}
     */
    public function of(OnlineMethod $method, string $net, FeePayer $payer): array
    {
        $key = "ezone:charge:{$method->value}:{$payer->value}:{$net}";
        $charge = Cache::get($key);

        if (! is_array($charge)) {
            $charge = $this->ask($method, $net, $payer);
            Cache::put($key, $charge, (int) config('ezone_pay.quote_cache_seconds', 900));
        }

        $this->guardBounds($method, $charge['gross'], $charge['rate'], $payer);

        return $charge;
    }

    /**
     * @return array{gross: string, fee: string, rate: string}
     */
    private function ask(OnlineMethod $method, string $net, FeePayer $payer): array
    {
        $onCustomer = $payer === FeePayer::Customer;
        $quote = $this->gateway->quote($method, $net, reverse: $onCustomer);
        $gross = $onCustomer ? Money::ceil($quote->charge) : Money::round($net);

        // A quote that would leave the shop short, or a negative fee, is not a price.
        if (bccomp($gross, $net, 2) < 0 || bccomp($quote->fee, '0', 3) < 0) {
            throw GatewayRejected::make('تعذّر حساب عمولة هذه الطريقة', 'method');
        }

        return ['gross' => $gross, 'fee' => Money::round($quote->fee), 'rate' => $quote->rate];
    }

    private function guardBounds(OnlineMethod $method, string $gross, string $rate, FeePayer $payer): void
    {
        $bounds = $this->rates->merchantMethods()[$method->value] ?? ['min' => null, 'max' => null];

        if ($bounds['min'] !== null && bccomp($gross, $bounds['min'], 2) < 0) {
            throw OnlinePaymentRefused::belowProviderMinimum($bounds['min']);
        }

        if ($bounds['max'] !== null && bccomp($gross, $bounds['max'], 2) > 0) {
            throw OnlinePaymentRefused::aboveProviderCap($this->fees->largestNet($bounds['max'], $rate, $payer));
        }
    }
}
