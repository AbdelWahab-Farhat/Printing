<?php

declare(strict_types=1);

namespace App\Domain\Wallet\Queries;

use App\Domain\Wallet\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * What each wallet holds — the sum of its rows, never a stored figure.
 *
 * A reversal has no direction of its own: it moves the opposite way to the row it undoes, so the
 * query reads that row's type through a self-join. One grouped query for any number of customers.
 */
final class WalletBalances
{
    private const CREDITS = "('topup', 'order_refund', 'adjustment_credit')";

    private const DEBITS = "('order_payment', 'adjustment_debit')";

    /**
     * @param  list<int>  $customerIds
     * @return array<int, string> customer id => balance, every asked-for customer present
     */
    public function forCustomers(array $customerIds): array
    {
        if ($customerIds === []) {
            return [];
        }

        $rows = DB::table('customer_wallet_entries as e')
            ->leftJoin('customer_wallet_entries as o', 'o.id', '=', 'e.reverses_entry_id')
            ->whereNull('e.deleted_at')
            ->whereIn('e.customer_id', $customerIds)
            ->groupBy('e.customer_id')
            ->selectRaw('e.customer_id, '.self::signedSum().' AS balance')
            ->pluck('balance', 'customer_id');

        $balances = [];

        foreach ($customerIds as $id) {
            $balances[$id] = Money::round((string) ($rows[$id] ?? '0'));
        }

        return $balances;
    }

    public function of(int $customerId): string
    {
        return $this->forCustomers([$customerId])[$customerId];
    }

    /** Every wallet together — what the shop owes its customers. For `wallets:check`. */
    public function total(): string
    {
        $total = DB::table('customer_wallet_entries as e')
            ->leftJoin('customer_wallet_entries as o', 'o.id', '=', 'e.reverses_entry_id')
            ->whereNull('e.deleted_at')
            ->selectRaw(self::signedSum().' AS total')
            ->value('total');

        return Money::round((string) ($total ?? '0'));
    }

    /**
     * The customers whose wallet is below zero — which no path may produce. For `wallets:check`.
     *
     * @return array<int, string> customer id => balance
     */
    public function negative(): array
    {
        return DB::table('customer_wallet_entries as e')
            ->leftJoin('customer_wallet_entries as o', 'o.id', '=', 'e.reverses_entry_id')
            ->whereNull('e.deleted_at')
            ->groupBy('e.customer_id')
            ->havingRaw(self::signedSum().' < 0')
            ->selectRaw('e.customer_id, '.self::signedSum().' AS balance')
            ->pluck('balance', 'customer_id')
            ->map(fn ($balance) => Money::round((string) $balance))
            ->all();
    }

    private static function signedSum(): string
    {
        return 'COALESCE(SUM(CASE'
            .' WHEN e.type IN '.self::CREDITS.' THEN e.amount'
            .' WHEN e.type IN '.self::DEBITS.' THEN -e.amount'
            .' WHEN o.type IN '.self::CREDITS.' THEN -e.amount'
            .' ELSE e.amount END), 0)';
    }
}
