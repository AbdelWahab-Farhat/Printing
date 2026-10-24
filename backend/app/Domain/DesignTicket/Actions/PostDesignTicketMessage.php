<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\DTOs\DesignTicketMessageData;
use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Events\DesignConversationChanged;
use App\Domain\DesignTicket\Exceptions\DesignConversationIsClosed;
use App\Domain\DesignTicket\Exceptions\QuotedMessageNotInDesignTicket;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\DesignTicket\Models\DesignTicketMessageAttachment;
use App\Domain\Identity\Models\User;
use App\Support\Media\StoreChatAttachment;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * يضيف رسالةً إلى محادثة تذكرة تصميم — على شكل `PostInternalMessage`.
 *
 * **يكتب فيها مَن يراها، ما دامت مفتوحة**، كما كان قبل أن تصير محادثة: الطالبُ والمصمّمُ ومَن يرى
 * التذاكر كلّها. والرؤيةُ يحرسها المتحكّم ٤٠٤ قبل أن يصل الطلب إلى هنا.
 *
 * **مَن كتب فقد قرأ ما قبل كتابته**: مؤشّرُه يتقدّم إلى رسالته هو، إن كان طرفاً.
 *
 * `clientToken` يجعل الإعادة آمنة: الرمزُ نفسه في التذكرة نفسها يُرجع الرسالة الأولى بلا كتابة.
 */
final class PostDesignTicketMessage
{
    public function __construct(private readonly StoreChatAttachment $storeAttachment) {}

    public function __invoke(DesignTicket $ticket, User $author, DesignTicketMessageData $data): DesignTicketMessage
    {
        if (! $ticket->acceptsMessages()) {
            throw DesignConversationIsClosed::make($ticket);
        }

        if ($data->clientToken !== null && ($sent = $this->alreadySent($ticket, $data->clientToken)) !== null) {
            return $sent;
        }

        if ($data->replyToMessageId !== null) {
            $this->assertQuotable($ticket, $data->replyToMessageId);
        }

        // الملفُّ قبل المعاملة وخارجها — انظر StoreChatAttachment.
        $stored = $data->file === null ? null : ($this->storeAttachment)(
            (string) config('media.design_ticket_message_attachments.disk'),
            "design-ticket-messages/{$ticket->getKey()}",
            $data->file,
            $data->durationSeconds,
            $data->waveform,
        );

        [$message, $isNew] = $this->write($ticket, $author, $data, $stored);

        // طلبان بالرمز نفسه في اللحظة نفسها: سبق أحدهما، فيُمحى ملفُّ الآخر.
        if (! $isNew && $stored !== null) {
            Storage::disk((string) $stored['disk'])->delete((string) $stored['path']);
        }

        return $message;
    }

    private function alreadySent(DesignTicket $ticket, string $clientToken): ?DesignTicketMessage
    {
        return DesignTicketMessage::query()
            ->where('design_ticket_id', $ticket->getKey())
            ->where('client_token', $clientToken)
            ->first();
    }

    private function assertQuotable(DesignTicket $ticket, int $messageId): void
    {
        $belongs = DesignTicketMessage::query()
            ->whereKey($messageId)
            ->where('design_ticket_id', $ticket->getKey())
            ->exists();

        if (! $belongs) {
            throw QuotedMessageNotInDesignTicket::make();
        }
    }

    /**
     * **صفُّ التذكرة مقفلٌ طوال الكتابة**، فتُكتب رسائلها واحدةً بعد واحدة، وتُقرأ حالتُها كما هي
     * ساعةَ الكتابة: تذكرةٌ اعتُمدت بين أول السطر وهذا لا يُكتب فيها.
     *
     * @param  array<string, mixed>|null  $stored
     * @return array{0: DesignTicketMessage, 1: bool} الرسالة، وهل كُتبت الآن
     */
    private function write(DesignTicket $ticket, User $author, DesignTicketMessageData $data, ?array $stored): array
    {
        return DB::transaction(function () use ($ticket, $author, $data, $stored): array {
            $locked = DesignTicket::query()->whereKey($ticket->getKey())->lockForUpdate()->firstOrFail();

            if (! $locked->acceptsMessages()) {
                throw DesignConversationIsClosed::make($locked);
            }

            if ($data->clientToken !== null && ($sent = $this->alreadySent($locked, $data->clientToken)) !== null) {
                return [$sent, false];
            }

            $message = new DesignTicketMessage(['body' => $data->body]);
            $message->design_ticket_id = (int) $locked->getKey();
            // يُختم هنا ولا مكان غيره.
            $message->user_id = (int) $author->getKey();
            $message->reply_to_message_id = $data->replyToMessageId;
            $message->client_token = $data->clientToken;
            $message->save();

            if ($stored !== null) {
                $attachment = new DesignTicketMessageAttachment;
                $attachment->message_id = $message->getKey();
                $attachment->forceFill($stored);
                $attachment->save();
            }

            $cursor = $locked->readCursorColumnFor((int) $author->getKey());

            if ($cursor !== null) {
                $locked->forceFill([$cursor => (int) $message->getKey()])->save();
            }

            DesignConversationChanged::dispatch(
                (int) $locked->getKey(),
                DesignConversationChange::MessagePosted,
                (int) $message->getKey(),
            );

            return [$message, true];
        });
    }
}
