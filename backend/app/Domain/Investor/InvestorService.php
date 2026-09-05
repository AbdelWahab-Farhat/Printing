<?php

declare(strict_types=1);

namespace App\Domain\Investor;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Identity\Models\User;
use App\Domain\Investor\Actions\CloseInvestorDeal;
use App\Domain\Investor\Actions\CreateInvestor;
use App\Domain\Investor\Actions\FundPurchaseOrder;
use App\Domain\Investor\Actions\PostDealEarningsForOrder;
use App\Domain\Investor\Actions\RecordDealExpense;
use App\Domain\Investor\Actions\RecordWalletEntry;
use App\Domain\Investor\Actions\SetInvestorActivation;
use App\Domain\Investor\Actions\UpdateInvestor;
use App\Domain\Investor\DTOs\DealExpenseData;
use App\Domain\Investor\DTOs\FundPurchaseOrderData;
use App\Domain\Investor\DTOs\InvestorData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorDealExpense;
use App\Domain\Investor\Models\InvestorDealSupply;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\DealListQuery;
use App\Domain\Investor\Queries\DealOrdersQuery;
use App\Domain\Investor\Queries\DealStockPosition;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\InvestorListQuery;
use App\Domain\Investor\Queries\PurchaseOrderFundingQuery;
use App\Domain\Investor\Support\Money;
use App\Domain\Settings\SettingsService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

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
        private readonly FundPurchaseOrder $fundPurchaseOrder,
        private readonly CloseInvestorDeal $closeDeal,
        private readonly RecordWalletEntry $recordEntry,
        private readonly RecordDealExpense $recordExpense,
        private readonly PostDealEarningsForOrder $postEarnings,
        private readonly InvestorBalances $balances,
        private readonly InvestorListQuery $investorList,
        private readonly DealListQuery $dealList,
        private readonly DealStockPosition $stockPosition,
        private readonly DealOrdersQuery $dealOrderList,
        private readonly PurchaseOrderFundingQuery $purchaseOrderFunding,
        private readonly SettingsService $settings,
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

    /**
     * A purchase order becomes a funded, open deal — its lines, its claim and its money at once.
     *
     * The only way a deal is born. There is no deal assembled by hand: the fraction of the goods
     * its partners own is derived from the order's cost, and a deal without an order had nothing
     * to derive it from — the owner's word, 2026-09-05: «صفقة يدوية يجب أن لا توجد».
     */
    public function fundPurchaseOrder(int $purchaseOrderId, FundPurchaseOrderData $data, ?int $actorId): InvestorDeal
    {
        return ($this->fundPurchaseOrder)($purchaseOrderId, $data, $actorId);
    }

    public function closeDeal(InvestorDeal $deal): InvestorDeal
    {
        return ($this->closeDeal)($deal);
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
     * The totals of a page of investors, in one query — what the register screen draws.
     *
     * @param  list<int>  $investorIds
     * @return array<int, array{capital: string, profit: string, wallet_capital: string, wallet_profit: string}>
     */
    public function balancesForMany(array $investorIds): array
    {
        return $this->balances->forInvestors($investorIds);
    }

    /**
     * @return array{capital: string, profit: string, per_investor: array<int, array{capital: string, profit: string}>}
     */
    public function dealBalances(int $dealId): array
    {
        return $this->balances->forDeal($dealId);
    }

    // ── the two lines the rest of the system calls ───────────────────────────

    /**
     * A set of deals as a screen holding their ids needs them: the code, and who is in each.
     *
     * For the screens that hold a deal id and cannot name it — a cost layer, a movement. They
     * live in Inventory, which must not import anything from here, so the Application layer asks
     * and hands the answer down.
     *
     * **One query for the page, two with the partners.** A layer list showing fifty batches must
     * not become fifty lookups.
     *
     * @param  list<int>  $dealIds
     * @return array<int, array{code: string, investors: list<array{investor_id: int, name: string, committed_amount: string, share_percent: string}>}>
     */
    public function dealSummaries(array $dealIds): array
    {
        if ($dealIds === []) {
            return [];
        }

        $deals = InvestorDeal::query()
            ->whereIn('id', $dealIds)
            ->with('shares.investor')
            ->get();

        $out = [];

        foreach ($deals as $deal) {
            $out[(int) $deal->getKey()] = [
                'code' => (string) $deal->code,
                'investors' => $deal->shares->map(fn ($share): array => [
                    'investor_id' => (int) $share->investor_id,
                    'name' => (string) ($share->investor?->name ?? ''),
                    'committed_amount' => (string) $share->committed_amount,
                    'share_percent' => (string) $share->share_percent,
                ])->values()->all(),
            ];
        }

        return $out;
    }

    /**
     * The investors' share of profit a new deal is born with — the company default.
     *
     * Read by the funding screen so the number is **shown** rather than left to be discovered
     * after the deal is struck. Copied onto each deal at birth and never read again for that
     * deal, so editing it tomorrow moves nothing already agreed.
     */
    public function defaultProfitSharePercent(): string
    {
        return (string) $this->settings->investorProfitSharePercent();
    }

    /**
     * The deals financing one purchase order, with their partners and percentages.
     *
     * Read by the purchase-order screen. Empty for the ordinary order the company paid for
     * itself, which is most of them.
     *
     * @return list<array<string, mixed>>
     */
    public function fundingForPurchaseOrder(int $purchaseOrderId): array
    {
        return ($this->purchaseOrderFunding)($purchaseOrderId);
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

    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, Investor>
     */
    public function paginateInvestors(array $filters, int $perPage = 15)
    {
        return ($this->investorList)($filters, $perPage);
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return LengthAwarePaginator<int, InvestorDeal>
     */
    public function paginateDeals(array $filters, int $perPage = 15)
    {
        return ($this->dealList)($filters, $perPage);
    }

    /**
     * What a deal's goods are doing — arrived, left, sold, damaged, short.
     *
     * @return array<string, mixed>
     */
    public function dealStock(int $dealId): array
    {
        return ($this->stockPosition)($dealId);
    }

    /**
     * The orders that sold a deal's goods, and what each one earned it.
     *
     * @return LengthAwarePaginator<int, array<string, mixed>>
     */
    public function dealOrders(int $dealId, int $perPage = 15)
    {
        return ($this->dealOrderList)($dealId, $perPage);
    }

    /** Rounding, exposed so a controller never reimplements it. */
    public function round(string $amount): string
    {
        return Money::round($amount);
    }
}
