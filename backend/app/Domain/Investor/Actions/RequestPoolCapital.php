<?php

declare(strict_types=1);

namespace App\Domain\Investor\Actions;

use App\Domain\Investor\DTOs\CapitalRequestData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\Enums\CapitalRequestDirection;
use App\Domain\Investor\Enums\CapitalRequestStatus;
use App\Domain\Investor\Enums\PeriodStatus;
use App\Domain\Investor\Exceptions\CapitalIsStillLocked;
use App\Domain\Investor\Exceptions\PoolHasNoOpenPeriod;
use App\Domain\Investor\Models\InvestmentCapitalRequest;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorDeal;
use App\Domain\Investor\Support\GraceWindow;
use App\Domain\Investor\Support\MinimumTerm;
use App\Domain\Settings\SettingsService;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Capital offered to a pool: taken now, or queued for the next period.
 *
 * ## The fork
 *
 * ```
 * inside the grace window   →  allocate immediately, and the money works for the whole period
 * outside it                →  a pending request; the money stays in his wallet until the boundary
 * ```
 *
 * {@see GraceWindow} makes that decision, and makes it for the endpoint that warns him too — so
 * what he was told before he pressed the button is produced by the same function that then acts.
 *
 * **Why the money is not taken and held when it is queued.** A pending request moves nothing: the
 * deposit sits in his wallet exactly as it always has, he can cancel and withdraw it, and the
 * ledger stays the one place capital actually is. Holding it would create a fifth pot that no
 * balance equation names — and somebody would eventually ask why his wallet says one thing and his
 * statement another.
 *
 * ## Going out
 *
 * An **exit is always queued**, whatever the window says. Two reasons, and the second is the one
 * that bites: an investor who pulled capital out on day 15 would have no single weight for that
 * period, which is the day-weighting the grace window exists to avoid; and the money is usually in
 * stock rather than in cash, so it cannot be handed back on demand anyway. It leaves at the close,
 * **after** that period's profit has been distributed — so a man who asks to leave in September is
 * still paid his September share.
 *
 * ## What is refused here, and what is not
 *
 * A pool with no open period is refused: there is no boundary to measure against, so there is no
 * honest answer to give. Whether he *has* the money is not this action's business —
 * {@see RecordWalletEntry} reads the wallet ceiling under the investor's lock, and duplicating that
 * check here would be a second opinion that can drift from the one that counts.
 */
final class RequestPoolCapital
{
    public function __construct(
        private readonly SettingsService $settings,
        private readonly RecordWalletEntry $recordEntry,
    ) {}

    /**
     * @throws PoolHasNoOpenPeriod|CapitalIsStillLocked
     */
    public function __invoke(InvestorDeal $pool, CapitalRequestData $data, ?int $actorId): InvestmentCapitalRequest
    {
        return DB::transaction(function () use ($pool, $data, $actorId): InvestmentCapitalRequest {
            $locked = InvestorDeal::query()->whereKey($pool->getKey())->lockForUpdate()->firstOrFail();
            $period = $this->openPeriodFor($locked);

            $this->guardMinimumTerm($locked, $data);

            $request = new InvestmentCapitalRequest([
                'amount' => $data->amount,
                'notes' => $data->notes,
            ]);

            $request->investor_id = $data->investorId;
            $request->investor_deal_id = $locked->getKey();
            $request->direction = $data->direction;
            $request->requested_at = now();
            $request->requested_by = $actorId;
            $request->status = CapitalRequestStatus::Pending;
            $request->save();

            if ($this->takesEffectNow($data->direction, $period)) {
                $entry = ($this->recordEntry)(
                    new WalletEntryData(
                        investorId: $data->investorId,
                        type: $data->direction->walletType(),
                        amount: $data->amount,
                        investorDealId: (int) $locked->getKey(),
                        notes: $data->notes,
                    ),
                    $actorId,
                );

                $request->status = CapitalRequestStatus::Applied;
                $request->effective_period_id = $period->getKey();
                $request->applied_entry_id = $entry->getKey();
                $request->save();
            }

            return $request->refresh();
        });
    }

    /**
     * Refuses an exit asked for before the minimum term has run.
     *
     * **Only an exit**, and only when a term is set — the default is zero, which is how this
     * system behaved before the setting existed, so nothing changes until somebody sets it.
     *
     * Checked **here, when the request is made**, and never again when it is paid: an exit already
     * queued was legitimate the day it was asked for, and lengthening the term tomorrow must not
     * strand it. The same standing every other setting has.
     *
     * @throws CapitalIsStillLocked
     */
    private function guardMinimumTerm(InvestorDeal $pool, CapitalRequestData $data): void
    {
        if ($data->direction !== CapitalRequestDirection::Out) {
            return;
        }

        // **The company is exempt, and the exemption is the point rather than a special case.**
        // The term exists to stop a partner taking a month's profit and leaving with his capital.
        // The company is not a partner in that sense: it is the operator, it absorbs the losses
        // that run past what a partner put in, and its money in the pool is working capital it has
        // to be able to move. Locking the house against itself protects nobody.
        //
        // It is still capped by its own slice of the cash at the close, exactly like everybody
        // else — this exempts it from the calendar, not from the arithmetic.
        if (Investor::query()->whereKey($data->investorId)->value('is_company')) {
            return;
        }

        $term = $this->settings->minimumTermMonths();

        $freeOn = MinimumTerm::freeOn($data->investorId, (int) $pool->getKey(), $term);

        if ($freeOn === null) {
            return;
        }

        throw CapitalIsStillLocked::make(
            (string) ($pool->name ?? $pool->code),
            $freeOn->toDateString(),
            $term,
        );
    }

    /**
     * Whether this request acts now rather than at the next boundary.
     *
     * Only capital coming **in**, and only inside the window. An exit never acts now — see the
     * class docblock.
     */
    private function takesEffectNow(CapitalRequestDirection $direction, InvestmentPeriod $period): bool
    {
        return $direction === CapitalRequestDirection::In
            && GraceWindow::admits($period, $this->settings->entryGraceDays(), Carbon::now());
    }

    /**
     * @throws PoolHasNoOpenPeriod
     */
    private function openPeriodFor(InvestorDeal $pool): InvestmentPeriod
    {
        $period = InvestmentPeriod::query()
            ->where('investor_deal_id', $pool->getKey())
            ->where('status', PeriodStatus::Open->value)
            ->first();

        if ($period === null) {
            throw PoolHasNoOpenPeriod::make((string) ($pool->name ?? $pool->code));
        }

        return $period;
    }
}
