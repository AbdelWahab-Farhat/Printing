<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Resources\InvestorPortfolioResource;
use App\Application\Api\V1\Resources\InvestorWalletEntryResource;
use App\Application\Controller;
use App\Domain\Investor\Enums\WalletEntryType;
use App\Domain\Investor\Exceptions\InvestorHasNoAccount;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\InvestmentPeriod;
use App\Domain\Investor\Models\InvestmentUnit;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundUnits;
use App\Domain\Investor\Queries\PeriodShares;
use App\Domain\Investor\Queries\UnitPrice;
use App\Domain\Investor\Support\Money;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Investor portal
 *
 * What an investor sees, and the only thing he can reach.
 *
 * **There is no id in any path here, and that is the security.** This application has no policy
 * classes; `can:` authorises an ability with no model, and an administrator is granted every
 * ability unconditionally — so «this investor sees only his own rows» cannot be expressed as a
 * permission. It is enforced by there being no id to tamper with: the investor is resolved from
 * the signed-in user's own `investors.user_id` link, and a user with no such link gets a 404
 * rather than somebody else's money.
 */
class InvestorPortalController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly InvestorService $investors,
        private readonly FundUnits $units,
        private readonly UnitPrice $price,
        private readonly PeriodShares $shares,
    ) {}

    /**
     * My money
     *
     * Capital in the wallet, capital in deals, profit earned so far, and profit released and
     * withdrawable. With a line per deal.
     */
    public function summary(Request $request): JsonResponse
    {
        $investor = $this->investors->investorFor($request->user());

        if ($investor === null) {
            throw InvestorHasNoAccount::make();
        }

        return $this->success(new InvestorPortfolioResource($this->portfolio((int) $investor->getKey(), $investor)));
    }

    /**
     * My statement
     *
     * Every movement of my own money — where each dinar came from and, when something was taken
     * back, which order or expense took it.
     */
    public function statement(Request $request): JsonResponse
    {
        $investor = $this->investors->investorFor($request->user());

        if ($investor === null) {
            throw InvestorHasNoAccount::make();
        }

        $perPage = min(max((int) $request->integer('per_page', 25), 1), 100);

        $entries = InvestorWalletEntry::query()
            ->with(['deal', 'reversedEntry'])
            ->where('investor_id', $investor->getKey())
            ->orderByDesc('occurred_at')
            ->orderByDesc('id')
            ->paginate($perPage);

        return $this->successWithPagination(InvestorWalletEntryResource::collection($entries));
    }

    /**
     * @return array<string, mixed>
     */
    private function portfolio(int $investorId, $investor): array
    {
        $balances = $this->investors->balancesFor($investorId);

        $capitalInDeals = '0.00';
        $profitInDeals = '0.00';
        $deals = [];

        $rows = $investor->shares()->with('deal')->get();

        foreach ($rows as $share) {
            $dealId = (int) $share->investor_deal_id;
            $pots = $balances['deals'][$dealId] ?? ['capital' => '0.00', 'profit' => '0.00'];

            $capitalInDeals = bcadd($capitalInDeals, $pots['capital'], 2);
            $profitInDeals = bcadd($profitInDeals, $pots['profit'], 2);

            $deals[] = [
                'id' => $dealId,
                'code' => $share->deal?->code,
                'name' => $share->deal?->name,
                'status' => $share->deal?->status->value,
                'status_label' => $share->deal?->status->label(),
                'share_percent' => (string) $share->share_percent,
                'capital' => $pots['capital'],
                'profit' => $pots['profit'],
            ];
        }

        $withdrawn = (string) InvestorWalletEntry::query()
            ->where('investor_id', $investorId)
            ->where('type', WalletEntryType::ProfitWithdrawal->value)
            ->whereDoesntHave('reversedBy')
            ->sum('amount');

        return [
            'investor' => [
                'id' => $investorId,
                'code' => $investor->code,
                'name' => $investor->name,
            ],
            'capital_in_wallet' => $balances['wallet']['capital'],
            'capital_in_deals' => $capitalInDeals,
            'capital_total' => bcadd($balances['wallet']['capital'], $capitalInDeals, 2),
            'profit_in_deals' => $profitInDeals,
            'profit_available' => $balances['wallet']['profit'],
            'profit_withdrawn' => number_format((float) $withdrawn, 2, '.', ''),
            'deals' => $deals,
            'fund' => $this->fundStanding($investorId),
        ];
    }

    /**
     * موقفُه من الصندوق: وحداتُه، ونسبتُه في الفترة الجارية، وما تساويه حصتُه اليوم.
     *
     * **الشريحة ٨.** البوابةُ كانت تقرأ `investor_deal_shares` وحدها — وشريكُ الصندوق لا صفَّ له
     * هناك: نصيبُه وحداتٌ في دفترٍ آخر. فكان يفتح الشاشةَ فيرى صفراً وماله في الصندوق.
     *
     * **و«قيمة حصتي» تُقال هنا ولا تُحسب على الهاتف.** هي `وحداتُه × سعرَ الوحدة`، والسعرُ
     * قسمةُ قيمة الصندوق على وحداته — أربعةُ استعلاماتٍ لا يملكها من يقرأ.
     *
     * **والحبسُ يُعرض دفعةً دفعة** لأنه كذلك: «كل deposit Timer خاص به لوحده». رقمٌ واحد
     * كان سيقول «محبوسٌ إلى ٢٠٢٨» لمن نصفُ ماله يخرج في ٢٠٢٧.
     *
     * @return array<string, mixed>
     */
    private function fundStanding(int $investorId): array
    {
        $held = $this->units->heldBy($investorId);
        $price = ($this->price)();
        $open = InvestmentPeriod::open();

        $locks = InvestmentUnit::query()
            ->where('investor_id', $investorId)
            ->whereNotNull('locked_until')
            ->whereDoesntHave('reversedBy')
            ->orderBy('locked_until')
            ->get()
            ->map(fn (InvestmentUnit $row): array => [
                'units' => (string) $row->units,
                'amount' => (string) $row->amount,
                'locked_until' => $row->locked_until?->toDateString(),
                'is_locked' => $row->isLockedOn(now()),
            ])
            ->all();

        $shares = $open === null ? [] : $this->shares->forPeriod((int) $open->getKey());

        return [
            'units' => $held,
            'unit_price' => $price,
            'value' => Money::round(bcmul($held, $price, 8)),
            'share_percent' => $shares[$investorId] ?? '0.000000',

            // **صفرٌ بجانب مالٍ في الصندوق سؤالٌ لا خبر.** من اكتتب في نافذة فترةٍ بدأت لا
            // يقاسمها — «تجمد نسبته ولا تحسب له أرباح شهر تسعة إنما تحسب له أرباح شهر عشرة» —
            // فتقول البوابةُ متى يبدأ نصيبُه بدل أن تتركه يحسب أن مالَه ضاع.
            'share_starts_next_period' => $open !== null
                && ! isset($shares[$investorId])
                && bccomp($held, '0', FundUnits::SCALE) > 0,
            'unlocked_units' => $this->units->unlockedFor($investorId, now()),
            'period' => $open === null ? null : [
                'code' => $open->code,
                'starts_on' => $open->starts_on->toDateString(),
                'ends_on' => $open->ends_on->toDateString(),
                'accepts_capital' => $open->acceptsCapitalOn(now()),
            ],
            'deposits' => $locks,
        ];
    }
}
