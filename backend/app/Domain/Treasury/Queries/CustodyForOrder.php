<?php

declare(strict_types=1);

namespace App\Domain\Treasury\Queries;

use App\Domain\Treasury\Enums\AccountKind;
use App\Domain\Treasury\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * How much of one order's money is still in somebody else's hands, per custody account.
 *
 * Every movement carries its order, so this is a sum: the payments Nawris collected, less any
 * reversal of them, less what a settlement already carried on. TREASURY-DESIGN §٦.
 */
final class CustodyForOrder
{
    /**
     * @return array<int, string> custody account id => what it still holds for this order, > 0 only
     */
    public function of(int $orderId): array
    {
        $rows = DB::table('treasury_movements as m')
            ->join('treasury_accounts as a', 'a.id', '=', 'm.account_id')
            ->where('m.order_id', $orderId)
            ->where('a.kind', AccountKind::Custody->value)
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

    public function total(int $orderId): string
    {
        return Money::sum('0', ...array_values($this->of($orderId)));
    }
}
