<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\InvestorService;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Support\Money;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The two cards under the accounts: whose the money is, and what the shelves are worth.
 *
 * **Composed here, not in Treasury**, because it reads three contexts and Treasury may import
 * none of them — this layer is where they meet (RULES §3).
 */
class TreasuryOverviewController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly TreasuryService $treasury,
        private readonly InvestorService $investors,
        private readonly InventoryService $inventory,
    ) {}

    /**
     * «لمن المال» — TREASURY-DESIGN §٩. What the drawers hold, less what is being kept for the
     * investors and the fund, less what the company owes (§٢٠), is what is the company's own.
     *
     * **Dollars count at «سعر النظام»** (USD-ACCOUNTS §٣) — left out, buying $1,000 would read
     * as the company losing seven thousand dinars. Until the owner writes a rate they cannot be
     * valued, so the dinar figures leave them out and `usd_rate` comes back null for the app to
     * say so; the dollar figures are always there beside them.
     */
    public function ownership(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $inHand = ['LYD' => '0', 'USD' => '0'];
        // A payable's balance is the debt below zero, so adding it subtracts what is owed.
        $owed = ['LYD' => '0', 'USD' => '0'];

        foreach ($this->treasury->accountsFor($user, activeOnly: true) as $account) {
            /** @var TreasuryAccount $account */
            $currency = $account->currency->value;
            $balance = (string) $account->getAttribute('balance');

            if ($account->kind->holdsMoney()) {
                $inHand[$currency] = bcadd($inHand[$currency], $balance, 2);
            } else {
                $owed[$currency] = bcadd($owed[$currency], $balance, 2);
            }
        }

        $rate = $this->treasury->settings()->usd_rate;
        $inDinars = fn (string $dollars): string => $rate === null ? '0.00' : Money::round(bcmul($dollars, (string) $rate, 8));

        $total = bcadd($inHand['LYD'], $inDinars($inHand['USD']), 2);
        $payables = bcadd($owed['LYD'], $inDinars($owed['USD']), 2);

        $held = $this->investors->moneyHeldForInvestors();

        $forInvestors = '0';

        foreach ($held['investors'] as $row) {
            $forInvestors = bcadd($forInvestors, bcadd($row['capital'], $row['profit'], 2), 2);
        }

        return $this->success([
            'total_held' => $total,
            // What the dollar accounts hold, in dollars, and that in dinars at «سعر النظام» —
            // already inside `total_held` when there is a rate, null when there is none.
            'usd_held' => bcadd($inHand['USD'], '0', 2),
            'usd_rate' => $rate === null ? null : (string) $rate,
            'usd_held_in_lyd' => $rate === null ? null : $inDinars($inHand['USD']),
            'investors' => $held['investors'],
            'investors_total' => $forInvestors,
            'fund_cash' => $held['fund_cash'],
            'payables_total' => bcmul($payables, '-1', 2),
            // What the vendors' dollar «علينا» owe, as a positive figure in dollars, and that in
            // dinars at «سعر النظام» — inside `payables_total` when there is a rate (§٤).
            'usd_payables' => bcmul($owed['USD'], '-1', 2),
            'usd_payables_in_lyd' => $rate === null ? null : bcmul($inDinars($owed['USD']), '-1', 2),
            'company_own' => bcadd(bcsub(bcsub($total, $forInvestors, 2), $held['fund_cash'], 2), $payables, 2),
        ]);
    }

    public function inventoryValue(): JsonResponse
    {
        return $this->success($this->inventory->inventoryValue());
    }
}
