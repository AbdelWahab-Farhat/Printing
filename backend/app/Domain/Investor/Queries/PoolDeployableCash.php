<?php

declare(strict_types=1);

namespace App\Domain\Investor\Queries;

use App\Domain\Investor\Support\Money;

/**
 * How much a pool can actually spend — derived, never stored.
 *
 * ## The identity
 *
 * ```
 * book value      = Σ capital_deal(pool) + Σ profit_deal(pool)      from the ledger
 * stock at cost   = cost of every layer carrying this pool          from the cost layers
 *
 * deployable cash = book value − stock at cost
 * ```
 *
 * **There is no cash ledger, and there must not be one.** A pool's money is in exactly two shapes
 * at any moment — cash it has not spent, and goods it bought with it — so knowing the book value
 * and the goods gives the cash by subtraction. A third table counting cash could only ever come to
 * disagree with the two that already know, and it is the one somebody would eventually trust.
 *
 * ## What this «cash» actually is
 *
 * A **book claim on the company**, not notes in a drawer. Profit is recognised at delivery, so an
 * order delivered and not yet collected from the customer counts here. That is deliberate and
 * inherited from the deal model; uncollected customer debt against a pool's sales is a named line
 * in the settlement rather than a silent gap in this figure.
 *
 * ## What is deliberately excluded
 *
 * **Undrawn profit.** Once a period closes, an investor's share moves to his *wallet* — out of
 * `profit_deal` and into `profit_wallet` — and leaves this sum by construction. It is money the
 * company holds and does not own, and a purchase made with it would be spending someone's settled
 * earnings. The owner's ruling, and the reason the dashboard prints two figures and never their
 * total.
 */
final class PoolDeployableCash
{
    public function __construct(
        private readonly InvestorBalances $balances,
        private readonly DealStockPosition $stockPosition,
    ) {}

    /**
     * @return array{book_value: string, stock_at_cost: string, deployable_cash: string, capital: string, unsettled_profit: string}
     */
    public function __invoke(int $poolId): array
    {
        $ledger = $this->balances->forDeal($poolId);
        $stock = ($this->stockPosition)($poolId);

        $bookValue = bcadd($ledger['capital'], $ledger['profit'], 2);

        return [
            'capital' => $ledger['capital'],
            // The current period's earnings, not yet divided and not yet withdrawable. Part of the
            // pool's book value, so it is spendable on the next lorry — which is exactly the
            // «إعادة تدوير الأموال» the whole design is for.
            'unsettled_profit' => $ledger['profit'],
            'book_value' => Money::round($bookValue),
            'stock_at_cost' => $stock['cost_remaining'],
            'deployable_cash' => Money::round(bcsub($bookValue, $stock['cost_remaining'], 2)),
        ];
    }

    /** Whether the pool can cover a cost — the one question a purchase asks. */
    public function covers(int $poolId, string $cost): bool
    {
        return bccomp($this->__invoke($poolId)['deployable_cash'], $cost, 2) >= 0;
    }
}
