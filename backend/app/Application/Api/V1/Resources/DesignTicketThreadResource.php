<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Identity\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * محادثة تذكرة تصميم كما يرسمها الشريطُ والفقاعاتُ والصندوق — لا التذكرةُ كلّها.
 *
 * **ما يحتاجه الشريط** في `ticket`: الكودُ والحالة، والعنوانُ واسمُ العميل تحته، والطرفان ليُكتب
 * في الوسط اسمُ «الطرف الآخر». **والرسائلُ أقدمُها أولاً**، بشكل رسائل التذكرة الداخلية.
 *
 * - `can_reply` و`closed_note`: هل يُرسم الصندوق، وإن لم يُرسم فما الجملةُ مكانه.
 * - `read_up_to`: المؤشّران كما هما، لمن لا «طرف آخر» عنده — البثُّ الحيّ لا قارئ له.
 * - `counterpart_read_up_to`: رسالتي ✓✓ إن كان رقمُها لا يتجاوز هذا. `null` لمن ليس طرفاً.
 *
 * **بلا قارئ في البثّ**: `is_party` و`can_reply` تُحسب للطلب الفارغ `false`، والتطبيقُ يُبقي ما
 * عنده منهما — انظر `DesignTicketThreadChanged`.
 *
 * @mixin DesignTicket
 */
class DesignTicketThreadResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $viewer = $viewer instanceof User ? $viewer : null;
        $counterpartId = $this->counterpartIdOf($viewer);

        return [
            'ticket' => [
                'id' => $this->id,
                'code' => $this->code,
                'title' => $this->title,
                'status' => $this->status->value,
                'status_label' => $this->status->label(),
                'is_open' => $this->status->isOpen(),
                'customer_name' => $this->customer_name,
                'requester' => $this->whenLoaded('requester', fn (): ?array => self::person($this->requester)),
                // مَن يعمل عليها فعلاً — مَن قبلها، أو مَن أُسندت إليه قبل القبول.
                'designer' => $this->when(
                    $this->relationLoaded('acceptedBy') && $this->relationLoaded('designer'),
                    fn (): ?array => self::person($this->acceptedBy ?? $this->designer),
                ),
            ],
            'messages' => DesignTicketMessageResource::collection($this->whenLoaded('messages')),
            'is_party' => $this->isParty($viewer),
            'can_reply' => $viewer !== null && $this->acceptsMessages(),
            'closed_note' => $this->conversationClosedNote(),
            'read_up_to' => [
                'requester' => $this->requester_read_message_id,
                'designer' => $this->designer_read_message_id,
            ],
            'counterpart_read_up_to' => $this->readUpToFor($counterpartId),
        ];
    }

    /**
     * @return array{id: int, name: string}|null
     */
    private static function person(?User $user): ?array
    {
        return $user === null ? null : ['id' => (int) $user->id, 'name' => (string) $user->name];
    }
}
