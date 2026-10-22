<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\InternalTicket;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * رسالةٌ في تذكرةٍ داخلية، كما يراها قارئٌ بعينه.
 *
 * - **المسحوبةُ تبقى مكانها فارغة**: نصُّها «تم حذف هذه الرسالة» — نصٌّ لا `null`، كي ترسمه نسخةٌ
 *   من التطبيق لا تعرف `is_deleted` فقاعةً عادية — ومرفقاتُها `[]`، والاقتباسُ منها يقول «محذوفة».
 * - **أعلامُ القدرة من الخادم** (`can_edit` / `can_delete` و`mutable_until`)، فلا يعيد التطبيقُ بناء
 *   القاعدة. وفي البثّ لا قارئ: الأعلامُ `false` و`mutable_until` صحيح، فيحسب التطبيق الباقي — كبريمولا.
 *
 * @mixin InternalTicketMessage
 */
class InternalTicketMessageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $viewer = $viewer instanceof User ? $viewer : null;
        $retracted = $this->isRetracted();

        // يقرأ `ticket`، وهي محمّلةٌ مع كل رسالةٍ من المحادثة (`chaperone`) أو يحمّلها المتحكّم.
        $blockReason = $viewer === null ? null : $this->mutationBlockReason($viewer);
        $mutable = $viewer !== null && $blockReason === null;

        return [
            'id' => $this->id,
            'ticket_id' => $this->internal_ticket_id,
            'author' => $this->whenLoaded('author', fn (): ?array => $this->author === null ? null : [
                'id' => $this->author->id,
                'name' => $this->author->name,
            ]),
            'is_mine' => $viewer !== null && $this->user_id === (int) $viewer->getKey(),
            'body' => $retracted ? InternalTicketMessage::RETRACTED_PLACEHOLDER : $this->body,
            'is_deleted' => $retracted,
            'deleted_at' => $this->retracted_at?->toIso8601String(),
            'is_edited' => ! $retracted && $this->isEdited(),
            'edited_at' => $retracted ? null : $this->edited_at?->toIso8601String(),
            'reply_to' => $this->whenLoaded('replyTo', fn (): ?array => $this->quoted()),
            'attachments' => $retracted
                ? []
                : InternalTicketAttachmentResource::collection($this->whenLoaded('attachments')),
            'client_token' => $this->client_token,
            'sent_at' => $this->created_at?->toIso8601String(),
            'can_edit' => $mutable,
            'can_delete' => $mutable,
            // لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
            'mutation_block_reason' => $blockReason,
            'mutable_until' => $this->mutableUntil()?->toIso8601String(),
        ];
    }

    /**
     * الاقتباسُ في سطر: مَن قال، وماذا — أو أنها حُذفت. يقرأ `replyTo.author` و`replyTo.attachments`.
     *
     * @return array<string, mixed>|null
     */
    private function quoted(): ?array
    {
        $quoted = $this->replyTo;

        if ($quoted === null) {
            return null;
        }

        return [
            'id' => $quoted->id,
            'author_name' => $quoted->author?->name,
            'preview' => $quoted->previewText(),
            'is_deleted' => $quoted->isRetracted(),
        ];
    }
}
