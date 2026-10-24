<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\DTOs\InternalMessageData;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Exceptions\InternalTicketIsClosed;
use App\Domain\InternalTicket\Exceptions\NotPartyToInternalTicket;
use App\Domain\InternalTicket\Exceptions\QuotedMessageNotInTicket;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketAttachment;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Support\Media\StoreChatAttachment;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * يضيف رسالةً إلى تذكرةٍ داخلية.
 *
 * **يكتب فيها طرفاها وحدهما، ما دامت مفتوحة.** المديرُ يرى ولا يكتب (السؤال ٥ في §١١)، والمغلقةُ
 * لا يُكتب فيها أحد — لا إعادة فتحٍ بالردّ كالتي يملكها العميل في الدعم.
 *
 * **مَن كتب فقد قرأ ما قبل كتابته**: مؤشّرُه يتقدّم إلى رسالته هو، كما في الدعم.
 *
 * **وعدّادُ التذكير يبدأ من جديد حين يتكلّم مَن كان يُنتظر**: آخرُ كلامٍ حيٍّ كان لزميله، فهذا
 * جوابٌ، والدورُ انقلب. أمّا مَن يكتب ثانيةً وهو ينتظر فلا يعيد العدّاد: هو لا يزال المنتظِر، وكان
 * سيمنح زميله أربعاً وعشرين تذكرةً جديدة بكل «؟» يرسلها.
 *
 * `clientToken` يجعل الإعادة آمنة: الرمزُ نفسه في التذكرة نفسها يُرجع الرسالة الأولى بلا كتابة.
 */
final class PostInternalMessage
{
    public function __construct(private readonly StoreChatAttachment $storeAttachment) {}

    public function __invoke(
        InternalTicket $ticket,
        User $author,
        InternalMessageData $data,
        InternalTicketChange $announceAs = InternalTicketChange::MessagePosted,
    ): InternalTicketMessage {
        if (! $ticket->isParty($author)) {
            throw NotPartyToInternalTicket::make('يقرأ المدير التذاكر الداخلية ولا يكتب فيها إلا إن كان طرفاً');
        }

        if (! $ticket->status->isOpen()) {
            throw InternalTicketIsClosed::make();
        }

        if ($data->clientToken !== null && ($sent = $this->alreadySent($ticket, $data->clientToken)) !== null) {
            return $sent;
        }

        if ($data->replyToMessageId !== null) {
            $this->assertQuotable($ticket, $data->replyToMessageId);
        }

        // الملفاتُ قبل المعاملة وخارجها — انظر StoreChatAttachment.
        $attachments = array_map(
            fn ($file) => ($this->storeAttachment)(
                (string) config('media.internal_ticket_attachments.disk'),
                "internal-ticket-attachments/{$ticket->getKey()}",
                $file,
                $data->durationSeconds,
                $data->waveform,
            ),
            $data->files,
        );

        [$message, $isNew] = $this->write($ticket, $author, $data, $attachments, $announceAs);

        // طلبان بالرمز نفسه في اللحظة نفسها: سبق أحدهما، فيُمحى ملفُّ الآخر.
        if (! $isNew) {
            foreach ($attachments as $stored) {
                Storage::disk((string) $stored['disk'])->delete((string) $stored['path']);
            }
        }

        return $message;
    }

    private function alreadySent(InternalTicket $ticket, string $clientToken): ?InternalTicketMessage
    {
        return InternalTicketMessage::query()
            ->where('internal_ticket_id', $ticket->getKey())
            ->where('client_token', $clientToken)
            ->first();
    }

    private function assertQuotable(InternalTicket $ticket, int $messageId): void
    {
        $belongs = InternalTicketMessage::query()
            ->whereKey($messageId)
            ->where('internal_ticket_id', $ticket->getKey())
            ->exists();

        if (! $belongs) {
            throw QuotedMessageNotInTicket::make();
        }
    }

    /**
     * **صفُّ التذكرة مقفلٌ طوال الكتابة**، فتُكتب رسائلها واحدةً بعد واحدة، وتُقرأ حالتُها كما هي
     * ساعةَ الكتابة: تذكرةٌ أُغلقت بين أول السطر وهذا لا يُكتب فيها.
     *
     * @param  list<array<string, mixed>>  $attachments
     * @return array{0: InternalTicketMessage, 1: bool} الرسالة، وهل كُتبت الآن
     */
    private function write(
        InternalTicket $ticket,
        User $author,
        InternalMessageData $data,
        array $attachments,
        InternalTicketChange $announceAs,
    ): array {
        return DB::transaction(function () use ($ticket, $author, $data, $attachments, $announceAs): array {
            $locked = InternalTicket::query()
                ->with('latestLiveMessage')
                ->whereKey($ticket->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if (! $locked->status->isOpen()) {
                throw InternalTicketIsClosed::make();
            }

            if ($data->clientToken !== null && ($sent = $this->alreadySent($locked, $data->clientToken)) !== null) {
                return [$sent, false];
            }

            $answersTheWait = $locked->awaitsReplyFrom($author);

            $message = new InternalTicketMessage(['body' => $data->body]);
            $message->internal_ticket_id = $locked->getKey();
            // يُختم هنا ولا مكان غيره.
            $message->user_id = (int) $author->getKey();
            $message->reply_to_message_id = $data->replyToMessageId;
            $message->client_token = $data->clientToken;
            $message->save();

            foreach ($attachments as $stored) {
                $attachment = new InternalTicketAttachment;
                $attachment->message_id = $message->getKey();
                $attachment->forceFill($stored);
                $attachment->save();
            }

            $locked->last_message_at = $message->created_at;
            $locked->forceFill([
                (string) $locked->readCursorColumnFor((int) $author->getKey()) => (int) $message->getKey(),
            ]);

            if ($answersTheWait) {
                $locked->reminder_count = 0;
                $locked->last_reminder_at = null;
            }

            $locked->save();

            InternalTicketChanged::dispatch((int) $locked->getKey(), $announceAs, (int) $message->getKey());

            return [$message, true];
        });
    }
}
