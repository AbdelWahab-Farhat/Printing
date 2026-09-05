<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Support\Money;
use App\Domain\Investor\Support\OrderDealSlices;
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
 * deal slice    = OrderDealSlices — the order's money, split across the shelves it drew from
 * investors     = slice × investor_funded_percent ÷ 100 × investor_profit_share_percent ÷ 100
 * each investor = largest-remainder split of that over share_percent
 * ```
 *
 * The first line is {@see OrderDealSlices}, which is also what `GET /investor-deals/{deal}/orders`
 * reads to show a person the order behind his figure. The second is
 * {@see InvestorDeal::investorsCutOf()}, shared with the expense that is charged the same way:
 * the slice is what the deal's goods earned, all of it, and the partners own only the fraction of
 * those goods their money bought — the company is a partner for the rest. So the slice stays
 * whole on the deal's order screen, the investors' share shrinks, and the company's share is the
 * residual. The last line is this class's own, because it is the only part that concerns who
 * gets paid rather than what was earned.
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
     * The arithmetic itself is {@see OrderDealSlices}, shared with the screen that shows a person
     * why he was paid this — one definition, so the two can never come to disagree.
     *
     * @param  array<string, mixed>  $order
     * @return array<int, string>
     */
    private function sliceByDeal(array $order): array
    {
        return OrderDealSlices::profitsOf(OrderDealSlices::forOrder(
            $order,
            $this->inventory->consumptionBreakdownFor(
                array_map(fn (array $line) => $line['movement_id'], $order['lines']),
            ),
        ));
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
        $investorsAmount = $deal->investorsCutOf($slice);

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
