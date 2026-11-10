<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\DTOs\PurchaseOrderAdditionalCostData;
use App\Domain\PurchaseOrder\Exceptions\PurchaseOrderCurrencyRefused;
use App\Domain\PurchaseOrder\Models\PurchaseOrder;
use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\TreasuryService;

/**
 * Keeps the money behind one of a purchase order's costs equal to the cost — PURCHASE-ORDER-
 * ARRIVAL-COSTS.md §3.
 *
 * A cost on the vendor's bill has no movement of its own: it is inside `vendor_amount`, and the
 * vendor's payable carries it ({@see SyncPurchaseOrderDebt}). A cost paid from a drawer, or owed
 * to a manual payable, is an `expense` out of that account, kept equal to the cost by
 * {@see TreasuryService::syncExpense()} — the vendor debt's own idempotent repost — so editing a
 * planned cost's amount or account reverses and reposts, and removing it reverses.
 *
 * Call after the row is saved or deleted, inside the same transaction.
 */
final class SyncAdditionalCostExpense
{
    public function __construct(private readonly TreasuryService $treasury) {}

    /**
     * @param  string|null  $amount  How much of it the company's own drawer stands for — less
     *                               than the cost when a deal carries the rest as its expense.
     *                               Null is all of it.
     */
    public function __invoke(
        PurchaseOrderAdditionalCost $cost,
        ?int $actorId,
        ?string $amount = null,
        ?string $reason = null,
    ): void {
        $live = ! $cost->trashed();
        $code = (string) $cost->purchase_order_id;
        $amount = $live ? ($amount ?? (string) $cost->amount) : '0';

        $this->treasury->syncExpense(
            sourceType: $cost->getMorphClass(),
            sourceId: (int) $cost->getKey(),
            accountId: $live ? $cost->treasury_account_id : null,
            amount: $amount,
            firstPostedAt: now(),
            notes: "{$cost->name} — أمر الشراء {$code}",
            reason: $reason ?? "تعديل أمر الشراء {$code}",
            actorId: $actorId,
            dinarAmount: $live && $cost->currency === Currency::Usd ? $this->inDinars($cost, $amount) : null,
        );
    }

    /**
     * A dollar cost out of a dollar drawer, in dinars for «المصاريف» — USD-ACCOUNTS.md §٨. At the
     * order's arrival rate once it is received, and at «سعر النظام» before: the rate of the day the
     * money left. The stock is priced at the arrival rate either way; this figure is the expense
     * tab's alone. {@see guardAccount()} made sure one of the two exists.
     */
    private function inDinars(PurchaseOrderAdditionalCost $cost, string $amount): ?string
    {
        $rate = $cost->purchaseOrder?->arrival_rate ?? $this->treasury->settings()->usd_rate;

        return $rate === null ? null : bcmul($amount, (string) $rate, 8);
    }

    /**
     * Refuses an account a cost cannot be charged to — see {@see TreasuryService::expenseAccount()}
     * — and a day the treasury is closed for. Before anything is written.
     *
     * **A dollar drawer pays a dollar order's cost alone** (USD-ACCOUNTS.md §٧): the cost is then
     * dollars, as the order is, and is priced into the stock at the arrival rate. On a dinar order
     * there is no rate to bring dollars into its lines. And the expense it posts is counted in
     * dinars for «المصاريف» — at the arrival rate, or «سعر النظام» before it — so one of the two
     * must exist. A dinar drawer pays a cost on any order, in dinars.
     *
     * @throws AccountDoesNotFitMethod
     * @throws PurchaseOrderCurrencyRefused
     */
    public function guardAccount(
        ?int $accountId,
        string $field,
        ?PurchaseOrder $order = null,
        // The arrival rate typed on the receive screen, before it is saved on the order.
        ?string $rateAtHand = null,
    ): void {
        if ($accountId === null) {
            return;
        }

        $chosen = TreasuryAccount::query()->find($accountId);

        if ($chosen?->isDollar() === true) {
            if ($order === null || ! $order->isDollar()) {
                throw PurchaseOrderCurrencyRefused::dollarDrawerOnADinarOrder((string) $chosen->name, $field);
            }

            if ($order->arrival_rate === null && $rateAtHand === null && $this->treasury->settings()->usd_rate === null) {
                throw PurchaseOrderCurrencyRefused::noRateForADollarCost($field);
            }
        }

        $account = $this->treasury->expenseAccount($accountId, $field, dollarsToo: $order?->isDollar() === true);

        $this->treasury->guardManualEntry($account, now(), $field);
    }

    /**
     * What a cost is counted in — USD-ACCOUNTS.md §٧. On the vendor's bill, the order's
     * currency; paid from a drawer, the drawer's — so a dollar order carries shipping in dollars
     * on the bill and customs in dinars out of a dinar drawer. A currency sent with the cost is
     * checked against that, never taken on its word. Call after {@see guardAccount()}.
     *
     * @throws PurchaseOrderCurrencyRefused
     */
    public function currencyOf(PurchaseOrder $order, PurchaseOrderAdditionalCostData $cost, string $field): Currency
    {
        if ($cost->treasuryAccountId === null) {
            if ($cost->currency !== null && $cost->currency !== $order->currency) {
                throw PurchaseOrderCurrencyRefused::costOnTheBill($order->currency->label(), $field);
            }

            return $order->currency;
        }

        $drawer = TreasuryAccount::query()->findOrFail($cost->treasuryAccountId)->currency;

        if ($cost->currency !== null && $cost->currency !== $drawer) {
            throw PurchaseOrderCurrencyRefused::costInTheDrawers($drawer->label(), $field);
        }

        return $drawer;
    }
}
