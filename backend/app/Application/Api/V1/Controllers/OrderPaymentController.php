<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Order\RefundOrderPaymentRequest;
use App\Application\Api\V1\Requests\Order\ReverseOrderPaymentRequest;
use App\Application\Api\V1\Requests\Order\StoreOrderPaymentRequest;
use App\Application\Api\V1\Resources\OrderPaymentResource;
use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\OrderService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Order payments
 *
 * An order's money ledger: what the customer has paid, what was given back, and what was entered
 * by mistake and cancelled.
 *
 * **Entries are written once and never edited.** There is no `PUT` and no `DELETE` here, by
 * design — a ledger that can be rewritten explains nothing, and being able to explain is why
 * this exists instead of a `paid_amount` column that goes up and down. A mistake is undone by
 * `POST /payments/{payment}/reverse`, which writes a second entry beside the wrong one and
 * leaves both readable.
 *
 * **Three write endpoints rather than one carrying a `type`.** A payment names a method, a
 * reversal names only a reason, and a refund sits between them — one route with a discriminator
 * and four optional fields would document a shape none of the three actually has.
 *
 * Money is never trusted from the client beyond the amount itself: `paid_amount` on the order is
 * derived from these rows, and the signed-in user is stamped onto every entry, so no payload can
 * attribute a collection to a colleague.
 */
class OrderPaymentController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly OrderService $orders) {}

    /**
     * An order's ledger
     *
     * Oldest first — a ledger is read as a story, and a correction printed above the entry it
     * corrects makes a reader work backwards.
     *
     * Not paginated: an order's entries are counted on one hand, and a page boundary through a
     * ledger would hide the reversal that explains the row above it.
     */
    public function index(Order $order): JsonResponse
    {
        return $this->success([
            'payments' => OrderPaymentResource::collection($this->orders->payments($order)),
            // The three numbers the screen puts side by side, from the one place that computes
            // them. A client subtracting these itself would be a second answer to one question,
            // and its answer is the one made of doubles.
            'summary' => $this->summary($order),
        ]);
    }

    /**
     * Record a payment
     *
     * Refused with 422 when the amount is larger than what the order still owes — the ordinary
     * cause is a slipped keystroke at a counter, and the moment to catch it is while the customer
     * is still standing there.
     *
     * Also refused on a cancelled order: there is nothing left to pay for. Refunds stay open on
     * one, which is where a deposit most often has to go back.
     *
     * `paid_at` may be back-dated and defaults to now.
     */
    public function store(StoreOrderPaymentRequest $request, Order $order): JsonResponse
    {
        $payment = $this->orders->recordPayment(
            $order,
            OrderPaymentData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->created(
            $this->entry($payment, $order),
            'تم تسجيل الدفعة بنجاح',
        );
    }

    /**
     * Refund an amount
     *
     * Money genuinely handed back — **not** the way to fix a mistyped entry, which is
     * `reverse` below. The two subtract the same figure and answer entirely different questions:
     * a refund is a cash event a report should count, and a typo is not.
     *
     * Bounded by what the order has actually been paid, and allowed in every status.
     */
    public function refund(RefundOrderPaymentRequest $request, Order $order): JsonResponse
    {
        $refund = $this->orders->refundPayment(
            $order,
            OrderPaymentData::fromArray($request->validated()),
            $this->actor($request),
        );

        return $this->created(
            $this->entry($refund, $order),
            'تم تسجيل ردّ المبلغ بنجاح',
        );
    }

    /**
     * Cancel an entry
     *
     * For an entry that should never have been written. The wrong row stays exactly where it is
     * and a second row beside it says so and points at it, so a reader a month later sees what
     * was typed, that it was caught, and by whom.
     *
     * The reversal carries the original's amount — a partial undo is not an undo. `reason` is
     * required.
     *
     * Only a payment can be cancelled, and only once: reversing a reversal is a maze, and undoing
     * a refund is a *payment*, because the customer really did hand the money back.
     */
    public function reverse(
        ReverseOrderPaymentRequest $request,
        Order $order,
        OrderPayment $payment,
    ): JsonResponse {
        $reversal = $this->orders->reversePayment(
            $order,
            $payment,
            (string) $request->validated('reason'),
            $this->actor($request),
        );

        return $this->created(
            $this->entry($reversal, $order),
            'تم إلغاء الدفعة',
        );
    }

    /**
     * One entry, with the order's money as it stands after it.
     *
     * The summary travels back with every write so a screen never has to re-fetch the order to
     * learn what the entry it just made did to the total.
     *
     * @return array<string, mixed>
     */
    private function entry(OrderPayment $payment, Order $order): array
    {
        return [
            'payment' => new OrderPaymentResource($payment->load(['recorder', 'reversal'])),
            'summary' => $this->summary($order->refresh()),
        ];
    }

    /**
     * The order's money in the shape the app draws it: total, paid, remaining, and where it
     * stands.
     *
     * @return array<string, mixed>
     */
    private function summary(Order $order): array
    {
        return [
            'grand_total' => (string) $order->grand_total,
            'paid_amount' => (string) $order->paid_amount,
            'remaining_amount' => $order->remainingAmount(),
            'payment_status' => $order->paymentStatus()->value,
            'payment_status_label' => $order->paymentStatus()->label(),
            // An order that finished without its money accounted for. See Order::hasUnrecordedMoney().
            'has_unrecorded_money' => $order->hasUnrecordedMoney(),
        ];
    }

    /**
     * The signed-in user, typed for the domain.
     *
     * Passed in rather than reached for inside the actions, so a console command or a test can
     * say who is acting without a global to set up — the same shape {@see OrderController} uses.
     */
    private function actor(Request $request): ?User
    {
        $user = $request->user();

        return $user instanceof User ? $user : null;
    }
}
