<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Queries;

use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use Illuminate\Support\Facades\Cache;

/**
 * Each method's fee rate for the methods list — quoted at a reference amount and kept for hours.
 *
 * **A quote that failed is remembered for a minute, never as 0 %** (Primula cached a failure as a
 * free method for eight hours): the method is left out of the list meanwhile. What a customer is
 * actually charged is quoted again at the real amount when the top-up starts.
 */
final class MethodRates
{
    private const REFERENCE_AMOUNT = '100.00';

    private const FAILED = 'failed';

    private const METHODS = 'ezone:method-bounds';

    public function __construct(private readonly OnlinePaymentGateway $gateway) {}

    /** The rate as a fraction, or null while the provider will not quote it. */
    public function of(OnlineMethod $method): ?string
    {
        $key = "ezone:rate:{$method->value}";
        $cached = Cache::get($key);

        if ($cached === self::FAILED) {
            return null;
        }

        if (is_string($cached)) {
            return $cached;
        }

        // A failure here *is* the answer — the method is hidden — so it is read with `rescue`, the
        // probe RULES §5 allows, rather than a `catch`.
        $rate = rescue(fn () => $this->gateway->quote($method, self::REFERENCE_AMOUNT, reverse: false)->rate, null, report: false);

        if ($rate === null) {
            Cache::put($key, self::FAILED, (int) config('ezone_pay.rate_failure_seconds', 60));

            return null;
        }

        Cache::put($key, $rate, (int) config('ezone_pay.rate_cache_seconds', 8 * 3600));

        return $rate;
    }

    /**
     * What the merchant account offers: id => the least and the most one charge may be. Cached
     * like the rates; empty while the provider cannot be reached.
     *
     * @return array<int, array{min: ?string, max: ?string}>
     */
    public function merchantMethods(): array
    {
        // Not `ezone:methods`: that key held the older shape (id => max), and a cache surviving
        // the deploy must not be read as this one.
        $cached = Cache::get(self::METHODS);

        if (is_array($cached)) {
            return $cached;
        }

        $methods = rescue(fn () => $this->gateway->methods(), null, report: false);

        if (! is_array($methods)) {
            return [];
        }

        Cache::put(self::METHODS, $methods, (int) config('ezone_pay.rate_cache_seconds', 8 * 3600));

        return $methods;
    }
}
