<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Wallet\AdjustWalletRequest;
use App\Application\Api\V1\Requests\Wallet\ReverseWalletEntryRequest;
use App\Application\Api\V1\Requests\Wallet\TopUpWalletRequest;
use App\Application\Api\V1\Resources\CustomerWalletEntryResource;
use App\Application\Controller;
use App\Domain\Customer\Models\Customer;
use App\Domain\Identity\Models\User;
use App\Domain\Wallet\DTOs\TopUpData;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\Models\CustomerWalletEntry;
use App\Domain\Wallet\Support\Money;
use App\Domain\Wallet\WalletService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Customer wallets
 *
 * «محفظة الزبون» for staff — Docs/payments/CUSTOMER-WALLET.md. One wallet per customer: it is
 * topped up and spent on orders, and **never paid out**. Every row is written once and never
 * edited; a mistaken top-up or adjustment is undone by `reverse`, which writes a second row.
 *
 * Paying an order from the wallet is `POST orders/{order}/payments/from-wallet`, beside the
 * order's other payments.
 */
class CustomerWalletController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly WalletService $wallet) {}

    /**
     * A customer's wallet
     *
     * The balance, and the newest rows.
     */
    public function show(Customer $customer): JsonResponse
    {
        return $this->success([
            'customer_id' => $customer->id,
            'balance' => $this->wallet->balanceOf((int) $customer->id),
            'recent' => CustomerWalletEntryResource::collection(
                $this->wallet->entriesOf((int) $customer->id, [], 5)->getCollection(),
            ),
        ]);
    }

    /**
     * A customer's wallet statement
     *
     * Newest first, paginated. `balance` in `meta` is the wallet as it stands.
     */
    public function entries(Request $request, Customer $customer): JsonResponse
    {
        $filters = $this->filters($request);

        return $this->successWithPagination(
            CustomerWalletEntryResource::collection(
                $this->wallet->entriesOf((int) $customer->id, $filters, $this->perPage($request)),
            ),
            extraMeta: ['balance' => $this->wallet->balanceOf((int) $customer->id)],
        );
    }

    /**
     * «المعاملات المالية» — every wallet
     *
     * Every customer's wallet rows on one page, newest first. `q` matches a customer's name,
     * phone or code.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $this->filters($request) + $request->validate([
            'customer_id' => ['nullable', 'integer'],
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        return $this->successWithPagination(
            CustomerWalletEntryResource::collection($this->wallet->allEntries($filters, $this->perPage($request))),
        );
    }

    /**
     * Top up a wallet
     *
     * Money handed over at the counter. It lands in the account the treasury picks for the method
     * (or the one chosen), and the wallet owes it to the customer. A transfer needs its receipt.
     */
    public function topUp(TopUpWalletRequest $request, Customer $customer): JsonResponse
    {
        $entry = $this->wallet->topUp(
            (int) $customer->id,
            TopUpData::fromArray($request->validated()),
            $this->actorId($request),
        );

        return $this->created($this->written($entry), 'تم شحن المحفظة');
    }

    /**
     * Adjust a balance
     *
     * A correction by hand, with a reason. A debit may not take the wallet below zero.
     */
    public function adjust(AdjustWalletRequest $request, Customer $customer): JsonResponse
    {
        $entry = $this->wallet->adjust(
            (int) $customer->id,
            Money::normalize($request->validated('amount')),
            $request->validated('direction') === 'credit',
            (string) $request->validated('reason'),
            $this->actorId($request),
        );

        return $this->created($this->written($entry), 'تم تعديل الرصيد');
    }

    /**
     * Undo a wallet row
     *
     * A top-up or an adjustment written by mistake. Refused when the money was already spent —
     * reverse the order payment it paid first. A payment from the wallet or a refund into it is
     * undone on the order's own ledger.
     */
    public function reverse(ReverseWalletEntryRequest $request, CustomerWalletEntry $entry): JsonResponse
    {
        $reversal = $this->wallet->reverse($entry, (string) $request->validated('reason'), $this->actorId($request));

        return $this->created($this->written($reversal), 'تم عكس الحركة');
    }

    /**
     * @return array<string, mixed>
     */
    private function written(CustomerWalletEntry $entry): array
    {
        return [
            'entry' => new CustomerWalletEntryResource($entry->load(['recorder', 'treasuryAccount', 'reversal', 'reversedEntry'])),
            'balance' => $this->wallet->balanceOf((int) $entry->customer_id),
        ];
    }

    /**
     * @return array{type?: ?string, from?: ?string, to?: ?string}
     */
    private function filters(Request $request): array
    {
        return $request->validate([
            'type' => ['nullable', Rule::enum(WalletEntryType::class)],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);
    }

    private function perPage(Request $request): int
    {
        return min(max((int) $request->integer('per_page', 20), 1), 100);
    }

    private function actorId(Request $request): ?int
    {
        $user = $request->user();

        return $user instanceof User ? (int) $user->getKey() : null;
    }
}
