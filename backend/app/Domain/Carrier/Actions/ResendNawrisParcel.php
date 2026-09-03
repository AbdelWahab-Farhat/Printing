<?php

declare(strict_types=1);

namespace App\Domain\Carrier\Actions;

use App\Domain\Carrier\Exceptions\NawrisRejectedRequest;
use App\Domain\Carrier\Models\NawrisParcel;
use App\Domain\Carrier\Models\NawrisParcelOrder;
use App\Domain\Carrier\Support\NawrisClient;
use Illuminate\Support\Facades\DB;

/**
 * Sends a returned parcel out again.
 *
 * **A second journey is a second parcel row**, not an edit of the first. The old one closes and
 * keeps its history; the new one gets its own code, its own reference and its own COD — which by
 * then may differ, because a payment may have been taken while the goods were back on the shelf.
 * That is exactly what the link table's `(parcel_id, order_id)` key is for.
 *
 * **One thing here is unverifiable until a real call.** The contract describes `order_code` on
 * this endpoint as *a new local order id*, because the system it was compiled from mints a fresh
 * order for a re-send. We do not — «إعادة إرسال» is the same order — so we send the same code.
 * Whether Nawris accepts a repeated value is unknown; if it refuses, the fallback is a suffixed
 * value, and this is the only place that would change.
 */
final class ResendNawrisParcel
{
    public function __construct(
        private readonly NawrisClient $client,
        private readonly BuildNawrisPayload $payload,
    ) {}

    public function __invoke(NawrisParcel $parcel): NawrisParcel
    {
        $parcel->loadMissing('orders');

        $order = $parcel->orders->first();

        if ($order === null || $parcel->code === null) {
            return $parcel;
        }

        $response = $this->client->resendRequest($parcel->code, (string) $order->code);

        $code = $response->code();

        // Same rule dispatch follows: a parcel row without a code can never be edited, cancelled
        // or matched to a webhook, so it must not be written at all.
        if ($code === null) {
            throw NawrisRejectedRequest::make('إعادة إرسال الشحنة', 'لم يصل رقم الطرد الجديد في الرد');
        }

        $amount = $this->payload->amountToCollect($order);
        $reference = $this->payload->reference($order);

        return DB::transaction(function () use ($parcel, $order, $code, $response, $amount, $reference): NawrisParcel {
            // The first journey is over, whatever happens next.
            $parcel->forceFill(['closed_at' => now()])->save();

            $fresh = new NawrisParcel;

            $fresh->forceFill([
                'code' => $code,
                'reference' => $reference,
                // Often the old barcode; theirs to decide, and kept whichever it is.
                'bar_code' => $response->barCode() ?? $parcel->bar_code,
                // Replayed, not re-derived — the parcel is going to the same place.
                'government' => $parcel->government,
                'area' => $parcel->area,
                'amount_to_collect' => $amount,
                'delivery_price_deducted' => (string) $order->delivery_price,
                'shipping_company_id' => $parcel->shipping_company_id,
                'dispatched_at' => now(),
            ])->save();

            $link = new NawrisParcelOrder;
            $link->forceFill([
                'nawris_parcel_id' => $fresh->getKey(),
                'order_id' => $order->getKey(),
                'amount_to_collect' => $amount,
            ])->save();

            return $fresh;
        }, attempts: 3);
    }
}
