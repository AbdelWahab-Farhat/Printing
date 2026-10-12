<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Support;

use App\Domain\OnlinePayment\Enums\FeePayer;
use App\Domain\OnlinePayment\Queries\TopUpCharge;

/**
 * EzonePay's fee, worked out on our side — **for what EzonePay has not said**. The price a
 * customer is shown and charged is EzonePay's own quote ({@see TopUpCharge});
 * this is the fee booked when a transaction comes back without one, the biggest net a capped
 * method allows, and the pretend gateway's arithmetic.
 *
 * **EzonePay keeps `r` of the whole charge, on every method** — what the sandbox answered on
 * 2026-10-11: 100 to reach the shop is 102.565 charged and 2.565 kept; 123.08 charged keeps 3.078.
 *
 * | | customer pays | shop pays |
 * |---|---|---|
 * | charged | `net ÷ (1 − r)` | `net` |
 * | EzonePay keeps | `charged × r` | the same |
 *
 * `r` is a fraction — 0.025 for 2.5 %. Totals round **up** to the hundredth, so the wallet never
 * receives a dirham more than reached the shop.
 */
final class FeeCalculator
{
    /**
     * @return array{gross: string, fee: string}
     */
    public function charge(string $net, string $rate, FeePayer $payer): array
    {
        $gross = $payer === FeePayer::Shop
            ? Money::round($net)
            : Money::ceil(bcdiv($net, bcsub('1', $rate, 8), 8));

        return ['gross' => $gross, 'fee' => $this->expectedFee($gross, $rate)];
    }

    /** What EzonePay keeps of a charge — used until it says what it kept. */
    public function expectedFee(string $gross, string $rate): string
    {
        return Money::round(bcmul($gross, $rate, 8));
    }

    /**
     * The most a customer can put in the wallet when the provider caps the charge at `max`.
     */
    public function largestNet(string $maxCharge, string $rate, FeePayer $payer): string
    {
        $net = $payer === FeePayer::Shop ? $maxCharge : bcmul($maxCharge, bcsub('1', $rate, 8), 8);

        // Down, not to the nearest: a net rounded up would charge past the cap.
        return bcadd($net, '0', Money::SCALE);
    }
}
