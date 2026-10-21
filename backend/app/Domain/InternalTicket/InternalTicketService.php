<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Actions\CloseInternalTicket;
use App\Domain\InternalTicket\Actions\EditInternalMessage;
use App\Domain\InternalTicket\Actions\MarkInternalTicketRead;
use App\Domain\InternalTicket\Actions\OpenInternalTicket;
use App\Domain\InternalTicket\Actions\PostInternalMessage;
use App\Domain\InternalTicket\Actions\RetractInternalMessage;
use App\Domain\InternalTicket\Actions\TransferInternalTicket;
use App\Domain\InternalTicket\DTOs\InternalMessageData;
use App\Domain\InternalTicket\DTOs\InternalTicketData;
use App\Domain\InternalTicket\DTOs\InternalTicketHome;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketCategory;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use App\Domain\InternalTicket\Queries\InternalTicketColleaguesQuery;
use App\Domain\InternalTicket\Queries\InternalTicketFilters;
use App\Domain\InternalTicket\Queries\InternalTicketListQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\UploadedFile;

/**
 * بابُ سياق التذاكر الداخلية.
 *
 * **كلُّ قراءةٍ لتذكرةٍ واحدة تمرّ بالرؤية** ({@see self::findVisible()}): زميلٌ ثالث يطلب رقم تذكرةٍ
 * بين اثنين يُجاب ٤٠٤، لا ٤٠٣ — لا شأن له بأن يعرف أنها موجودة.
 */
class InternalTicketService
{
    /** بطاقةُ الرئيسية: حتى عشرٍ، كبريمولا. */
    public const HOME_PREVIEW_LIMIT = 10;

    public function __construct(
        private readonly OpenInternalTicket $open,
        private readonly PostInternalMessage $post,
        private readonly EditInternalMessage $edit,
        private readonly RetractInternalMessage $retract,
        private readonly CloseInternalTicket $close,
        private readonly TransferInternalTicket $transfer,
        private readonly MarkInternalTicketRead $markRead,
        private readonly InternalTicketListQuery $list,
        private readonly InternalTicketColleaguesQuery $colleagues,
    ) {}

    // ─────────────────────────── القراءة ───────────────────────────

    /**
     * @return LengthAwarePaginator<int, InternalTicket>
     */
    public function paginate(User $reader, InternalTicketFilters $filters, int $perPage): LengthAwarePaginator
    {
        return $this->list->paginate($reader, $filters, $perPage);
    }

    /**
     * التذكرةُ إن كان هذا القارئ يراها، وإلا ٤٠٤.
     *
     * @param  list<string>  $relations
     */
    public function findVisible(User $reader, int $ticketId, array $relations = []): InternalTicket
    {
        $ticket = InternalTicket::query()->with($relations)->findOrFail($ticketId);

        if (! $ticket->isVisibleTo($reader)) {
            throw (new ModelNotFoundException)->setModel(InternalTicket::class, [$ticketId]);
        }

        return $ticket;
    }

    /**
     * رسالةٌ من تذكرةٍ يراها القارئ، وإلا ٤٠٤ — ورسالةٌ من تذكرةٍ أخرى ٤٠٤ كذلك.
     */
    public function findVisibleMessage(User $reader, int $ticketId, int $messageId): InternalTicketMessage
    {
        $ticket = $this->findVisible($reader, $ticketId);

        return InternalTicketMessage::query()
            ->where('internal_ticket_id', $ticket->getKey())
            ->findOrFail($messageId);
    }

    public function home(User $reader): InternalTicketHome
    {
        $open = $this->list->openFor($reader);

        $awaiting = $open
            ->filter(fn (InternalTicket $ticket) => $ticket->awaitsReplyFrom($reader))
            // الأحدثُ بكلام الزميل أولاً — هو ما يُجاب عنه — والرقمُ يكسر التعادل كي لا يتبدّل
            // الترتيب بين طلبين لردّين في الثانية نفسها.
            ->sortByDesc(fn (InternalTicket $ticket) => [
                ($ticket->latestLiveMessage?->created_at ?? $ticket->created_at)?->getTimestamp() ?? 0,
                (int) $ticket->getKey(),
            ])
            ->values();

        return new InternalTicketHome(
            tickets: $awaiting->take(self::HOME_PREVIEW_LIMIT)->all(),
            awaitingMyReply: $awaiting->count(),
            hasMore: $awaiting->count() > self::HOME_PREVIEW_LIMIT,
            totalOpen: $open->count(),
            unreadTickets: $open->filter(fn (InternalTicket $ticket) => (int) $ticket->getAttribute('unread_count') > 0)->count(),
        );
    }

    /**
     * @return Collection<int, User>
     */
    public function colleaguesOf(User $reader): Collection
    {
        return $this->colleagues->for($reader);
    }

    /**
     * الأنواع التي يُفتح بها: النشطة، بترتيبها.
     *
     * @return Collection<int, InternalTicketCategory>
     */
    public function activeCategories(): Collection
    {
        return InternalTicketCategory::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get();
    }

    // ─────────────────────────── الكتابة ───────────────────────────

    /**
     * @param  list<UploadedFile>  $images
     */
    public function open(User $opener, InternalTicketData $data, array $images = []): InternalTicket
    {
        return ($this->open)($opener, $data, $images);
    }

    public function post(InternalTicket $ticket, User $author, InternalMessageData $data): InternalTicketMessage
    {
        return ($this->post)($ticket, $author, $data);
    }

    public function edit(InternalTicketMessage $message, User $editor, string $body): InternalTicketMessage
    {
        return ($this->edit)($message, $editor, $body);
    }

    public function retract(InternalTicketMessage $message, User $author): InternalTicketMessage
    {
        return ($this->retract)($message, $author);
    }

    public function close(InternalTicket $ticket, User $closer): InternalTicket
    {
        return ($this->close)($ticket, $closer);
    }

    public function transfer(InternalTicket $ticket, User $actor, User $newOwner): InternalTicket
    {
        return ($this->transfer)($ticket, $actor, $newOwner);
    }

    /** فتحُ المحادثة هو ما يعلّمها مقروءة — حتى آخر رسالةٍ حُمّلت للقارئ. */
    public function markRead(InternalTicket $ticket, User $reader, ?int $upToMessageId = null): void
    {
        ($this->markRead)($ticket, $reader, $upToMessageId);
    }
}
