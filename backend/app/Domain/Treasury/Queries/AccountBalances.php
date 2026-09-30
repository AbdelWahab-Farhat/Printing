<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * What each account holds — the sum of its movements, never a stored figure.
 *
 * One grouped query for any number of accounts, so the dashboard costs the same with four
 * accounts or forty.
 */
final class AccountBalances
{
    /**
     * @param  list<int>|null  $accountIds  null for every account
     * @return array<int, string> account id => balance, every asked-for account present
     */
    public function forAccounts(?array $accountIds = null): array
    {
        $rows = DB::table('treasury_movements')
            ->whereNull('deleted_at')
            ->when($accountIds !== null, fn ($q) => $q->whereIn('account_id', $accountIds))
            ->groupBy('account_id')
            ->selectRaw("account_id, SUM(CASE WHEN direction = 'in' THEN amount ELSE -amount END) AS balance")
            ->pluck('balance', 'account_id');

        $balances = [];

        foreach ($accountIds ?? array_map('intval', $rows->keys()->all()) as $id) {
            $balances[(int) $id] = Money::round((string) ($rows[$id] ?? '0'));
        }

        return $balances;
    }

    public function of(int $accountId): string
    {
        return $this->forAccounts([$accountId])[$accountId];
    }
}
