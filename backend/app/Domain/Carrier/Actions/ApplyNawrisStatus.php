<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\DTOs\NawrisParcelTerms;
use App\Domain\Carrier\DTOs\NawrisWebhookPayload;
use App\Domain\Carrier\Enums\NawrisStatusCode;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Identity\Models\User;
use App\Domain\Order\Actions\ChangeOrderStatus;
use App\Domain\Order\Actions\RecordCarrierSettlement;
use App\Domain\Order\Actions\RecordOrderPayment;
use App\Domain\Order\DTOs\OrderPaymentData;
use App\Domain\Order\Enums\OrderStatus;
use App\Domain\Order\Enums\PaymentMethod;
use App\Domain\Order\Models\Order;
use App\Domain\Order\Support\Money;
use App\Domain\Treasury\Models\TreasuryAccount;
use Illuminate\Support\Facades\DB;

/**
 * Everything a webhook is allowed to do to an order, and the three guards that stand in front.
 *
 * **This is the whole risk surface of the integration.** It is the only thing that moves an order
 * on the word of an unauthenticated POST, and the only thing that writes to the ledger without a
 * person deciding to. Every guard here exists because of an incident recorded in the contract;
 * reimplementing the mapping without them reimplements the incidents.
 *
 * The order matters and is not negotiable: **idempotency first, conflict second, price alert
 * third.**
 */
final class ApplyNawrisStatus
{
    public function __construct(
        private readonly ChangeOrderStatus $changeStatus,
        private readonly RecordOrderPayment $recordPayment,
        private readonly RecordCarrierSettlement $recordCarrierSettlement,
        private readonly ReadNawrisParcelTerms $readTerms,
        private readonly EditNawrisParcel $edit,
    ) {}

    public function __invoke(
        NawrisWebhookEvent $event,
        NawrisParcel $parcel,
        NawrisWebhookPayload $payload,
        User $actor,
    ): void {
        $code = $payload->status();

        // Taken before anything overwrites it: a second delivery is compared against the first.
        $previouslyCollected = $parcel->collected_amount !== null ? (string) $parcel->collected_amount : null;

        // Their fee and who pays it, as known when this event arrived. Read before the early
        // returns below, because their edits arrive under whatever status the parcel is in —
        // often «محفوظة قبل التوصيل», which is unmapped.
        $terms = ($this->readTerms)($parcel, $event);

        // The raw label lands whatever happens — mapped, unmapped, legal or parked. It is what
        // support reads, and it is never interpreted.
        $this->recordCarrierState($parcel, $payload, $code, $terms);

        // Before the unmapped-code return too: their hand corrections arrive as edits under
        // whatever status the parcel is in.
        $this->recogniseHandCorrection($parcel, $payload, $terms);

        if ($code === null) {
            // An unmapped code must never guess at a state change. The label is stored; the note
            // says so; nothing moves.
            $event->forceFill(['error' => 'رمز حالة غير معروف: '.($payload->statusCode ?? 'null')])->save();

            return;
        }

        $target = $code->target();

        if ($target === null) {
            return;
        }

        // What Nawris should be bringing back for the whole parcel, read once before the first
        // order of a shared parcel is paid and changes the answer for the rest.
        $owed = $this->owedFromNawris($parcel);

        foreach ($parcel->orders as $order) {
            $this->applyToOrder($event, $parcel, $payload, $terms, $code, $target, $order, $actor, $previouslyCollected, $owed);
        }
    }

    private function applyToOrder(
        NawrisWebhookEvent $event,
        NawrisParcel $parcel,
        NawrisWebhookPayload $payload,
        NawrisParcelTerms $terms,
        NawrisStatusCode $code,
        OrderStatus $target,
        Order $order,
        User $actor,
        ?string $previouslyCollected,
        string $owed,
    ): void {
        // ── guard 1: idempotency ─────────────────────────────────────────────────────────
        //
        // **Enum against enum, never against a string.** `orders.status` is a cast enum, and
        // comparing it to a plain string is always false — which leaves the guard passing
        // everything while looking like it works. That is the trap the contract names, and it is
        // silent, so it is worth the explicit type on both sides.
        if ($order->status === $target) {
            // Exception to the skip: a changed amount is still recorded and said out loud, or a
            // repeated delivery notice would swallow the alert along with the duplicate.
            if ($code->collectsMoney()) {
                $this->recordCollected($parcel, $payload);
                $this->flagChangeAfterDelivery($event, $payload, $previouslyCollected);
            }

            return;
        }

        // ── guard 2: delivery conflict ───────────────────────────────────────────────────
        if ($code->collectsMoney() && $this->conflictBlocks($parcel, $payload, $terms, $owed)) {
            $parcel->forceFill(['conflict_raised_at' => now(), 'conflict_resolved_at' => null])->save();

            $event->forceFill([
                'error' => 'تعارض تسليم: رقم طرد مختلف ومبلغ غير مطابق — لم تُنقل الطلبية',
            ])->save();

            return;
        }

        // ── the machine still decides ────────────────────────────────────────────────────
        //
        // Our return chain is walked one link at a time on purpose; Nawris does not walk it. A
        // move it will not accept is parked rather than forced, because forcing it would record a
        // hand-over that never happened. See NAWRIS-INTEGRATION.md §3.2.
        if (! $order->status->canMoveTo($target, $order->production_flow)) {
            $event->forceFill([
                'error' => "نقلة غير مسموحة: «{$order->status->label()}» ← «{$target->label()}»",
            ])->save();

            return;
        }

        DB::transaction(function () use ($event, $parcel, $payload, $terms, $code, $target, $order, $actor, $owed): void {
            if ($code->collectsMoney()) {
                $this->recordCollected($parcel, $payload);
            }

            $this->changeStatusFor($order, $target, $payload, $actor);

            // ── guard 3: a shortfall — alert, never block — is noted inside, once the
            // payment shows what the order is still owed.
            if ($code->collectsMoney()) {
                $this->settleMoney($event, $order, $parcel, $payload, $terms, $owed, $actor);
            }

            // The one moment trustworthy enough to clear an older conflict: the parcel arrived
            // under the code we expected, carrying what we asked for.
            if ($code->collectsMoney() && ! $this->codeDiffers($parcel, $payload) && $parcel->hasOpenConflict()) {
                $parcel->forceFill(['conflict_resolved_at' => now()])->save();
            }

            // Once, by whichever order of a shared parcel moves first. The loop carries on over
            // its siblings regardless: they were loaded before any of this ran.
            if ($code->closesTheParcel() && $parcel->closed_at === null) {
                $parcel->forceFill(['closed_at' => now()])->save();
            }
        }, attempts: 3);
    }

    /**
     * The status move itself, with the courier's number and the carrier's own reason carried on
     * to the timeline.
     */
    private function changeStatusFor(
        Order $order,
        OrderStatus $target,
        NawrisWebhookPayload $payload,
        User $actor,
    ): void {
        // **«إلغاء تام» demands a reason and the webhook has none of its own.**
        // `ChangeOrderStatus` throws `TransitionRequiresReason` on a null, so every code 12 would
        // fail without this. Their `return_reason` when they sent one, a synthetic line naming
        // them when they did not.
        $reason = $target->requiresReason()
            ? ($payload->returnReason ?? 'أُغلقت من قبل شركة نورس (رمز '.$payload->statusCode.')')
            : $payload->returnReason ?? $payload->delayReason;

        ($this->changeStatus)($order, $target, $reason, $actor);

        if ($payload->captainPhone !== null) {
            // Last courier wins — the number you ring is the one holding it now.
            $order->forceFill(['courier_phone' => $payload->captainPhone])->save();
        }
    }

    /**
     * The money, on code 7 only.
     *
     * **What is paid is what Nawris actually collected for us**, not what we asked for: the door
     * amount less their fee when the customer pays it, the door amount itself when we do — see
     * {@see NawrisParcelTerms}. Paying our ask whatever came back marked orders fully paid on
     * money that was never collected. What is short stays owed; a webhook never writes it off.
     *
     * **When that cannot be told, nothing is paid and the event says why** — their fee unknown,
     * a `shipment_on_sender` we cannot read, a shared parcel that came back short. A person enters
     * the payment; a webhook guessing at money is what this replaced.
     *
     * **A second entry for parcels from before 2026-09-08.** The delivery fee we took off the COD
     * then was paid by the customer to the courier, and closes the order without ever reaching our
     * drawer — see `OrderPaymentType::CarrierSettled`.
     *
     * **A shortfall is what the order is still owed once the payment is in**, not the door amount
     * against the parcel's figure. That figure goes stale whenever a payment taken after dispatch
     * fails to reach Nawris, and someone at Nawris then corrects the door amount by hand — the old
     * comparison called a correct delivery short, and overstated a short one by the payment.
     *
     * `carrier_collection_recorded_at` is the last line of defence against a duplicate delivery
     * notice writing either entry twice, and it lives on the *order* so it survives the parcel
     * being deleted, re-created or re-dispatched. It is stamped even when nothing was paid: the
     * webhook has said its piece, and the rest is a person's.
     */
    private function settleMoney(
        NawrisWebhookEvent $event,
        Order $order,
        NawrisParcel $parcel,
        NawrisWebhookPayload $payload,
        NawrisParcelTerms $terms,
        string $owed,
        User $actor,
    ): void {
        $order->refresh();

        if ($order->carrier_collection_recorded_at !== null) {
            return;
        }

        $remitted = $this->remittedFor($event, $order, $parcel, $payload, $terms, $owed);
        $ours = $remitted;

        // **Only a parcel of one order ever carried a fee.** The deduction ended before shared
        // parcels existed, so every shared parcel reads zero here — and if one somehow did not,
        // there would be no telling which order the fee belonged to.
        $fee = $parcel->links()->count() === 1 ? (string) $parcel->delivery_price_deducted : '0.00';

        $remaining = $order->remainingAmount();

        if ($remitted !== null && bccomp($remitted, $remaining, Money::SCALE) > 0) {
            $this->note($event, "تحصيل زائد: الواصل لنا {$remitted} والمتبقي على الطلبية {$remaining} — لم يُسجَّل الفرق");
        }

        // Clamped to what is actually outstanding: `RecordOrderPayment` refuses anything over the
        // remainder, and a webhook must never blow up on an order somebody part-paid at the
        // counter after dispatch. The excess is the note above, not a crash.
        $remitted = $remitted === null ? '0.00' : $this->clamp($remitted, $remaining);

        if ($terms->senderPays()) {
            $this->note($event, 'على حساب المرسل: نورس تخصم أجرتها ('.($terms->fee ?? 'غير معروفة')
                .') مما تحوّله — تُسجَّل في «ما احتفظ به الناقل» عند التسوية');
        }

        // The money changed after the parcel left and Nawris never took the change — so the
        // courier was collecting the old amount. Whatever came back, somebody checks it against
        // what the customer had already paid.
        if ($parcel->moneyOutOfSync()) {
            $this->note($event, 'تغيّر مبلغ الطلبية بعد خروج الطرد ولم تُبلَّغ نورس — راجِع ما حصّله المندوب، فقد يكون الزبون دفع مرتين');
        }

        if (bccomp($remitted, '0', Money::SCALE) > 0) {
            ($this->recordPayment)($order, OrderPaymentData::fromArray([
                'amount' => $remitted,
                'method' => PaymentMethod::Cash->value,
                'notes' => "محصّلة من نورس — الطرد {$parcel->code}",
                // **Into Nawris's custody, not the cash box.** The customer paid cash at the door
                // — that is the method — but the money is with Nawris until it transfers it, and
                // «تم التسوية» is what carries it on (TREASURY-DESIGN §٦). يسمّيه النظام هنا، لا
                // إنسانٌ يختاره — والاختيارُ باليد لحساب النورس يُرفض.
            ])->intoSystemAccount(TreasuryAccount::NAWRIS), $actor);
        }

        $order->refresh();
        $fee = $this->clamp($fee, $order->remainingAmount());

        if (bccomp($fee, '0', Money::SCALE) > 0) {
            ($this->recordCarrierSettlement)(
                $order,
                $fee,
                "أجرة التوصيل محصّلة لدى نورس — الطرد {$parcel->code}",
                $actor,
            );
        }

        // ── guard 3: a shortfall — alert, never block ─────────────────────────────────────
        //
        // Only where the payment was the webhook's to write: where it was not, the note above
        // already says why, and a person is entering it. An earlier version of the system this
        // came from blocked here, and froze orders at "with the courier" while cash that had
        // genuinely been collected sat outside the books.
        $left = $order->refresh()->remainingAmount();

        if ($ours !== null && bccomp($left, '0', Money::SCALE) > 0) {
            $this->note($event, "نقص في التحصيل: بقي على الطلبية {$left} (الواصل لنا {$ours})");
        }

        $order->forceFill(['carrier_collection_recorded_at' => now()])->save();
    }

    /**
     * This order's money out of what the courier took at the door, or null — with the reason
     * noted — when no payment should be written automatically.
     */
    private function remittedFor(
        NawrisWebhookEvent $event,
        Order $order,
        NawrisParcel $parcel,
        NawrisWebhookPayload $payload,
        NawrisParcelTerms $terms,
        string $owed,
    ): ?string {
        if ($payload->collectedAmount === null) {
            $this->note($event, 'لم يصل مع التسليم مبلغ التحصيل — لم تُسجَّل دفعة، أدخلها يدوياً');

            return null;
        }

        $ours = $terms->oursOf($payload->collectedAmount)
            ?? $this->byTheOldCitysFee($terms, $payload->collectedAmount, $owed);

        if ($ours === null) {
            $this->note($event, $this->termsUnknown($terms).' '.$this->whatWasCollected($terms, $payload->collectedAmount));

            return null;
        }

        if ($terms->cityChanged) {
            $this->note($event, $terms->fee === null && ! $terms->senderPays()
                ? "نُقل الطرد لدى نورس إلى مدينة أخرى، والمبلغ مطابق بأجرة المدينة السابقة ({$terms->feeBeforeMove}) — سُجّلت الدفعة، راجِعها"
                : 'نُقل الطرد لدى نورس إلى مدينة أخرى — سُجّلت الدفعة بما حصّله المندوب، راجِعها');
        }

        // **Each order of a shared parcel is paid its own share, never the parcel's figure**, and
        // only when the parcel came back whole: a shortfall has no rule saying which order lost
        // it. The share is the link row's, written at dispatch and on every edit.
        if ($parcel->links()->count() > 1) {
            if ($this->isShort($ours, $owed)) {
                $this->note($event, 'طرد مشترك وصل ناقصاً — لا يُوزَّع النقص على طلبياته تلقائياً، أدخل دفعاتها يدوياً');

                return null;
            }

            return $this->shareOf($parcel, $order);
        }

        return $ours;
    }

    private function termsUnknown(NawrisParcelTerms $terms): string
    {
        if ($terms->cityChanged) {
            return 'نُقل الطرد لدى نورس إلى مدينة أخرى فأجرتها غير معروفة — لم تُسجَّل دفعة، أدخلها يدوياً';
        }

        return match ($terms->shipmentOnSender) {
            NawrisParcelTerms::CUSTOMER_PAYS, NawrisParcelTerms::SENDER_PAYS => 'أجرة نورس على هذا الطرد غير معروفة — لم تُسجَّل دفعة، أدخلها يدوياً',
            default => "قيمة «من يدفع أجرة نورس» غير معروفة ({$terms->shipmentOnSender}) — لم تُسجَّل دفعة، أدخلها يدوياً",
        };
    }

    /**
     * Someone at Nawris put right by hand what our refused edit could not.
     *
     * It happens — hours after a payment our edit never delivered, someone there takes the same
     * amount off by hand. When what their door figure leaves us is exactly what the orders still
     * owe, that is the edit we would have sent, accepted by another road: the refusal is cleared
     * and our figures follow. Anything else stays flagged, with their figure on it.
     */
    private function recogniseHandCorrection(NawrisParcel $parcel, NawrisWebhookPayload $payload, NawrisParcelTerms $terms): void
    {
        if (! $parcel->moneyOutOfSync() || ! $parcel->isOpen() || $payload->collectedAmount === null) {
            return;
        }

        $ours = $terms->oursOf($payload->collectedAmount);

        if ($ours === null || bccomp($ours, $this->owedFromNawris($parcel), Money::SCALE) !== 0) {
            return;
        }

        $this->edit->recordAccepted($parcel);
    }

    /**
     * After a move to another city, ours by the old city's fee — but only when that lands exactly
     * on what the orders still owe.
     *
     * The new city's fee is unknown, so the old one proves nothing by itself. A door amount that
     * leaves exactly the debt after it is another matter: Nawris kept the same figure through the
     * move, and the courier took what we asked. Paid, and noted for a person to check; anything
     * else is still theirs to enter.
     */
    private function byTheOldCitysFee(NawrisParcelTerms $terms, string $door, string $owed): ?string
    {
        if (! $terms->cityChanged || $terms->feeBeforeMove === null || $terms->shipmentOnSender !== NawrisParcelTerms::CUSTOMER_PAYS) {
            return null;
        }

        $ours = $this->less($door, $terms->feeBeforeMove);

        return bccomp($ours, $owed, Money::SCALE) === 0 ? $ours : null;
    }

    /**
     * What the courier took, and what is left for us after Nawris's fee where a fee can be named —
     * so the person entering the payment by hand starts from a figure, not from a blank.
     *
     * After a move to another city the old city's fee is quoted, and said to be the old city's.
     */
    private function whatWasCollected(NawrisParcelTerms $terms, string $door): string
    {
        $line = "(حصّل المندوب {$door}";

        if ($terms->fee !== null) {
            return $line."؛ بعد أجرة نورس ({$terms->fee}) يبقى لنا {$this->less($door, $terms->fee)})";
        }

        if ($terms->feeBeforeMove !== null) {
            return $line."؛ بأجرة المدينة السابقة ({$terms->feeBeforeMove}) يبقى لنا {$this->less($door, $terms->feeBeforeMove)})";
        }

        return $line.')';
    }

    /** `$amount − $fee`, never below zero. */
    private function less(string $amount, string $fee): string
    {
        $left = bcsub($amount, $fee, Money::SCALE);

        return bccomp($left, '0', Money::SCALE) > 0 ? Money::round($left) : '0.00';
    }

    /** Their door figure, kept on the parcel: the raw `order_price`, their fee and all. */
    private function recordCollected(NawrisParcel $parcel, NawrisWebhookPayload $payload): void
    {
        if ($payload->collectedAmount !== null) {
            $parcel->forceFill(['collected_amount' => $payload->collectedAmount])->save();
        }
    }

    /**
     * What Nawris should be bringing back for the parcel: what its orders still owe, less the
     * delivery fee we used to take off the COD on parcels from before 2026-09-08, which the
     * carrier-settled entry closes rather than their money.
     *
     * **What the orders owe, not the parcel's figure**, which goes stale whenever a payment taken
     * after dispatch fails to reach them.
     */
    private function owedFromNawris(NawrisParcel $parcel): string
    {
        $owed = '0';

        foreach ($parcel->orders as $order) {
            $owed = bcadd($owed, $order->remainingAmount(), Money::SCALE);
        }

        if ($parcel->links()->count() === 1) {
            $owed = bcsub($owed, (string) $parcel->delivery_price_deducted, Money::SCALE);
        }

        return bccomp($owed, '0', Money::SCALE) > 0 ? Money::round($owed) : '0.00';
    }

    /**
     * A second delivery notice moves no money — guard 1 sees to that — but when it carries a
     * different amount from the first, somebody changed the parcel after it was handed over, and
     * that is said out loud rather than absorbed.
     */
    private function flagChangeAfterDelivery(
        NawrisWebhookEvent $event,
        NawrisWebhookPayload $payload,
        ?string $previouslyCollected,
    ): void {
        if ($previouslyCollected === null || $payload->collectedAmount === null) {
            return;
        }

        if (bccomp($previouslyCollected, $payload->collectedAmount, Money::SCALE) !== 0) {
            $this->note($event, "تغيّر المبلغ بعد التسليم: {$previouslyCollected} ← {$payload->collectedAmount} — لم تتحرك أي دفعة، راجِع");
        }
    }

    /**
     * **A different code alone proves nothing** — a legitimate re-send arrives under a new one —
     * so the decision is compound: a different code *and* an amount that does not match blocks
     * the transition entirely. A different code with a matching amount is let through and merely
     * flagged, because freezing an order on unproven suspicion is worse than a late review.
     *
     * "Matching" is ours out of their door figure against what the orders still owe. With their
     * fee unknown the door figure itself stands in — the floor, which still catches anything worse.
     */
    private function conflictBlocks(
        NawrisParcel $parcel,
        NawrisWebhookPayload $payload,
        NawrisParcelTerms $terms,
        string $owed,
    ): bool {
        if (! $this->codeDiffers($parcel, $payload)) {
            return false;
        }

        if ($payload->collectedAmount === null) {
            // Cannot be checked — let it through and flag it.
            return false;
        }

        return $this->isShort($terms->oursOf($payload->collectedAmount) ?? $payload->collectedAmount, $owed);
    }

    /** Two decimal places with a small epsilon, so a rounding difference is not an incident. */
    private function isShort(string $collected, string $expected): bool
    {
        return bccomp(bcadd($collected, '0.01', Money::SCALE), $expected, Money::SCALE) < 0;
    }

    /**
     * Adds a line to what the event says, rather than replacing it — a delivery can be short
     * *and* carry a fee we pay, and both are worth reading. A line already there is not repeated,
     * which is what a shared parcel's second order would otherwise do.
     */
    private function note(NawrisWebhookEvent $event, string $line): void
    {
        $current = (string) $event->error;

        if (str_contains($current, $line)) {
            return;
        }

        $event->forceFill(['error' => $current === '' ? $line : $current.' · '.$line])->save();
    }

    private function codeDiffers(NawrisParcel $parcel, NawrisWebhookPayload $payload): bool
    {
        return $payload->code !== null
            && $parcel->code !== null
            && $payload->code !== $parcel->code;
    }

    /**
     * Their label, verbatim, and their integer — which is what the mapping is written against —
     * with their fee and who pays it as the history reads so far.
     */
    private function recordCarrierState(
        NawrisParcel $parcel,
        NawrisWebhookPayload $payload,
        ?NawrisStatusCode $code,
        NawrisParcelTerms $terms,
    ): void {
        $parcel->forceFill([
            'remote_status_code' => $payload->statusCode,
            'remote_status_text' => $payload->statusText,
            'carrier_fee' => $terms->fee,
            'shipment_on_sender' => $terms->shipmentOnSender,
            // Their latest figure for the door, from whatever event carried one.
            'door_amount' => $payload->collectedAmount ?? $parcel->door_amount,
        ])->save();

        unset($code);
    }

    /**
     * This order's part of what the parcel collects, as last sent to Nawris.
     *
     * Falls back to the parcel's own figure for a link that never recorded one, which can only
     * be a parcel of one order — where the two are the same number.
     */
    private function shareOf(NawrisParcel $parcel, Order $order): string
    {
        $share = $parcel->links()->where('order_id', $order->getKey())->value('amount_to_collect');

        return (string) ($share ?? $parcel->amount_to_collect);
    }

    private function clamp(string $amount, string $ceiling): string
    {
        if (bccomp($ceiling, '0', Money::SCALE) <= 0) {
            return '0.00';
        }

        return bccomp($amount, $ceiling, Money::SCALE) > 0 ? Money::round($ceiling) : Money::round($amount);
    }
}
