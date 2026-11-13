<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Audit\Models\ActivityLog;
use App\Domain\Carrier\DTOs\NawrisParcelTerms;
use App\Domain\Carrier\DTOs\NawrisWebhookPayload;
use App\Domain\Carrier\Enums\NawrisStatusCode;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisWebhookEvent;
use App\Domain\Order\Support\Money;
use DateTimeInterface;

/**
 * Nawris's fee on a parcel and who pays it, read back out of the webhooks it stored.
 *
 * **Their payload carries neither fact outright**, so both are worked out from the history:
 *
 * - **The fee** is fixed when they create the parcel and never moves after, so the parcel's
 *   *earliest* event that carries a door amount gives it: that amount less what we had asked for at
 *   that moment. When that event is itself an edit, the amount from before the edit is the one that
 *   counts.
 * - **Who pays** starts at what we dispatched the parcel as (`payer_at_dispatch`; `1` for every
 *   parcel from before 2026-11-13) and changes through `changes.shipment_on_sender` on one of their
 *   edits — or through ours: our last accepted change (`payer_sent`, `payer_sent_at`) counts from
 *   the moment we made it. The last of these wins.
 * - **An edit that moves the parcel to another city** makes the fee unknown from then on.
 *
 * **Read from the stored rows in id order, never from the event being processed.** Webhooks are
 * queued, and a job retried late would otherwise decide the fee from whatever happened to run first.
 *
 * **A delivery is never a source for the fee.** If it were, a parcel whose first word from them is
 * «تم التسليم» would yield a fee of exactly the door amount less our ask — and the payment would come
 * out as our ask whatever they collected, which is the bug this replaces. No fee is learnt from the
 * delivery or anything after it; the payment then waits for a person.
 */
final class ReadNawrisParcelTerms
{
    /**
     * @param  NawrisWebhookEvent|null  $upTo  Read the history only as far as this event — what was
     *                                         known when it arrived. Null reads all of it.
     */
    public function __invoke(NawrisParcel $parcel, ?NawrisWebhookEvent $upTo = null): NawrisParcelTerms
    {
        $events = $parcel->events()
            ->when($upTo !== null, fn ($query) => $query->where('id', '<=', $upTo?->getKey()))
            ->orderBy('id')
            ->get(['id', 'payload', 'received_at']);

        // Where the parcel started: what we dispatched it as. Parcels from before 2026-11-13 carry
        // nothing here, and every one of them was dispatched as the customer paying.
        $shipmentOnSender = $parcel->payer_at_dispatch ?? NawrisParcelTerms::CUSTOMER_PAYS;
        $fee = null;
        $feeDecided = false;
        $cityChanged = false;
        $feeBeforeMove = null;

        // Our own last accepted change of who pays, slotted into their history at the moment we
        // made it — their webhook for our edit may not carry `changes.shipment_on_sender`, and
        // without this the next event would read the parcel back to where it was.
        $sentAt = $parcel->payer_sent_at;
        $sentApplied = $parcel->payer_sent === null || $sentAt === null;

        foreach ($events as $event) {
            if (! $sentApplied && ($event->received_at === null || $event->received_at >= $sentAt)) {
                $shipmentOnSender = (int) $parcel->payer_sent;
                $sentApplied = true;
            }

            $payload = NawrisWebhookPayload::fromArray((array) $event->payload);

            if (! $feeDecided && $payload->status() === NawrisStatusCode::Delivered) {
                $feeDecided = true;
            }

            $doorBefore = $payload->collectedAmountBefore ?? $payload->collectedAmount;

            if (! $feeDecided && $doorBefore !== null) {
                $feeDecided = true;

                // The fee shows only while the customer pays it: under `2` the door amount is ours.
                if (($payload->shipmentOnSenderBefore ?? $shipmentOnSender) === NawrisParcelTerms::CUSTOMER_PAYS) {
                    $fee = $this->feeFrom($doorBefore, $this->askedAt($parcel, $event->received_at));
                }
            }

            // **A move to another city ends what the fee can be known to be.** Their fee is the
            // city's; the one read before the move may not be the one charged after it, and the
            // door amount from here on mixes the two. A person enters that payment.
            if ($payload->cityChanged) {
                $cityChanged = true;
                $feeDecided = true;
                // Kept only to be quoted: the person entering the payment by hand starts from it.
                $feeBeforeMove ??= $fee;
                $fee = null;
            }

            $shipmentOnSender = $payload->shipmentOnSenderAfter ?? $shipmentOnSender;
        }

        // Sent after every event read so far — unless we are reading as of an event that came
        // before it, when it had not happened yet.
        if (! $sentApplied && ($upTo === null || $upTo->received_at === null || $upTo->received_at >= $sentAt)) {
            $shipmentOnSender = (int) $parcel->payer_sent;
        }

        return new NawrisParcelTerms($fee, $shipmentOnSender, $cityChanged, $feeBeforeMove);
    }

    /**
     * Null rather than a negative fee. Their door amount below what we asked means the figures do
     * not fit the rule at all, and a guess here would be a guess about money.
     */
    private function feeFrom(string $door, string $asked): ?string
    {
        $fee = bcsub($door, $asked, Money::SCALE);

        return bccomp($fee, '0', Money::SCALE) >= 0 ? Money::round($fee) : null;
    }

    /**
     * What we were asking them to collect when the event arrived.
     *
     * Usually today's figure. But a payment taken after dispatch lowers it, and their first event
     * may have come before that: the first change to it *after* the event, read from the audit
     * trail, says what it was then.
     */
    private function askedAt(NawrisParcel $parcel, ?DateTimeInterface $at): string
    {
        if ($at === null) {
            return (string) $parcel->amount_to_collect;
        }

        $later = ActivityLog::query()
            ->where('subject_type', $parcel->getMorphClass())
            ->where('subject_id', $parcel->getKey())
            ->where('created_at', '>', $at)
            ->whereRaw("(attribute_changes->'old'->>'amount_to_collect') is not null")
            ->orderBy('id')
            ->first();

        $old = $later?->attribute_changes?->get('old')['amount_to_collect'] ?? null;

        return $old !== null ? Money::normalize($old) : (string) $parcel->amount_to_collect;
    }
}
