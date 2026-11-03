<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Order\DTOs\OrderTicket;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * صفٌّ في «التذاكر المرتبطة».
 *
 * **`kind` ثم `id` هما عنوانُ فتحها**: لكلّ نوعٍ شاشتُه ومساره — `internal-tickets/{id}`
 * و`design-tickets/{id}` و`support/tickets/{id}` — والمعرّفُ يتكرّر بين الجداول الثلاثة، فلا
 * يكفي وحده. `kind_label` هو الكلمةُ التي تُكتب بجانبها.
 *
 * @mixin OrderTicket
 */
class OrderTicketResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var OrderTicket $ticket */
        $ticket = $this->resource;

        return [
            'kind' => $ticket->kind->value,
            'kind_label' => $ticket->kind->label(),
            'id' => $ticket->id,
            'code' => $ticket->code,
            'title' => $ticket->title,
            'status' => $ticket->status,
            'status_label' => $ticket->statusLabel,
            'is_open' => $ticket->isOpen,
            'activity_at' => $ticket->activityAt?->toIso8601String(),
        ];
    }
}
