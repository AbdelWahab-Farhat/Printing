<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Requests\Order\ReviewOrderPaymentRequest;
use App\Application\Api\V1\Resources\OrderPaymentResource;
use App\Application\Controller;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Enums\OrderPaymentType;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Models\OrderPayment;
use App\Domain\Order\OrderService;
use App\Support\ResponseTrait;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Payment review
 *
 * «مراجعة الدفعات»: somebody holding `orders.payments.review` checks each payment and refund, and
 * says it is right — their own entries included.
 *
 * **Nothing waits for it.** An unreviewed entry counts, settles and moves the treasury exactly
 * like a reviewed one; what the review feeds is the queue below.
 *
 * Payments recorded before reviews existed are exempt, and so are entries that moved no cash of
 * ours — `requires_review` is false on both. See Docs/payments/PAYMENT-REVIEW-AND-OVERPAY.md.
 */
class OrderPaymentReviewController extends Controller
{
    use ResponseTrait;

    public function __construct(private readonly OrderService $orders) {}

    /**
     * The review queue
     *
     * Every payment and refund still waiting for a review, across all orders, **oldest first** —
     * it is a work list. Reversed entries leave it, and so do entries on a deleted order.
     *
     * `meta.total` is the count to put on the tab; `meta.incoming_total` and
     * `meta.outgoing_total` are what the whole filtered list adds up to, money in and money out
     * apart.
     */
    public function queue(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date', 'after_or_equal:from'],
            'account_id' => ['nullable', 'integer'],
            'recorded_by' => ['nullable', 'integer'],
            /** `payment` or `refund` — the two kinds of entry a review covers. */
            'type' => ['nullable', Rule::in([OrderPaymentType::Payment->value, OrderPaymentType::Refund->value])],
        ]);

        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);

        $queue = $this->orders->paymentReviewQueue($filters, $perPage);

        return $this->successWithPagination(
            OrderPaymentResource::collection($queue['page']),
            extraMeta: $queue['totals'],
        );
    }

    /**
     * Review an entry
     *
     * `reviewed: true` stamps who checked it and when; `false` takes the review back.
     *
     * Refused with 422 when the entry was reversed, and when it is not one that needs a review. `can_review` on the entry says so in
     * advance, with the reason in `review_blocked_reason`. Taking a review back is open to anybody
     * holding the grant. Marking an entry somebody already reviewed keeps their review.
     */
    public function update(ReviewOrderPaymentRequest $request, Order $order, OrderPayment $payment): JsonResponse
    {
        $user = $request->user();

        $updated = $this->orders->reviewPayment(
            $payment,
            (bool) $request->validated('reviewed'),
            $user instanceof User ? $user : null,
        );

        return $this->success(
            ['payment' => new OrderPaymentResource($updated->load(['recorder', 'reviewer', 'reversal', 'treasuryAccount']))],
            $updated->isReviewed() ? 'تمت مراجعة الدفعة' : 'أُلغيت مراجعة الدفعة',
        );
    }
}
