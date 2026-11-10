<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Treasury\StoreTreasuryAccountRequest;
use App\Application\Api\V1\Requests\Treasury\UpdateTreasuryAccountRequest;
use App\Application\Api\V1\Resources\TreasuryAccountResource;
use App\Application\Api\V1\Resources\TreasuryMovementResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Carrier\CarrierService;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\OrderService;
use App\Domain\Treasury\DTOs\AccountData;
use App\Domain\Treasury\Enums\Currency;
use App\Domain\Treasury\Enums\MovementKind;
use App\Domain\Treasury\Models\TreasuryAccount;
use App\Domain\Treasury\Models\TreasuryMovement;
use App\Domain\Treasury\Support\Money;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * الحسابات والكاش — the accounts, their balances and their history.
 *
 * **Reading is not behind route middleware.** `treasury.view` opens every account; without it a
 * person still reads the accounts in their own name — a driver sees what he is holding. The
 * rule is `TreasuryService::canRead()`, asked here, per account.
 */
class TreasuryAccountController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    public function __construct(private readonly TreasuryService $treasury) {}

    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $accounts = $this->treasury->accountsFor($user, $request->boolean('active_only'));

        $active = $accounts->where('is_active', true);
        $money = $active->filter(fn (TreasuryAccount $a) => $a->kind->holdsMoney());
        $payables = $active->reject(fn (TreasuryAccount $a) => $a->kind->holdsMoney());

        // Dollars count at «سعر النظام», as in «لمن المال» (USD-ACCOUNTS §٣); with no rate they
        // stay out of the dinar total and are said beside it.
        $rate = $this->treasury->settings()->usd_rate;
        $inDinars = fn (string $dollars): ?string => $rate === null ? null : Money::round(bcmul($dollars, (string) $rate, 8));

        $dollars = $this->sum($money->filter(fn (TreasuryAccount $a) => $a->isDollar()));
        $dollarsInDinars = $inDinars($dollars);

        // A vendor's dollar «علينا» (§٤), as a positive figure in dollars.
        $owedDollars = bcmul($this->sum($payables->filter(fn (TreasuryAccount $a) => $a->isDollar())), '-1', 2);
        $owedDollarsInDinars = $inDinars($owedDollars);

        return $this->success([
            'accounts' => TreasuryAccountResource::collection($accounts),
            // Only the accounts the caller can see — for a holder, their own money, not the shop's.
            // Money only: a debt is not a dinar in any drawer, and an older app adds up `total`.
            'total' => bcadd(
                $this->sum($money->reject(fn (TreasuryAccount $a) => $a->isDollar())),
                $dollarsInDinars ?? '0',
                2,
            ),
            'usd_total' => bcadd($dollars, '0', 2),
            'usd_rate' => $rate === null ? null : (string) $rate,
            'usd_total_in_lyd' => $dollarsInDinars,
            // «علينا» — what the payables owe, as a positive figure (§٢٠). The dollar ones count
            // at «سعر النظام», like the money above, and are said beside it.
            'payables_total' => bcadd(
                bcmul($this->sum($payables->reject(fn (TreasuryAccount $a) => $a->isDollar())), '-1', 2),
                $owedDollarsInDinars ?? '0',
                2,
            ),
            'usd_payables_total' => $owedDollars,
            'usd_payables_total_in_lyd' => $owedDollarsInDinars,
            'can_view_all' => $this->treasury->canViewAll($user),
        ]);
    }

    /**
     * @param  Collection<int, TreasuryAccount>  $accounts
     */
    private function sum(Collection $accounts): string
    {
        $total = '0';

        foreach ($accounts as $account) {
            $total = bcadd($total, (string) $account->getAttribute('balance'), 2);
        }

        return $total;
    }

    public function show(Request $request, TreasuryAccount $account): JsonResponse
    {
        $this->authorizeRead($request, $account);

        $this->treasury->withBalances(new Collection([$account->load(['holder', 'settlesInto'])]));

        return $this->success([
            'account' => new TreasuryAccountResource($account),
            'totals' => $this->treasury->totalsOf($account),
        ]);
    }

    public function store(StoreTreasuryAccountRequest $request): JsonResponse
    {
        $account = $this->treasury->createAccount(AccountData::fromArray($request->validated()), $request->user());

        return $this->created(new TreasuryAccountResource($this->loaded($account)), 'تم إنشاء الحساب');
    }

    public function update(UpdateTreasuryAccountRequest $request, TreasuryAccount $account): JsonResponse
    {
        $account = $this->treasury->updateAccount($account, AccountData::fromArray($request->validated()));

        return $this->success(new TreasuryAccountResource($this->loaded($account)), 'تم حفظ الحساب');
    }

    public function movements(Request $request, TreasuryAccount $account, OrderService $orders): JsonResponse
    {
        $this->authorizeRead($request, $account);

        $filters = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
            'kind' => ['nullable', Rule::enum(MovementKind::class)],
            'order_id' => ['nullable', 'integer'],
            'has_order' => ['nullable', 'boolean'],
            'search' => ['nullable', 'string', 'max:50'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);

        $page = $this->treasury->ledger($account, $filters, $perPage);

        $this->attachPaymentReviews($page->getCollection(), $orders);

        return $this->successWithPagination(TreasuryMovementResource::collection($page));
    }

    /**
     * «غير مراجَعة / تمت المراجعة» on the lines a customer's payment or refund moved.
     *
     * **Asked of the orders here, not by the treasury**, which knows nothing of order payments —
     * one query for the page. A reversal's line carries none: the mirror undoes money, and a
     * badge on it would read as a review of the undoing. The resource publishes it as
     * `payment_review`, present only on this endpoint.
     *
     * @param  Collection<int, TreasuryMovement>  $movements
     */
    private function attachPaymentReviews(Collection $movements, OrderService $orders): void
    {
        $alias = (new OrderPayment)->getMorphClass();

        $lines = $movements->filter(
            fn (TreasuryMovement $movement): bool => $movement->source_type === $alias && ! $movement->isReversal(),
        );

        $states = $orders->reviewStatesOf(
            $lines->map(fn (TreasuryMovement $movement): int => (int) $movement->source_id)->unique()->values()->all(),
        );

        foreach ($lines as $movement) {
            $movement->setRelation('paymentReview', $states[(int) $movement->source_id] ?? null);
        }
    }

    /**
     * What a picker offers for a payment method, and which account it opens on for this person.
     *
     * `purpose=out` for money leaving — a refund, an expense — which is never taken from custody.
     * Open to anybody signed in: it names accounts, not balances, and every payment form needs it.
     */
    public function options(Request $request, OrderService $orders, CarrierService $carrier): JsonResponse
    {
        $validated = $request->validate([
            'method' => ['required', 'string', Rule::in(['cash', 'bank_transfer', 'bank_card', 'libyana'])],
            'purpose' => ['nullable', Rule::in(['in', 'out'])],
            // The order the money is for: while it waits at a branch, «تلقائي» is that branch's
            // cash box (§١٩).
            'order_id' => ['nullable', 'integer'],
            // `USD` for a dollar debt paid out (USD-ACCOUNTS §٦): the dollar accounts alone, and
            // no «تلقائي».
            'currency' => ['nullable', Rule::enum(Currency::class)],
        ]);

        $orderId = isset($validated['order_id']) ? (int) $validated['order_id'] : null;

        $options = $this->treasury->accountOptions(
            (string) $validated['method'],
            $request->user(),
            ($validated['purpose'] ?? 'in') === 'in',
            $orderId === null ? null : $orders->pickupOfficeOf($orderId),
            // والطردُ في الطريق: «تلقائي» هو النورس، كما تختاره الدفعةُ نفسها.
            carrierHolds: $orderId !== null && $carrier->hasParcelOnTheRoad($orderId),
            currency: isset($validated['currency']) ? Currency::from((string) $validated['currency']) : Currency::Lyd,
        );

        return $this->success([
            'accounts' => $options['accounts']->map(fn (TreasuryAccount $account) => [
                'id' => $account->id,
                'name' => $account->name,
                'kind' => $account->kind->value,
                'kind_label' => $account->kind->label(),
                'is_default' => (bool) $account->is_default,
            ])->values(),
            // Null for dollars: a dollar payment names its drawer (USD-ACCOUNTS §٦).
            'suggested_id' => $options['suggested']?->id,
            // بالاسم أيضاً: المقترحُ قد يكون حساباً لا يُختار باليد فليس في القائمة — النورس.
            'suggested_name' => $options['suggested']?->name,
        ]);
    }

    public function logs(ActivityLogFilterRequest $request, TreasuryAccount $account, AuditService $audit): JsonResponse
    {
        return $this->auditTrailResponse($request, $account, $audit);
    }

    private function authorizeRead(Request $request, TreasuryAccount $account): void
    {
        /** @var User $user */
        $user = $request->user();

        if (! $this->treasury->canRead($user, $account)) {
            throw new AuthorizationException('لا تملك صلاحية عرض هذا الحساب');
        }
    }

    private function loaded(TreasuryAccount $account): TreasuryAccount
    {
        $this->treasury->withBalances(new Collection([$account->load(['holder', 'settlesInto'])]));

        return $account;
    }
}
