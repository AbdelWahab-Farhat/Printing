<?php

declare(strict_types=1);

namespace App\Domain\OnlinePayment;

use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\OnlinePayment\Actions\ConfirmTopUpOtp;
use App\Domain\OnlinePayment\Actions\RecheckTopUp;
use App\Domain\OnlinePayment\Actions\RecordEzonePayout;
use App\Domain\OnlinePayment\Actions\StartTopUp;
use App\Domain\OnlinePayment\DTOs\OnlineTopUpData;
use App\Domain\OnlinePayment\Enums\FeePayer;
use App\Domain\OnlinePayment\Enums\OnlineMethod;
use App\Domain\OnlinePayment\Exceptions\GatewayUnavailable;
use App\Domain\OnlinePayment\Exceptions\OnlinePaymentRefused;
use App\Domain\OnlinePayment\Gateway\OnlinePaymentGateway;
use App\Domain\OnlinePayment\Models\OnlinePaymentMethod;
use App\Domain\OnlinePayment\Models\PaymentIntent;
use App\Domain\OnlinePayment\Queries\MethodRates;
use App\Domain\OnlinePayment\Queries\TopUpCharge;
use App\Domain\OnlinePayment\Queries\TopUpLimits;
use App\Domain\OnlinePayment\Support\FeeCalculator;
use App\Domain\Treasury\Models\TreasuryOperation;
use App\Domain\Treasury\TreasuryService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;

/**
 * The door to online top-ups — Docs/payments/CUSTOMER-WALLET.md §٥. The customer app starts,
 * confirms and watches its own attempts; staff list them, recheck one, set the methods and their
 * limits, and record EzonePay's payouts.
 */
final class OnlinePaymentService
{
    public function __construct(
        private readonly OnlinePaymentGateway $gateway,
        private readonly MethodRates $rates,
        private readonly FeeCalculator $fees,
        private readonly TopUpLimits $limits,
        private readonly TopUpCharge $charge,
        private readonly TreasuryService $treasury,
        private readonly StartTopUp $start,
        private readonly ConfirmTopUpOtp $confirm,
        private readonly RecheckTopUp $recheck,
        private readonly RecordEzonePayout $payout,
    ) {}

    public function isEnabled(): bool
    {
        return $this->gateway->isEnabled();
    }

    public function feePayer(): FeePayer
    {
        return FeePayer::from((string) ($this->treasury->settings()->online_fee_payer ?? 'customer'));
    }

    // ── the customer ────────────────────────────────────────────────────────────────────

    /**
     * What this customer may top up with now: active here, offered by the merchant account, and
     * with a fee rate the provider would quote. Each with its fee and what is left of its limits.
     * Empty while online payments are off.
     *
     * @return list<array{method: OnlineMethod, rate: string, max_net: ?string, limits: array<string, array{limit: ?string, used: string, remaining: ?string}>}>
     */
    public function methodsFor(Customer $customer): array
    {
        if (! $this->isEnabled()) {
            return [];
        }

        $active = OnlinePaymentMethod::query()->where('is_active', true)->pluck('method')
            ->map(fn ($method) => $method instanceof OnlineMethod ? $method->value : (int) $method)
            ->all();
        $offered = $this->rates->merchantMethods();
        $payer = $this->feePayer();
        $list = [];

        foreach (OnlineMethod::cases() as $method) {
            if (! in_array($method->value, $active, true) || ($offered !== [] && ! array_key_exists($method->value, $offered))) {
                continue;
            }

            $rate = $this->rates->of($method);

            if ($rate === null) {
                continue;
            }

            $max = $offered[$method->value]['max'] ?? null;

            $list[] = [
                'method' => $method,
                'rate' => $rate,
                'max_net' => $max === null ? null : $this->fees->largestNet($max, $rate, $payer),
                'limits' => $this->limits->of((int) $customer->getKey(), $method),
            ];
        }

        // Libyana first — the method most customers have (Primula pinned it too).
        usort($list, fn (array $a, array $b) => ($b['method'] === OnlineMethod::Libyana) <=> ($a['method'] === OnlineMethod::Libyana));

        return $list;
    }

    /**
     * What the customer would be charged — the screen's «تضيف ١٠٠ ← تدفع ١٠٢٫٥٠». EzonePay's own
     * quote ({@see TopUpCharge}), the one the start charges.
     *
     * @return array{net: string, gross: string, fee: string, rate: string, fee_payer: FeePayer}
     */
    public function quote(OnlineMethod $method, string $net): array
    {
        if (! $this->isEnabled()) {
            throw GatewayUnavailable::notConfigured();
        }

        if ($this->rates->of($method) === null) {
            throw OnlinePaymentRefused::methodUnavailable($method->label());
        }

        $payer = $this->feePayer();
        $charge = $this->charge->of($method, $net, $payer);

        return [
            'net' => $net,
            'gross' => $charge['gross'],
            // What the customer pays on top — nothing when the shop carries the fee.
            'fee' => bcsub($charge['gross'], $net, 2),
            'rate' => $charge['rate'],
            'fee_payer' => $payer,
        ];
    }

    public function start(Customer $customer, OnlineTopUpData $data): PaymentIntent
    {
        return ($this->start)($customer, $data);
    }

    public function confirmOtp(PaymentIntent $intent, string $otp): PaymentIntent
    {
        return ($this->confirm)($intent, $otp);
    }

    /**
     * The attempt as the app polls it. **While EzonePay has the code but has not said it is
     * paid** ({@see PaymentIntent::isConfirming()}), it is asked again — at most every ten seconds
     * however often the app polls, and a failure to ask leaves the answer as it was: the poll
     * never errs because EzonePay did. Every other attempt is read as it stands.
     */
    public function watch(PaymentIntent $intent): PaymentIntent
    {
        if (! $intent->isConfirming() || ! Cache::add("ezone:watch:{$intent->getKey()}", true, 10)) {
            return $intent;
        }

        // The probe RULES §5 allows `rescue` for: not asking is an answer here.
        return rescue(fn () => ($this->recheck)($intent), $intent, report: false);
    }

    /** The customer's own attempt by its public id — another customer's is a 404. */
    public function findForCustomer(Customer $customer, string $uuid): PaymentIntent
    {
        return PaymentIntent::query()
            ->where('customer_id', $customer->getKey())
            ->where('uuid', $uuid)
            ->firstOrFail();
    }

    // ── staff ───────────────────────────────────────────────────────────────────────────

    public function recheck(PaymentIntent $intent): PaymentIntent
    {
        return ($this->recheck)($intent);
    }

    /**
     * «المدفوعات الإلكترونية» — newest first.
     *
     * @param  array{status?: ?string, method?: ?int, customer_id?: ?int, q?: ?string}  $filters
     * @return LengthAwarePaginator<int, PaymentIntent>
     */
    public function intents(array $filters, int $perPage): LengthAwarePaginator
    {
        return PaymentIntent::query()
            ->when($filters['status'] ?? null, fn ($q, $status) => $q->where('status', $status))
            ->when($filters['method'] ?? null, fn ($q, $method) => $q->where('method', $method))
            ->when($filters['customer_id'] ?? null, fn ($q, $id) => $q->where('customer_id', $id))
            ->when(trim((string) ($filters['q'] ?? '')), fn ($q, $term) => $q->where(fn ($match) => $match
                ->where('our_reference', 'ilike', "%{$term}%")
                ->orWhereHas('customer', fn ($c) => $c
                    ->where('name', 'ilike', "%{$term}%")
                    ->orWhere('phone', 'ilike', "%{$term}%"))))
            ->with('customer')
            ->orderByDesc('id')
            ->paginate($perPage);
    }

    /**
     * Every method with its switch and its limits, in EzonePay's order.
     *
     * @return Collection<int, OnlinePaymentMethod>
     */
    public function methodSettings(): Collection
    {
        return OnlinePaymentMethod::query()->orderBy('method')->get();
    }

    /**
     * @param  array{is_active?: bool, daily_limit?: ?string, monthly_limit?: ?string, yearly_limit?: ?string}  $values
     */
    public function updateMethod(OnlinePaymentMethod $method, array $values, ?User $actor): OnlinePaymentMethod
    {
        $method->fill($values);
        $method->forceFill(['updated_by' => $actor?->getKey()])->save();

        return $method;
    }

    /** Step 6 — see {@see RecordEzonePayout}. */
    public function recordPayout(
        string $received,
        ?string $kept,
        ?int $bankAccountId,
        Carbon $occurredAt,
        ?string $reference,
        ?User $actor,
        ?string $clientToken = null,
    ): TreasuryOperation {
        return ($this->payout)($received, $kept, $bankAccountId, $occurredAt, $reference, $actor, $clientToken);
    }
}
