<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use App\Domain\Order\OrderService;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Splits one delivered order's profit among the deals whose stock it sold, and writes each
 * investor's share into his ledger.
 *
 * **The number is the order's own.** `grand_total − total_cogs`, exactly as the order screen
 * already shows it — not the profit-and-loss report's different figure, which excludes the
 * delivery fee, the additional charge and the discount. Taking the order's own number is what
 * makes the discount and a post-deduction shortage fall out by construction: both move
 * `grand_total`, and whatever is left is what gets split.
 *
 * **Written once, at «تم الاستلام».** Before delivery an order can still come home and be
 * cancelled, and its profit with it. After delivery the state machine allows only «تم التسوية»,
 * `UpdateOrder` refuses every edit on a closed order, and `total_cogs` was frozen at «جاهزة» —
 * so the figure can never move again and a written row never needs restating. The practical
 * consequence, which is worth knowing rather than discovering: the «لماذا سُحب منّي» log will
 * almost never fire for an order. It fires for expenses, damage, and corrections.
 *
 * ## How one order's profit reaches one investor
 *
 * ```
 * E(O)          = grand_total − items_total        the order-level extras, net of the discount
 * line_revenue  = line_total + share of E(O)       allocated across lines by line_total
 * per draw c    revenue    = share of line_revenue    ← by quantity, over EVERY draw of the
 *               conversion = share of the line's        movement, the company's included
 *                            labour + overhead + outsourcing
 *               material   = c.total_cost exactly     ← never allocated; it is already exact
 *               profit(c)  = revenue − conversion − material
 * deal slice    = Σ profit(c) for that deal's draws
 * investors     = slice × investor_profit_share_percent ÷ 100
 * each investor = largest-remainder split of that over share_percent
 * ```
 *
 * The denominator is the whole movement. A line that drew 1,000 units from a deal and 2,000 from
 * the company's own stock gives the deal a third of the line's money — allocating across the
 * deal's rows alone would hand it all of it, because a proportional split distributes its total
 * across whatever weights it is given.
 */
final class PostDealEarningsForOrder
{
    /** The statuses at which an order's figures can no longer move. */
    private const RECOGNISED = ['delivered', 'settled'];

    public function __construct(
        private readonly OrderService $orders,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * @return list<InvestorWalletEntry> the rows written, empty when there was nothing to post
     */
    public function __invoke(int $orderId): array
    {
        $order = $this->orders->profitAttributionFor($orderId);

        if ($order === null
            || ! in_array($order['status'], self::RECOGNISED, true)
            || $order['gross_profit'] === null
            || $order['lines'] === []) {
            return [];
        }

        $slices = $this->sliceByDeal($order);

        if ($slices === []) {
            return [];
        }

        return DB::transaction(function () use ($slices, $orderId): array {
            $written = [];

            // Ascending by id, always — the deadlock discipline this whole context shares with
            // CreditBackStockBatches.
            ksort($slices);

            foreach ($slices as $dealId => $slice) {
                $deal = InvestorDeal::query()->whereKey($dealId)->lockForUpdate()->first();

                if ($deal === null) {
                    continue;
                }

                foreach ($this->rowsFor($deal, $slice, $orderId) as $row) {
                    $written[] = $row;
                }
            }

            return $written;
        });
    }

    /**
     * Each deal's share of this order's profit, keyed by deal id.
     *
     * @param  array<string, mixed>  $order
     * @return array<int, string>
     */
    private function sliceByDeal(array $order): array
    {
        $extras = bcsub($order['grand_total'], $order['items_total'], 2);

        $lineTotals = array_map(fn (array $line) => $line['line_total'], $order['lines']);
        $extraShares = Money::allocate($extras, array_map(
            // Weights must not be negative, and a line total never is.
            fn (string $total) => $total,
            $lineTotals,
        ));

        $breakdown = $this->inventory->consumptionBreakdownFor(
            array_map(fn (array $line) => $line['movement_id'], $order['lines']),
        );

        $slices = [];

        foreach ($order['lines'] as $index => $line) {
            $draws = $breakdown[$line['movement_id']] ?? [];

            if ($draws === []) {
                continue;
            }

            $lineRevenue = bcadd($line['line_total'], $extraShares[$index] ?? '0.00', 2);
            $weights = array_map(fn (array $draw) => $draw['quantity'], $draws);

            $revenue = Money::allocate($lineRevenue, $weights);
            $conversion = Money::allocate($line['conversion_cost'], $weights);

            foreach ($draws as $position => $draw) {
                $dealId = $draw['investor_deal_id'];

                if ($dealId === null) {
                    continue;
                }

                $profit = bcsub(
                    bcsub($revenue[$position] ?? '0.00', $conversion[$position] ?? '0.00', 2),
                    $draw['total_cost'],
                    2,
                );

                $slices[$dealId] = bcadd($slices[$dealId] ?? '0.00', $profit, 2);
            }
        }

        return array_filter($slices, fn (string $slice) => bccomp($slice, '0', 2) !== 0);
    }

    /**
     * Turns one deal's slice into one row per investor — or leaves what already stands alone.
     *
     * Idempotent by comparison rather than by hope: the same order delivered twice, or a status
     * walked twice, computes the same figures and writes nothing the second time. The partial
     * unique index behind `(investor, deal, source, sequence)` is the database's own backstop for
     * the day a future caller forgets the lock.
     *
     * @return list<InvestorWalletEntry>
     */
    private function rowsFor(InvestorDeal $deal, string $slice, int $orderId): array
    {
        $investorsAmount = $this->applyPercent($slice, (string) $deal->investor_profit_share_percent);

        if (bccomp($investorsAmount, '0', 2) === 0) {
            return [];
        }

        $shares = $deal->shares()->get();

        if ($shares->isEmpty()) {
            return [];
        }

        $amounts = Money::allocate(
            $investorsAmount,
            $shares->map(fn ($share) => (string) $share->share_percent)->all(),
        );

        $standing = InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('source_type', AuditSubject::Order->value)
            ->where('source_id', $orderId)
            ->whereIn('type', [WalletEntryType::Profit->value, WalletEntryType::Loss->value])
            ->whereDoesntHave('reversedBy')
            ->get()
            ->keyBy('investor_id');

        $target = [];

        foreach ($shares as $index => $share) {
            $target[(int) $share->investor_id] = $amounts[$index] ?? '0.00';
        }

        if ($this->matches($standing, $target)) {
            return [];
        }

        $sequence = 1 + (int) InvestorWalletEntry::query()
            ->where('investor_deal_id', $deal->getKey())
            ->where('source_type', AuditSubject::Order->value)
            ->where('source_id', $orderId)
            ->max('source_sequence');

        foreach ($standing as $entry) {
            $this->reverse($entry);
        }

        $written = [];

        foreach ($target as $investorId => $amount) {
            if (bccomp($amount, '0', 2) === 0) {
                continue;
            }

            $isLoss = bccomp($amount, '0', 2) < 0;

            $entry = new InvestorWalletEntry([
                'amount' => $isLoss ? substr($amount, 1) : $amount,
                'occurred_at' => now(),
            ]);

            $entry->investor_id = $investorId;
            $entry->investor_deal_id = $deal->getKey();
            $entry->type = $isLoss ? WalletEntryType::Loss : WalletEntryType::Profit;
            $entry->source_type = AuditSubject::Order->value;
            $entry->source_id = $orderId;
            $entry->source_sequence = $sequence;
            $entry->save();

            $written[] = $entry;
        }

        return $written;
    }

    /**
     * The investors' share of a slice, with the sign carried across.
     *
     * A loss is split by the same percentage as a profit — «لو خسرنا نتقاسمها زي مانتقاسم
     * الربح».
     */
    private function applyPercent(string $slice, string $percent): string
    {
        $negative = bccomp($slice, '0', 2) < 0;
        $magnitude = $negative ? substr($slice, 1) : $slice;

        $amount = Money::round(bcdiv(bcmul($magnitude, $percent, 8), '100', 8));

        return $negative && bccomp($amount, '0', 2) !== 0 ? '-'.$amount : $amount;
    }

    /**
     * @param  Collection<int, InvestorWalletEntry>  $standing
     * @param  array<int, string>  $target
     */
    private function matches($standing, array $target): bool
    {
        $current = [];

        foreach ($standing as $entry) {
            $signed = $entry->type === WalletEntryType::Loss
                ? '-'.$entry->amount
                : (string) $entry->amount;

            $current[(int) $entry->investor_id] = $signed;
        }

        $wanted = array_filter($target, fn (string $amount) => bccomp($amount, '0', 2) !== 0);

        if (array_keys($current) !== array_keys($wanted)) {
            return false;
        }

        foreach ($wanted as $investorId => $amount) {
            if (bccomp($current[$investorId], $amount, 2) !== 0) {
                return false;
            }
        }

        return true;
    }

    private function reverse(InvestorWalletEntry $entry): void
    {
        $reversal = new InvestorWalletEntry([
            'amount' => (string) $entry->amount,
            'occurred_at' => now(),
            'notes' => 'تصحيح إسناد ربح الطلبية',
        ]);

        $reversal->investor_id = $entry->investor_id;
        $reversal->investor_deal_id = $entry->investor_deal_id;
        $reversal->type = WalletEntryType::Reversal;
        $reversal->reverses_entry_id = $entry->getKey();
        $reversal->save();
    }
}
