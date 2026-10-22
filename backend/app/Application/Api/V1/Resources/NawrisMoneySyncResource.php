<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Carrier\DTOs\NawrisMoneySync;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Whether Nawris heard about a change to an order's money.
 *
 * Returned beside every payment, refund and cancelled entry while a parcel is out, and by the
 * retry. `warning` is the sentence to show when it is not null — the courier is still collecting
 * the old amount and somebody has to tell them.
 *
 * @mixin NawrisMoneySync
 */
class NawrisMoneySyncResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'told' => $this->told,
            'parcel_code' => $this->parcel->code,
            // Ours, without their fee: what Nawris holds for us, and what it should.
            'nawris_asks' => $this->nawrisAsks,
            'should_ask' => $this->shouldAsk,
            // Their refusal, in their words — null when they took it.
            'reason' => $this->reason,
            'warning' => $this->warning(),
        ];
    }
}
