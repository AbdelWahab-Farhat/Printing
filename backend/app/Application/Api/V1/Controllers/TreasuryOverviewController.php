<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\Inventory\InventoryService;
use App\Domain\Investor\InvestorService;
use App\Domain\Treasury\Models\TreasuryAccount;
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
     */
    public function ownership(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $total = '0';
        // A payable's balance is the debt below zero, so adding it subtracts what is owed.
        $payables = '0';

        foreach ($this->treasury->accountsFor($user, activeOnly: true) as $account) {
            /** @var TreasuryAccount $account */
            if ($account->kind->holdsMoney()) {
                $total = bcadd($total, (string) $account->getAttribute('balance'), 2);
            } else {
                $payables = bcadd($payables, (string) $account->getAttribute('balance'), 2);
            }
        }

        $held = $this->investors->moneyHeldForInvestors();

        $forInvestors = '0';

        foreach ($held['investors'] as $row) {
            $forInvestors = bcadd($forInvestors, bcadd($row['capital'], $row['profit'], 2), 2);
        }

        return $this->success([
            'total_held' => $total,
            'investors' => $held['investors'],
            'investors_total' => $forInvestors,
            'fund_cash' => $held['fund_cash'],
            'payables_total' => bcmul($payables, '-1', 2),
            'company_own' => bcadd(bcsub(bcsub($total, $forInvestors, 2), $held['fund_cash'], 2), $payables, 2),
        ]);
    }

    public function inventoryValue(): JsonResponse
    {
        return $this->success($this->inventory->inventoryValue());
    }
}
