<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CashEntryType;
use App\Domain\Investor\Enums\DealStatus;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\DealTakesNoMoreCapital;
use App\Domain\Investor\Exceptions\EntryCannotBeReversed;
use App\Domain\Investor\Exceptions\WithdrawalExceedsBalance;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\InvestorBalances;
use App\Domain\Investor\Queries\PeriodForEntry;
use App\Domain\Investor\Support\Money;
use Illuminate\Support\Facades\DB;

/**
 * Writes one hand-recorded movement of an investor's money.
 *
 * **The ceiling is read from the locked row, never from a figure fetched before it.** That is
 * the `RecordOrderPayment` discipline and the only thing that makes two simultaneous withdrawals
 * safe: without the lock both read the same balance, both pass their own check, and the pair
 * takes out more than was there.
 *
 * Locks are taken in one order everywhere in this context — the investor first, then the deal,
 * each ascending by id — so two of these can never hold what the other is waiting for.
 */
final class RecordWalletEntry
{
    public function __construct(
        private readonly InvestorBalances $balances,
        private readonly PeriodForEntry $periodFor,
        private readonly RecordCashEntry $cash,
    ) {}

    /**
     * @throws WithdrawalExceedsBalance
     * @throws EntryCannotBeReversed
     */
    public function __invoke(WalletEntryData $data, ?int $actorId): InvestorWalletEntry
    {
        if (! $data->type->isRecordableByHand()) {
            throw EntryCannotBeReversed::make(
                'هذه الحركة يكتبها النظام عند تسليم الطلبيات أو عند إقفال الصفقة، ولا تُسجَّل يدوياً'
            );
        }

        return DB::transaction(function () use ($data, $actorId): InvestorWalletEntry {
            $investor = Investor::query()->whereKey($data->investorId)->lockForUpdate()->firstOrFail();

            $deal = $data->investorDealId === null
                ? null
                : InvestorDeal::query()->whereKey($data->investorDealId)->lockForUpdate()->firstOrFail();

            $this->guardCeiling($data, (int) $investor->getKey());
            $this->guardDeal($data, $deal);

            $occurredAt = $data->occurredAt ?? now();

            $entry = new InvestorWalletEntry([
                'amount' => $data->amount,
                'method' => $data->method,
                'reference' => $data->reference,
                'occurred_at' => $occurredAt,
                'notes' => $data->notes,
            ]);

            $entry->investor_id = $investor->getKey();
            $entry->investor_deal_id = $deal?->getKey();
            // **بتاريخ وقوعه لا بتاريخ كتابته** — إيداعٌ حدث يوم ٢٨ وسُجِّل يوم ٢ يخصّ الفترة
            // التي وقع فيها، كما تخصّ الطلبيةُ فترةَ تاريخها. والأرضيةُ تردّه إلى المفتوحة اليوم
            // إن كانت فترتُه قد أُقفلت.
            $entry->investment_period_id = $this->periodFor->byDate($occurredAt);
            $entry->type = $data->type;
            $entry->recorded_by = $actorId;
            $entry->save();

            // **صرفُ الأرباح نقدٌ يخرج من الخزينة.** رأسُ المال يخرج من {@see WithdrawFromFund}
            // لأنه يُلغي وحداتٍ معه؛ والأرباحُ لا وحداتِ لها — أُفرِج عنها بالفعل ولا تغيّر
            // نسبةَ أحد — فبابُها هنا. والإيداعُ كذلك في {@see DepositToFund} لأنه يشتري وحدات.
            if ($data->type === WalletEntryType::ProfitWithdrawal) {
                ($this->cash)(
                    type: CashEntryType::ProfitPayout,
                    amount: $entry->amount,
                    sourceType: AuditSubject::InvestorWalletEntry->value,
                    sourceId: (int) $entry->getKey(),
                    actorId: $actorId,
                );
            }

            return $entry;
        });
    }

    /**
     * Nothing leaves a pot that does not have it.
     *
     * A deposit has no ceiling — money genuinely arrived, and refusing to record it would only
     * make the books disagree with the drawer.
     */
    private function guardCeiling(WalletEntryData $data, int $investorId): void
    {
        $balances = $this->balances->forInvestor($investorId);

        $available = match ($data->type) {
            WalletEntryType::Withdrawal, WalletEntryType::Allocation => $balances['wallet']['capital'],
            // **وسقفُ التحويل هو الربحُ المتاح**: من يحوّل إلى رأس المال أكثر مما ربح يخلق
            // مالاً من لا شيء، ولا يظهر ذلك في أيّ رصيدٍ لأن الجيبين يتحرّكان معاً.
            WalletEntryType::ProfitWithdrawal,
            WalletEntryType::ProfitCapitalisation => $balances['wallet']['profit'],
            default => null,
        };

        if ($available === null) {
            return;
        }

        if (bccomp($data->amount, $available, Money::SCALE) > 0) {
            throw WithdrawalExceedsBalance::make($data->amount, $available);
        }
    }

    /** Money only goes into a deal that is open to take it. */
    private function guardDeal(WalletEntryData $data, ?InvestorDeal $deal): void
    {
        if ($deal === null) {
            return;
        }

        if ($deal->status !== DealStatus::Open && $deal->status !== DealStatus::Draft) {
            throw EntryCannotBeReversed::make(
                "الصفقة {$deal->code} «{$deal->status->label()}» ولا تقبل حركات مالية جديدة"
            );
        }

        // A deal born from a purchase order fixed, at funding, what fraction of the goods the
        // partners' money bought. Capital added after it opened buys nothing and moves no
        // percent; `FundPurchaseOrder` writes its own allocations while the deal is still a
        // draft, so this catches only the top-up from the investor screen.
        if ($data->type === WalletEntryType::Allocation
            && $deal->status === DealStatus::Open
            && $deal->isBornFromPurchaseOrder()) {
            throw DealTakesNoMoreCapital::make((string) $deal->code);
        }
    }
}
