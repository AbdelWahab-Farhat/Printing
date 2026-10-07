<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Order\SettleOrderPaymentsRequest;
use App\Application\Api\V1\Requests\Order\UnsettleOrderPaymentRequest;
use App\Application\Api\V1\Resources\OrderPaymentResource;
use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\OrderService;
use App\Domain\Order\Queries\PaymentSettlementQueue;
use App\Domain\Treasury\TreasuryService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Payment settlement
 *
 * «تسوية دفعة»: one payment's money carried from the account it landed in — Nawris, a driver,
 * «مصرف علي», a branch's box — to the account it really reached, **without waiting for the order
 * to reach «تم التسوية»**. Neither the order's status nor what was paid changes.
 *
 * Every settlement can be taken back, with a reason. See TREASURY-DESIGN §٢٣.
 */
class OrderPaymentSettlementController extends Controller
{
    use ResponseTrait;

    public function __construct(
        private readonly OrderService $orders,
        private readonly TreasuryService $treasury,
    ) {}

    /**
     * The settlement list
     *
     * `state=pending` (the default): payments whose money is still where it landed, on orders
     * not yet settled, **oldest first**; the dates filter the day the money was taken. A payment
     * straight into its final account is never listed.
     *
     * `state=settled`: payments settled on their own, **newest settlement first**; the dates
     * filter the day they were settled.
     *
     * `meta.amount_total` is what the whole filtered list adds up to; `meta.total` counts its rows.
     */
    public function queue(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'state' => ['nullable', Rule::in([PaymentSettlementQueue::PENDING, PaymentSettlementQueue::SETTLED])],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            /** Where the money landed — Nawris, «مصرف علي»… */
            'account_id' => ['nullable', 'integer'],
            /** An order code, or part of a customer's name. */
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);
        $user = $request->user();

        $queue = $this->orders->paymentSettlementQueue($filters, $perPage, $user instanceof User ? $user : null);

        return $this->successWithPagination(
            OrderPaymentResource::collection($queue['page']),
            extraMeta: $queue['totals'],
        );
    }

    /**
     * The settlement accounts
     *
     * `sources`: where payments wait to be settled — Nawris, a driver, «مصرف علي» — for the
     * page's filter. `destinations`: every active cash box, bank and wallet, where money may be
     * settled to. Names, never balances.
     */
    public function accounts(Request $request): JsonResponse
    {
        $user = $request->user();

        return $this->success(
            $this->treasury->settlementAccounts($user instanceof User ? (int) $user->getKey() : null),
        );
    }

    /**
     * Settle payments
     *
     * One payment or several, all or nothing. `account_id` empty sends each to its own automatic
     * account (`settlement_target` on the payment); a payment with no automatic account needs one
     * named. `fee` is what Nawris or a driver kept — only on money held in custody.
     *
     * Refused with 422 under `payments.{i}.payment_id` for a refund, a reversed payment, a payment
     * from before the treasury, an order already «تم التسوية», a payment settled before, or money
     * no longer in its account.
     */
    public function settle(SettleOrderPaymentsRequest $request): JsonResponse
    {
        $user = $request->user();
        $accountId = $request->validated('account_id');

        $payments = $this->orders->settlePayments(
            $request->rows(),
            $accountId === null ? null : (int) $accountId,
            $user instanceof User ? $user : null,
        );

        return $this->success(
            ['payments' => OrderPaymentResource::collection($payments)],
            $payments->count() === 1 ? 'تمت تسوية الدفعة' : 'تمت تسوية الدفعات',
        );
    }

    /**
     * Undo a payment's settlement
     *
     * The money goes back to the account it landed in. Refused while the order is «تم التسوية» —
     * un-settle the order first.
     */
    public function unsettle(UnsettleOrderPaymentRequest $request, Order $order, OrderPayment $payment): JsonResponse
    {
        $user = $request->user();

        $updated = $this->orders->unsettlePayment(
            $order,
            $payment,
            (string) $request->validated('reason'),
            $user instanceof User ? $user : null,
        );

        return $this->success(
            ['payment' => new OrderPaymentResource($updated)],
            'أُلغيت تسوية الدفعة',
        );
    }
}
