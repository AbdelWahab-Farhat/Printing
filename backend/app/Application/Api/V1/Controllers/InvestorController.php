<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Investor\InvestorStatementRequest;
use App\Application\Api\V1\Requests\Investor\StoreInvestorRequest;
use App\Application\Api\V1\Requests\Investor\StoreWalletEntryRequest;
use App\Application\Api\V1\Requests\Investor\UpdateInvestorRequest;
use App\Application\Api\V1\Requests\SetActivationRequest;
use App\Application\Api\V1\Resources\InvestorResource;
use App\Application\Api\V1\Resources\InvestorWalletEntryResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Investor\Actions\ReverseWalletEntry;
use App\Domain\Investor\DTOs\InvestorData;
use App\Domain\Investor\DTOs\WalletEntryData;
use App\Domain\Investor\InvestorService;
use App\Domain\Investor\Models\Investor;
use App\Domain\Investor\Models\InvestorWalletEntry;
use App\Domain\Investor\Queries\FundStanding;
use App\Domain\Investor\Queries\InvestorPeriods;
use App\Domain\Investor\Queries\InvestorStatementQuery;
use App\Domain\Investor\Queries\ProfitAwaitingDelivery;
use App\Domain\Investor\Support\FundDeal;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Investors
 *
 * المستثمرون — the people whose money finances the stock, and the wallet each one's money sits
 * in. A wallet has two pots kept deliberately apart: **capital**, which he put in and can take
 * back out, and **profit**, which his deals earned him.
 *
 * Nothing here stores a balance. Every figure is a walk of `investor_wallet_entries`, which is
 * the same rule the order ledger follows and the reason the numbers can never drift from the
 * rows they summarise.
 */
class InvestorController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(
        private readonly InvestorService $investors,
        private readonly FundDeal $fund,
        private readonly ProfitAwaitingDelivery $awaiting,
        private readonly FundStanding $fundStanding,
        private readonly InvestorPeriods $periods,
    ) {}

    /**
     * List investors
     *
     * Active first, then by name. `search` matches the name, the code and the phone.
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min(max((int) $request->integer('per_page', 15), 1), 100);

        $page = $this->investors->paginateInvestors($request->only(['search', 'is_active']), $perPage);

        // What each man has with us and what he has earned, drawn on the row itself. **One query
        // for the whole page**, not one ledger walk per card — the register is a list, and a
        // list that costs fifty queries to draw two numbers is a list that gets slower every
        // time somebody is added.
        $totals = $this->investors->balancesForMany(
            $page->getCollection()->map(fn ($investor) => (int) $investor->getKey())->all(),
        );

        $page->getCollection()->each(
            fn ($investor) => $investor->setAttribute('totals', $totals[(int) $investor->getKey()] ?? null),
        );

        return $this->successWithPagination(InvestorResource::collection($page));
    }

    /**
     * Create an investor
     */
    public function store(StoreInvestorRequest $request): JsonResponse
    {
        $investor = $this->investors->createInvestor(
            InvestorData::fromArray($request->validated()),
            $request->user()?->id,
        );

        return $this->created(new InvestorResource($investor), 'تم إضافة المستثمر');
    }

    /**
     * Show an investor
     *
     * With his balances: what is in his wallet, what each of his deals is holding and has
     * earned him, and what he has in the fund.
     *
     * **والصندوقُ ليس منها.** هو صفقةٌ في الجدول — ختمُ ملكيةٍ على طبقات التكلفة، لا كيانٌ يديره
     * أحد ({@see FundDeal}) — وقسمُ «في الصفقات» على صفحته كان يعرضه صفّاً يفتح صفحةَ الصفقة
     * بزرِّ إغلاقها. وهو البابُ الذي أُغلق منه الصندوقُ فعلاً في ٢٢ سبتمبر ٢٠٢٦: رابطُ قائمة
     * الصفقات كان قد رُفع من الدرج، وبقي هذا الطريقُ إليه مفتوحاً من صفحة كلِّ مشترك.
     *
     * **ومالُه فيه يُقال في `fund` لا في الصفقات** ({@see FundStanding}): ما وضعه، ووحداتُه،
     * ونسبتُه، ودفعاتُه بمواعيد فكّها — ما تقوله بوابتُه له. كان الظنُّ أنّ لوحةَ الصندوق تكفيه،
     * فكان رجلٌ مالُه كلُّه في الصندوق يُقرأ على صفحته «رصيد المحفظة 0» و«لا مال له في أي صفقة».
     * والحذفُ هنا في طبقة العرض وحدها — `InvestorBalances` يبقى يمشي على كل صفقة، وعليه
     * يقف حارسُ الاسترداد وتسويةُ الإقفال.
     */
    public function show(Investor $investor): JsonResponse
    {
        $balances = $this->investors->balancesFor((int) $investor->getKey());
        $fundId = $this->fund->idOrNull();

        // **الأرقامُ الثلاثة قبل أن يُحذف الصندوقُ من الصفقات** — ربحُه المقيَّد فيه جزءٌ من
        // «أرباح معلّقة»، وحذفُه من القائمة أدناه عرضٌ لا حساب.
        $pending = '0.00';

        foreach ($balances['deals'] as $pots) {
            $pending = bcadd($pending, $pots['profit'], 2);
        }

        $awaiting = $this->awaiting->forInvestor((int) $investor->getKey());

        $investor->setAttribute('profit_figures', [
            'awaiting_delivery' => $awaiting['amount'],
            'orders_awaiting_delivery' => $awaiting['orders'],
            'pending' => $pending,
            'available' => $balances['wallet']['profit'],
        ]);

        if ($fundId !== null) {
            unset($balances['deals'][$fundId]);
        }

        $investor->setAttribute('balances', $balances);
        $investor->setAttribute('fund', $this->fundStanding->forInvestor((int) $investor->getKey()));

        // **فتراتُه بدل صفقاته** — قرارُ المالك 2026-09-25: الصفحةُ لا ترسم `balances.deals` بعدها.
        $investor->setAttribute('periods', $this->periods->forInvestor((int) $investor->getKey()));

        return $this->success(new InvestorResource($investor));
    }

    /**
     * Update an investor
     */
    public function update(UpdateInvestorRequest $request, Investor $investor): JsonResponse
    {
        return $this->success(
            new InvestorResource($this->investors->updateInvestor($investor, InvestorData::fromArray($request->validated()))),
            'تم تحديث بيانات المستثمر',
        );
    }

    /**
     * Activate or retire an investor
     *
     * There is no delete: a man with money in the ledger cannot be removed without the ledger
     * losing its subject.
     */
    public function activation(SetActivationRequest $request, Investor $investor): JsonResponse
    {
        return $this->success(
            new InvestorResource($this->investors->setInvestorActivation($investor, (bool) $request->validated('is_active'))),
            'تم تحديث حالة المستثمر',
        );
    }

    /**
     * An investor's statement
     *
     * Every movement of his money, newest first, each row carrying what it did to each of the
     * four balances. `deposit`, `withdrawal`, `allocation` and `profit_withdrawal` were recorded
     * by a person; `profit`, `loss`, `release` and `profit_release` were written by an order or
     * by a deal closing, and each names the source it came from.
     *
     * Filter with `category` (capital · investment · profit · loss — a reversal follows the row
     * it undoes), `investor_deal_id`, `from` and `to`.
     */
    public function statement(InvestorStatementRequest $request, Investor $investor, InvestorStatementQuery $query): JsonResponse
    {
        $entries = $query((int) $investor->getKey(), $request->filters(), $request->perPage());

        return $this->successWithPagination(InvestorWalletEntryResource::collection($entries));
    }

    /**
     * Record a movement of an investor's money
     *
     * Four types only: `deposit` and `withdrawal` move capital between him and the company,
     * `allocation` commits wallet capital to a deal, and `profit_withdrawal` pays out profit
     * that a closed deal has released.
     *
     * **Profit cannot be withdrawn from a running deal**, and that is not a rule checked here:
     * profit only reaches the wallet when a deal closes, so there is simply no path to it.
     */
    public function storeWalletEntry(StoreWalletEntryRequest $request, Investor $investor): JsonResponse
    {
        $entry = $this->investors->recordWalletEntry(
            WalletEntryData::fromArray($request->validated(), (int) $investor->getKey()),
            $request->user()?->id,
        );

        return $this->created(new InvestorWalletEntryResource($entry), 'تم تسجيل الحركة');
    }

    /**
     * An investor's history
     *
     * Every change to the investor himself, newest first — who made it and what it was before.
     *
     * **His money is not here, deliberately.** The wallet is an append-only ledger rather than a
     * change log, and `GET /investors/{investor}/statement` is the reader built for it.
     *
     * Filter with `event`, `causer_id`, `from` and `to`.
     */
    public function logs(ActivityLogFilterRequest $request, Investor $investor, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $investor, $audit);
    }

    /**
     * Reverse a wallet entry
     *
     * **الشريحة ٠ب**: المؤشّرُ `can_be_reversed` كان يُرسَل إلى التطبيق منذ البداية بلا مسارٍ
     * خلفه. والإبطالُ هنا يبطل ما تبع الحركةَ أيضاً — صفَّ الخزينة ووحداتِ الصندوق — وإلا بقيت
     * نسبةُ رجلٍ استُرجع مالُه تقاسم ربحاً لا يموّله.
     */
    public function reverseWalletEntry(Request $request, int $investor, int $entry): JsonResponse
    {
        $validated = $request->validate([
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $row = InvestorWalletEntry::query()
            ->where('investor_id', $investor)
            ->whereKey($entry)
            ->firstOrFail();

        $reversal = app(ReverseWalletEntry::class)(
            $row,
            $request->user()?->id,
            $validated['notes'] ?? null,
        );

        return $this->success(
            ['id' => $reversal->id],
            'أُبطلت الحركة — ومعها ما تبعها في الخزينة والوحدات',
        );
    }
}
