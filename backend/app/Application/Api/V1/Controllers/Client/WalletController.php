<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers\Client;

use App\Application\Api\V1\Requests\Order\PayOrderFromWalletRequest;
use App\Application\Api\V1\Resources\Client\ClientOrderDetailResource;
use App\Application\Api\V1\Resources\Client\ClientWalletEntryResource;
use App\Application\Controller;
use App\Domain\Customer\Models\Customer;
use App\Domain\Order\OrderService;
use App\Domain\Order\Support\Money;
use App\Domain\Wallet\Enums\WalletEntryType;
use App\Domain\Wallet\WalletService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * My wallet
 *
 * The signed-in customer's wallet — Docs/payments/CUSTOMER-WALLET.md. Topped up, spent on orders,
 * and never paid out. Always the customer's own: no route here takes a customer id.
 */
class WalletController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly WalletService $wallet,
        private readonly OrderService $orders,
    ) {}

    /**
     * My balance
     */
    public function show(Request $request): JsonResponse
    {
        return $this->success([
            'balance' => $this->wallet->balanceOf($this->customerId($request)),
        ]);
    }

    /**
     * My transactions
     *
     * Newest first, paginated. `balance` in `meta` is the wallet as it stands.
     */
    public function entries(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'type' => ['nullable', Rule::enum(WalletEntryType::class)],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);
        $customerId = $this->customerId($request);

        return $this->successWithPagination(
            ClientWalletEntryResource::collection($this->wallet->entriesOf($customerId, $filters, $perPage)),
            extraMeta: ['balance' => $this->wallet->balanceOf($customerId)],
        );
    }

    /**
     * Pay an order from my wallet
     *
     * `amount` may be left out: the wallet then pays as much as it holds, up to what the order
     * owes. Refused while the order awaits the shop's review, and beyond either the balance or
     * the debt.
     *
     * `client_token` makes a retry safe: the same token again — a connection that dropped after
     * the payment — returns 200 with the order as it stands and pays nothing.
     */
    public function payOrder(PayOrderFromWalletRequest $request, int $order): JsonResponse
    {
        $customerId = $this->customerId($request);
        $owned = $this->orders->findForCustomer($customerId, $order);
        $amount = $request->validated('amount');

        $payment = $this->orders->payFromWallet(
            $owned,
            $amount === null ? null : Money::normalize($amount),
            clientToken: $request->validated('client_token'),
        );

        $data = [
            'order' => new ClientOrderDetailResource($this->orders->findForCustomer($customerId, $order)),
            'balance' => $this->wallet->balanceOf($customerId),
        ];

        return $payment->wasRecentlyCreated
            ? $this->created($data, 'تم الدفع من المحفظة')
            : $this->success($data, 'هذه الدفعة مسجَّلة من قبل');
    }

    /**
     * The signed-in customer. The route group's `auth:customer` is what makes this true.
     */
    private function customerId(Request $request): int
    {
        $customer = $request->user();

        assert($customer instanceof Customer);

        return (int) $customer->getKey();
    }
}
