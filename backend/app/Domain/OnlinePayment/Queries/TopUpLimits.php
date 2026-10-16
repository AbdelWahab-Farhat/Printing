<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment\Queries;

use App\Domain\OnlinePayment\Enums\IntentStatus;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Exceptions\OnlinePaymentRefused;
use App\Domain\OnlinePayment\Models\OnlinePaymentMethod;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\OnlinePayment\Support\Money;
use Carbon\CarbonImmutable;

/**
 * How much one customer may still top up with one method — per day, month and year, in Libyan
 * days, in net terms (what reaches the wallet).
 *
 * **Usage counts what succeeded, and what is pending from the last half hour** (Primula counted
 * succeeded alone, so two quick top-ups could pass a cap). Landing exactly on the cap is allowed.
 * Checked when a top-up starts, under the customer's lock — not at settlement: by then the money
 * has moved.
 */
final class TopUpLimits
{
    private const PERIODS = [
        'daily' => 'اليومي',
        'monthly' => 'الشهري',
        'yearly' => 'السنوي',
    ];

    /**
     * @return array<string, array{limit: ?string, used: string, remaining: ?string}>
     */
    public function of(int $customerId, OnlineMethod $method): array
    {
        $setting = OnlinePaymentMethod::query()->where('method', $method->value)->first();
        $result = [];

        foreach (array_keys(self::PERIODS) as $period) {
            $limit = $setting?->{"{$period}_limit"};
            $used = $this->used($customerId, $method, $this->since($period));

            $result[$period] = [
                'limit' => $limit === null ? null : (string) $limit,
                'used' => $used,
                'remaining' => $limit === null ? null : $this->remaining((string) $limit, $used),
            ];
        }

        return $result;
    }

    /** Refuses `$net` when it would take any period past its cap. */
    public function guard(int $customerId, OnlineMethod $method, string $net): void
    {
        foreach ($this->of($customerId, $method) as $period => $row) {
            if ($row['limit'] === null) {
                continue;
            }

            if (bccomp(bcadd($row['used'], $net, 2), $row['limit'], 2) > 0) {
                throw OnlinePaymentRefused::limitExceeded(self::PERIODS[$period], $row['limit'], (string) $row['remaining']);
            }
        }
    }

    private function used(int $customerId, OnlineMethod $method, CarbonImmutable $since): string
    {
        $pendingSince = now()->subMinutes((int) config('ezone_pay.pending_counts_minutes', 30));

        $sum = PaymentIntent::query()
            ->where('customer_id', $customerId)
            ->where('method', $method->value)
            ->where('created_at', '>=', $since)
            ->where(fn ($q) => $q
                ->where('status', IntentStatus::Succeeded->value)
                ->orWhere(fn ($pending) => $pending
                    ->where('status', IntentStatus::Pending->value)
                    ->where('created_at', '>=', $pendingSince))
                // An attempt still being started — a twin of this one, a second ago. One the
                // provider refused stays `created` and stops counting after a minute.
                ->orWhere(fn ($starting) => $starting
                    ->where('status', IntentStatus::Created->value)
                    ->where('created_at', '>=', now()->subMinute())))
            ->sum('net_amount');

        return Money::round((string) $sum);
    }

    /** The first instant of the period, in Libyan time, as UTC. */
    private function since(string $period): CarbonImmutable
    {
        $now = CarbonImmutable::now((string) config('app.business_timezone', 'Africa/Tripoli'));

        $start = match ($period) {
            'daily' => $now->startOfDay(),
            'monthly' => $now->startOfMonth(),
            default => $now->startOfYear(),
        };

        return $start->utc();
    }

    /** What is left of a cap, never below zero. */
    private function remaining(string $limit, string $used): string
    {
        $left = bcsub($limit, $used, 2);

        return bccomp($left, '0', 2) < 0 ? '0.00' : Money::round($left);
    }
}
