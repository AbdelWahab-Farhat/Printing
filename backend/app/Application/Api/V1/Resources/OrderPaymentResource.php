<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Identity\Enums\PermissionName;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Models\OrderPayment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin OrderPayment
 */
class OrderPaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'order_id' => $this->order_id,

            'type' => $this->type->value,
            'type_label' => $this->type->label(),

            // Always positive. Which direction it moves is the type's business — see the model.
            // A string, like every other money field: what was stored reaches the client exactly.
            'amount' => (string) $this->amount,

            // How much of [amount] was beyond the order — owed back to the customer — or, on a
            // refund, how much of it handed that back. «0.00» on nearly every entry.
            'excess_amount' => (string) $this->excess_amount,

            // Null on a reversal alone, because no money moved for it to have a method.
            'method' => $this->method?->value,
            'method_label' => $this->method?->label(),

            'reference' => $this->reference,

            // Where the money landed. Null on entries that moved none, and on every entry from
            // before the treasury — see `OrderPayment::treasuryAccount()`.
            'treasury_account_id' => $this->treasury_account_id,
            'treasury_account' => $this->whenLoaded('treasuryAccount', fn (): ?array => $this->treasuryAccount === null ? null : [
                'id' => $this->treasuryAccount->id,
                'name' => $this->treasuryAccount->name,
                'kind' => $this->treasuryAccount->kind->value,
            ]),

            // The receipt (الواصل) — always present on a transfer, because nothing else proves
            // one happened. The URL is built per request rather than stored: the disk is private,
            // so in production this is a signed link that expires, and a permanent one sitting in
            // a JSON payload would be somebody's bank details left on the table.
            'has_receipt' => $this->hasReceipt(),
            // Whether it is a picture the app can draw full screen, or a PDF it hands to the
            // phone. Decided here from the stored file, so the app holds no format list.
            'receipt_is_image' => $this->receiptIsImage(),
            'receipt_url' => $this->receiptUrl(),
            'receipt_filename' => $this->receipt_original_filename,
            'receipt_size_bytes' => $this->receipt_size_bytes,

            // When the money moved. `created_at` beside it is when somebody typed it in, and the
            // two genuinely differ on a back-dated deposit — both are published because a cash
            // report needs the first and an audit needs the second.
            'paid_at' => $this->paid_at?->toIso8601String(),

            'notes' => $this->notes,

            // **The two flags the app draws its ledger from**, so no copy of the rules lives in
            // Dart. `is_reversed` strikes the row through; `is_reversible` is what puts a cancel
            // action on it — and the server has already decided that a refund and a reversal
            // are not candidates.
            'is_reversed' => $this->isReversed(),
            'is_reversible' => $this->isReversible(),

            // Which entry this one undoes, on a reversal.
            'reverses_payment_id' => $this->reverses_payment_id,

            // And the other way round, so a struck-through row can name its correction without
            // the client pairing rows up by eye.
            'reversal' => $this->whenLoaded('reversal', fn (): ?array => $this->reversal === null ? null : [
                'id' => $this->reversal->id,
                'reason' => $this->reversal->notes,
                'created_at' => $this->reversal->created_at?->toIso8601String(),
            ]),

            'recorded_by' => $this->recorded_by,
            'recorder' => $this->whenLoaded('recorder', fn (): ?array => $this->recorder === null ? null : [
                'id' => $this->recorder->id,
                'name' => $this->recorder->name,
                'employee_code' => $this->recorder->employee_code,
            ]),

            // «مراجعة الدفعات». `requires_review` false is a row nobody is asked to check — a
            // reversal, a write-off, or a payment from before reviews existed — and the app draws
            // no badge on it at all.
            'requires_review' => (bool) $this->requires_review,
            'is_reviewed' => $this->isReviewed(),
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'reviewer' => $this->whenLoaded('reviewer', fn (): ?array => $this->reviewer === null ? null : [
                'id' => $this->reviewer->id,
                'name' => $this->reviewer->name,
            ]),
            ...$this->reviewAbilities($request),

            // The order the entry belongs to — on the review queue, where rows from many orders
            // sit together. Absent on an order's own ledger, which is already about one order.
            'order' => $this->whenLoaded('order', fn (): ?array => $this->order === null ? null : [
                'id' => $this->order->id,
                'code' => $this->order->code,
                'customer_name' => $this->order->relationLoaded('customer') ? $this->order->customer?->name : null,
            ]),

            // No `updated_at`: a ledger entry is never updated, and publishing one would invite
            // a client to believe it could be. A review is the one exception, and it carries its
            // own stamp above.
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * What the signed-in person may do about the review, decided here so the app keeps no copy of
     * the rule. `review_blocked_reason` is the sentence to write under a greyed button — a
     * reversed payment — and is null whenever there is no button to grey.
     *
     * @return array{can_review: bool, can_unreview: bool, review_blocked_reason: ?string}
     */
    private function reviewAbilities(Request $request): array
    {
        $user = $request->user();
        $user = $user instanceof User ? $user : null;

        $granted = $user?->can(PermissionName::ReviewOrderPayments->value) ?? false;

        if (! $granted || ! $this->requires_review) {
            return ['can_review' => false, 'can_unreview' => false, 'review_blocked_reason' => null];
        }

        if ($this->isReviewed()) {
            return ['can_review' => false, 'can_unreview' => true, 'review_blocked_reason' => null];
        }

        $refusal = $this->resource->reviewRefusal();

        return [
            'can_review' => $refusal === null,
            'can_unreview' => false,
            'review_blocked_reason' => $refusal?->getMessage(),
        ];
    }
}
