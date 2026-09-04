<?php

declare(strict_types=1);

namespace App\Domain\Investor;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\CancelInvestorDeal;
use App\Domain\Investor\Actions\ClaimDealSupply;
use App\Domain\Investor\Actions\CloseInvestorDeal;
use App\Domain\Investor\Actions\CreateInvestor;
use App\Domain\Investor\Actions\CreateInvestorDeal;
use App\Domain\Investor\Actions\OpenInvestorDeal;
use App\Domain\Investor\Actions\PostDealEarningsForOrder;
use App\Domain\Investor\Actions\RecordDealExpense;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Actions\SetInvestorActivation;
use App\Domain\Investor\Actions\SyncDealItems;
use App\Domain\Investor\Actions\SyncDealShares;
use App\Domain\Investor\Actions\UpdateInvestor;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\DealItemData;
use App\Domain\Investor\DTOs\DealShareData;
use App\Domain\Investor\DTOs\InvestorData;
use App\Domain\Investor\DTOs\InvestorDealData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Support\Money;

/**
 * The door to everything about investors — and the only one other contexts knock on.
 *
 * **The dependency runs one way.** Investment reads Orders, Inventory and Catalog through their
 * services; none of them imports anything from here. The two places the rest of the system calls
 * in are both a single line: `ReceivePurchaseOrder` asks which deal financed a line, and
 * `ChangeOrderStatus` says that an order has been delivered. Neither knows what happens next.
 */
final class InvestorService
{
    public function __construct(
        private readonly CreateInvestor $createInvestor,
        private readonly UpdateInvestor $updateInvestor,
        private readonly SetInvestorActivation $setActivation,
        private readonly CreateInvestorDeal $createDeal,
        private readonly SyncDealItems $syncItems,
        private readonly SyncDealShares $syncShares,
        private readonly OpenInvestorDeal $openDeal,
        private readonly CloseInvestorDeal $closeDeal,
        private readonly CancelInvestorDeal $cancelDeal,
        private readonly RecordWalletEntry $recordEntry,
        private readonly RecordDealExpense $recordExpense,
        private readonly ClaimDealSupply $claimSupply,
        private readonly PostDealEarningsForOrder $postEarnings,
        private readonly InvestorBalances $balances,
    ) {}

    // ── people ───────────────────────────────────────────────────────────────

    public function createInvestor(InvestorData $data, ?int $actorId): Investor
    {
        return ($this->createInvestor)($data, $actorId);
    }

    public function updateInvestor(Investor $investor, InvestorData $data): Investor
    {
        return ($this->updateInvestor)($investor, $data);
    }

    public function setInvestorActivation(Investor $investor, bool $isActive): Investor
    {
        return ($this->setActivation)($investor, $isActive);
    }

    /** The investor behind a signed-in user, or null — the whole of the portal's scoping. */
    public function investorFor(?User $user): ?Investor
    {
        if ($user === null) {
            return null;
        }

        return Investor::query()
            ->where('user_id', $user->getKey())
            ->where('is_active', true)
            ->first();
    }

    // ── deals ────────────────────────────────────────────────────────────────

    public function createDeal(InvestorDealData $data, ?int $actorId): InvestorDeal
    {
        return ($this->createDeal)($data, $actorId);
    }

    /**
     * @param  list<DealItemData>  $items
     */
    public function syncDealItems(InvestorDeal $deal, array $items): InvestorDeal
    {
        return ($this->syncItems)($deal, $items);
    }

    /**
     * @param  list<DealShareData>  $shares
     */
    public function syncDealShares(InvestorDeal $deal, array $shares): InvestorDeal
    {
        return ($this->syncShares)($deal, $shares);
    }

    public function openDeal(InvestorDeal $deal): InvestorDeal
    {
        return ($this->openDeal)($deal);
    }

    public function closeDeal(InvestorDeal $deal): InvestorDeal
    {
        return ($this->closeDeal)($deal);
    }

    public function cancelDeal(InvestorDeal $deal, string $reason): InvestorDeal
    {
        return ($this->cancelDeal)($deal, $reason);
    }

    // ── money ────────────────────────────────────────────────────────────────

    public function recordWalletEntry(WalletEntryData $data, ?int $actorId): InvestorWalletEntry
    {
        return ($this->recordEntry)($data, $actorId);
    }

    public function recordDealExpense(InvestorDeal $deal, DealExpenseData $data, ?int $actorId): InvestorDealExpense
    {
        return ($this->recordExpense)($deal, $data, $actorId);
    }

    /**
     * @return array{wallet: array{capital: string, profit: string}, deals: array<int, array{capital: string, profit: string}>}
     */
    public function balancesFor(int $investorId): array
    {
        return $this->balances->forInvestor($investorId);
    }

    /**
     * @return array{capital: string, profit: string, per_investor: array<int, array{capital: string, profit: string}>}
     */
    public function dealBalances(int $dealId): array
    {
        return $this->balances->forDeal($dealId);
    }

    // ── the two lines the rest of the system calls ───────────────────────────

    public function claimSupply(InvestorDeal $deal, int $purchaseOrderId, int $stockItemId, ?int $actorId): InvestorDealSupply
    {
        return ($this->claimSupply)($deal, $purchaseOrderId, $stockItemId, $actorId);
    }

    /**
     * Which deal financed a line of an arriving document — asked once per line at receipt.
     *
     * Null is the ordinary answer and means the company paid for it. The receiving clerk never
     * sees this question: it is answered from a claim somebody made before the goods left the
     * supplier.
     */
    public function dealForSupply(int $purchaseOrderId, int $stockItemId): ?int
    {
        $supply = InvestorDealSupply::query()
            ->where('source_type', AuditSubject::PurchaseOrder->value)
            ->where('source_id', $purchaseOrderId)
            ->where('stock_item_id', $stockItemId)
            ->first();

        return $supply === null ? null : (int) $supply->investor_deal_id;
    }

    /**
     * An order has become final — split what it earned among whoever financed its stock.
     *
     * Called from `ChangeOrderStatus` on the way into «تم الاستلام». Does nothing at all when the
     * order drew from no funded layer, which is the normal case.
     *
     * @return list<InvestorWalletEntry>
     */
    public function postEarningsForOrder(int $orderId): array
    {
        return ($this->postEarnings)($orderId);
    }

    /** Rounding, exposed so a controller never reimplements it. */
    public function round(string $amount): string
    {
        return Money::round($amount);
    }
}
