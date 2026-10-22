<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources\InternalTicket;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalAttachmentKind;
use App\Domain\InternalTicket\Models\InternalTicket;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * تذكرةٌ داخلية كما يراها قارئٌ بعينه: مَن الطرفُ الآخر عنده، وكم لم يقرأ، وهل تنتظر ردّه، وماذا
 * يملك أن يفعل بها.
 *
 * **الأعلامُ من الخادم** (`can_reply` و`can_close` و`can_transfer`)، كبريمولا: التطبيقُ يرسم الأزرار
 * ولا يعيد بناء القواعد.
 *
 * @mixin InternalTicket
 */
class InternalTicketResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $viewer = $request->user();
        $viewer = $viewer instanceof User ? $viewer : null;
        $viewerId = $viewer === null ? null : (int) $viewer->getKey();
        $isParty = $viewer !== null && $this->isParty($viewer);
        $isOpen = $this->status->isOpen();
        $counterpartId = $viewer === null ? null : $this->counterpartIdOf($viewer);

        return [
            'id' => $this->id,
            'code' => $this->code,
            'title' => $this->title,
            'status' => $this->status->value,
            'status_label' => $this->status->label(),
            'priority' => $this->priority->value,
            'priority_label' => $this->priority->label(),

            'category' => $this->whenLoaded('category', fn (): ?array => $this->category === null ? null : [
                'id' => $this->category->id,
                'name' => $this->category->name,
            ]),

            'opener' => $this->whenLoaded('opener', fn (): array => self::person($this->opener)),
            'assignee' => $this->whenLoaded('assignee', fn (): array => self::person($this->assignee)),
            // الطرفُ الآخر عند هذا القارئ — ما يكتبه الصفُّ اسماً. `null` للمدير الذي ليس طرفاً.
            'counterpart' => $this->when(
                $this->relationLoaded('opener') && $this->relationLoaded('assignee'),
                fn (): ?array => match ($counterpartId) {
                    null => null,
                    $this->opened_by => self::person($this->opener),
                    default => self::person($this->assignee),
                },
            ),
            'i_opened_it' => $viewerId !== null && $this->opened_by === $viewerId,
            'is_party' => $isParty,

            'customer' => $this->whenLoaded('customer', fn (): ?array => $this->customer === null ? null : [
                'id' => $this->customer->id,
                'code' => $this->customer->code,
                'name' => $this->customer->name,
                'phone' => $this->customer->phone,
            ]),
            'order' => $this->whenLoaded('order', fn (): ?array => $this->order === null ? null : [
                'id' => $this->order->id,
                'code' => $this->order->code,
            ]),

            'unread_count' => $viewer === null ? 0 : $this->unreadCountFor($viewer),
            // رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
            'counterpart_read_up_to' => $counterpartId === null ? null : $this->readUpToFor($counterpartId),
            // المؤشّران كما هما، لمن لا «طرف آخر» عنده: البثُّ الحيّ لا قارئ له، والمدير ليس طرفاً.
            'read_up_to' => [
                'opener' => $this->opener_read_message_id,
                'assignee' => $this->assignee_read_message_id,
            ],
            'awaiting_my_reply' => $this->when(
                $viewer !== null && $this->relationLoaded('latestLiveMessage'),
                fn (): bool => $this->awaitsReplyFrom($viewer),
            ),
            'last_message' => $this->whenLoaded('latestLiveMessage', fn (): ?array => $this->lastMessage()),

            'messages' => InternalTicketMessageResource::collection($this->whenLoaded('messages')),

            'can_reply' => $viewer !== null && $this->isWritableBy($viewer),
            'can_close' => $isOpen && ($isParty || ($viewer?->isAdmin() ?? false)),
            'can_transfer' => $isOpen && $viewer !== null
                && ($this->opened_by === $viewerId || $viewer->isAdmin()),

            'last_message_at' => $this->last_message_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),
            'closed_by' => $this->whenLoaded('closer', fn (): ?array => $this->closer === null ? null : self::person($this->closer)),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }

    /**
     * محسوبٌ بالجملة في القائمة (`unread_count`)، وواحداً واحداً في التذكرة المفتوحة.
     */
    private function unreadCountFor(User $viewer): int
    {
        // `getAttributes()` لا `getAttribute()`: الوضعُ الصارم يرمي على قراءة عمودٍ لم يُختر.
        $counted = $this->resource->getAttributes()['unread_count'] ?? null;

        return $counted !== null ? (int) $counted : $this->unreadFor($viewer);
    }

    /**
     * @return array<string, mixed>|null
     */
    private function lastMessage(): ?array
    {
        $message = $this->latestLiveMessage;

        if ($message === null) {
            return null;
        }

        $first = $message->attachments->first();

        return [
            'id' => $message->id,
            'author_id' => $message->user_id,
            'author_name' => $message->author?->name,
            'preview' => $message->previewText(),
            // ما يرسمه الصفّ أيقونةً قبل المعاينة.
            'kind' => match (true) {
                $first === null => 'text',
                $first->kind === InternalAttachmentKind::Voice => 'voice',
                default => 'image',
            },
            'duration_seconds' => $first?->duration_seconds,
            'sent_at' => $message->created_at?->toIso8601String(),
        ];
    }

    /**
     * @return array{id: int, name: string}
     */
    private static function person(User $user): array
    {
        return ['id' => (int) $user->id, 'name' => (string) $user->name];
    }
}
