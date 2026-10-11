<?php

declare(strict_types=1);

namespace App\Domain\PurchaseOrder\Actions;

use App\Domain\PurchaseOrder\Models\PurchaseOrderAdditionalCost;
use App\Domain\Treasury\Exceptions\AccountDoesNotFitMethod;
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

        $this->treasury->syncExpense(
            sourceType: $cost->getMorphClass(),
            sourceId: (int) $cost->getKey(),
            accountId: $live ? $cost->treasury_account_id : null,
            amount: $live ? ($amount ?? (string) $cost->amount) : '0',
            firstPostedAt: now(),
            notes: "{$cost->name} — أمر الشراء {$code}",
            reason: $reason ?? "تعديل أمر الشراء {$code}",
            actorId: $actorId,
        );
    }

    /**
     * Refuses an account a cost cannot be charged to — see {@see TreasuryService::expenseAccount()}
     * — and a day the treasury is closed for. Before anything is written.
     *
     * @throws AccountDoesNotFitMethod
     */
    public function guardAccount(?int $accountId, string $field): void
    {
        if ($accountId === null) {
            return;
        }

        $account = $this->treasury->expenseAccount($accountId, $field);

        $this->treasury->guardManualEntry($account, now(), $field);
    }
}
