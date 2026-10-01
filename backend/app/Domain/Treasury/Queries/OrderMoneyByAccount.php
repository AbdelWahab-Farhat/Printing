<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * How much of one order's money sits in each account of a kind — what «التجميع عند التسوية»
 * carries on. TREASURY-DESIGN §١٨.
 *
 * Every movement carries its order, so this is a sum: the payments that landed there, less a
 * refund paid from there, less any reversal, less what a collection already carried on.
 */
final class OrderMoneyByAccount
{
    /**
     * @param  list<int>  $except  accounts left where they are — the collecting one, and whatever
     *                             was picked by hand on the settle screen
     * @return array<int, string> account id => what it holds for this order, > 0 only
     */
    public function of(int $orderId, AccountKind $kind, array $except = []): array
    {
        $rows = DB::table('treasury_movements as m')
            ->join('treasury_accounts as a', 'a.id', '=', 'm.account_id')
            ->where('m.order_id', $orderId)
            ->where('a.kind', $kind->value)
            ->where('a.is_collected', true)
            ->when($except !== [], fn ($q) => $q->whereNotIn('m.account_id', $except))
            ->whereNull('m.deleted_at')
            ->groupBy('m.account_id')
            ->selectRaw("m.account_id, SUM(CASE WHEN m.direction = 'in' THEN m.amount ELSE -m.amount END) AS held")
            ->orderBy('m.account_id')
            ->pluck('held', 'account_id');

        $held = [];

        foreach ($rows as $accountId => $amount) {
            $amount = Money::round((string) $amount);

            if (Money::isPositive($amount)) {
                $held[(int) $accountId] = $amount;
            }
        }

        return $held;
    }
}
