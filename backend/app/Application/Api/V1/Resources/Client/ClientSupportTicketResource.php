<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\Client;

use App\Domain\Support\Models\SupportTicket;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A support thread, as its own customer sees it.
 *
 * **The assignee does not travel, and neither does *when* anybody read.** Whose desk a ticket
 * sits on is how the shop organises itself, and «قرأها الموظف في ١٠:٤٢ ولم يرد» is a stick to
 * beat somebody with rather than information the customer can act on.
 *
 * **ما يسافر منذ ٢٠٢٦-٠٩-٢٥ هو الحدّ وحده** (`support_read_up_to`): طلب صاحب المحل علامة
 * القراءة ✓✓ كما في تطبيقات المحادثة. هي تقول «وصلت ورآها المحل»، لا متى ولا مَن.
 *
 * @mixin SupportTicket
 */
class ClientSupportTicketResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'subject' => $this->subject,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'is_open' => $this->status->isOpen(),

            // The order this is about, named rather than as a bare id so the list can draw
            // «بخصوص الطلبية #١٢٢٠» without a second request.
            'order' => $this->whenLoaded('order', fn (): ?array => $this->order === null ? null : [
                'id' => $this->order->id,
                'code' => $this->order->code,
            ]),

            // Derived from the read cursor every time it is asked, never stored — see
            // `SupportTicket::unreadFor()` for why a counter would drift.
            'unread_count' => $this->unreadFor(staff: false),

            // **علامةُ القراءة: الحدّ وحده، لا الساعة.** رقمُ آخر رسالةٍ رآها المحل؛ رسالتي
            // مقروءةٌ (✓✓) إن كان رقمها لا يتجاوزه. متى قرأها ومن قرأها لا يغادران الخادم.
            'support_read_up_to' => $this->readUpTo(staff: true),

            'messages' => ClientTicketMessageResource::collection($this->whenLoaded('messages')),

            // What the list draws under the subject: how long the thread is, and the last thing
            // anybody said in it. Both are absent from the thread endpoint's payload, where the
            // messages themselves are already there to be counted and read.
            'messages_count' => $this->whenCounted('messages'),
            'preview' => $this->whenLoaded(
                'latestMessage',
                // نصُّها، أو ما يُقال عن ملفها حين لا نص — «صورة»، أو اسم الـPDF.
                fn (): ?string => $this->latestMessage?->previewText(),
            ),

            'last_message_at' => $this->last_message_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
