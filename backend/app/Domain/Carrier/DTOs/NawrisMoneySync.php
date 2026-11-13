<?php

declare(strict_types=1);

namespace App\Domain\Carrier\DTOs;

use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Order\Enums\DeliveryPayer;

/**
 * How telling Nawris about an order's new money went.
 *
 * **The payment stands either way** — it is real, and refusing to record it because a carrier
 * would not listen would lose the more important of the two facts. What this carries is whether
 * the courier now knows, so the person who took the money can tell them when Nawris did not.
 */
final readonly class NawrisMoneySync
{
    /**
     * @param  string  $nawrisAsks  What Nawris holds for us on the parcel, without their fee.
     * @param  string  $shouldAsk  What it should hold now.
     * @param  string|null  $reason  Their refusal, in their words.
     * @param  DeliveryPayer|null  $payer  Set when the edit was a change of who pays their fee,
     *                                     so the warning speaks of that rather than of money.
     */
    public function __construct(
        public NawrisParcel $parcel,
        public bool $told,
        public string $nawrisAsks,
        public string $shouldAsk,
        public ?string $reason = null,
        public ?DeliveryPayer $payer = null,
    ) {}

    /** The sentence the app shows when Nawris did not take it, or null when it did. */
    public function warning(): ?string
    {
        if ($this->told) {
            return null;
        }

        // A change of who pays the courier, refused: the courier will charge the door as before.
        if ($this->payer !== null) {
            return $this->payer === DeliveryPayer::Us
                ? "لم تقبل نورس تحويل أجرة التوصيل علينا في الطرد {$this->parcel->code} — المندوب سيطلب أجرته من المستلم."
                    .' بلّغ المندوب أو نورس قبل التسليم، أو أعد الإبلاغ من الطلبية.'
                : "لم تقبل نورس إرجاع أجرة التوصيل على المستلم في الطرد {$this->parcel->code} — ستبقى أجرتها علينا وتُخصم مما تحوّله."
                    .' بلّغ نورس، أو أعد الإبلاغ من الطلبية.';
        }

        return "لم تقبل نورس تعديل المبلغ على الطرد {$this->parcel->code} — ما زالت تطلب لنا {$this->nawrisAsks}"
            ." والصحيح {$this->shouldAsk} (دون أجرتها). بلّغ المندوب أو نورس قبل التسليم.";
    }
}
