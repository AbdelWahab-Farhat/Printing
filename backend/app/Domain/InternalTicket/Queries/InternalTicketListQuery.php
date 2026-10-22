<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Queries;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Models\InternalTicket;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

/**
 * قوائمُ التذاكر الداخلية: الصفحةُ في تبويب «الموظفين»، وبطاقةُ الرئيسية.
 *
 * **التضييقُ بالرؤية في SQL**، كتذاكر التصميم: صفحةٌ تجلب خمسة عشر صفاً ثم تُسقط أربعة تصير صفحةً
 * قصيرة يظنّ قارئها أن القائمة انتهت. والقاعدةُ هي {@see InternalTicket::isVisibleTo()} نفسها،
 * مكتوبةً مرّتين عن قصد لأن إحداهما يجب أن تكون استعلاماً.
 *
 * **وعددُ غير المقروء يُحسب بالجملة**، بقاعدة {@see InternalTicket::unreadFor()}: رسائلُ الطرف
 * الآخر، لم تُسحب، بعد مؤشّر القارئ — ومؤشّرُ القارئ عمودٌ يختلف بحسب أيّ الطرفين هو.
 */
final class InternalTicketListQuery
{
    private const RELATIONS = [
        'opener',
        'assignee',
        'category',
        'customer',
        'order',
        'latestLiveMessage.author',
        'latestLiveMessage.attachments',
    ];

    /**
     * @return LengthAwarePaginator<int, InternalTicket>
     */
    public function paginate(User $reader, InternalTicketFilters $filters, int $perPage): LengthAwarePaginator
    {
        $direction = $filters->sort === InternalTicketFilters::SORT_OLDEST_ACTIVITY ? 'asc' : 'desc';

        return $this->forReader($reader)
            ->tap(fn (Builder $query) => $this->applyFilters($query, $reader, $filters))
            ->orderBy('last_message_at', $direction)
            ->orderBy('id', $direction)
            ->paginate($perPage);
    }

    /**
     * كلُّ تذكرةٍ مفتوحة هذا الموظفُ طرفٌ فيها — ما تُبنى منه بطاقةُ الرئيسية.
     *
     * **مجموعةٌ لا صفحة**، كبريمولا: «مَن ينتظر مَن» يقارن كاتبَ آخر رسالةٍ حيّة بالقارئ، ولا
     * يقولها `WHERE` بلا استعلامٍ فرعيٍّ لكل صف. والمجموعةُ تذاكرُ موظفٍ واحد المفتوحة — عشرات لا آلاف.
     *
     * @return Collection<int, InternalTicket>
     */
    public function openFor(User $reader): Collection
    {
        return $this->forReader($reader)
            ->tap(fn (Builder $query) => $this->whereParty($query, (int) $reader->getKey()))
            ->where('status', InternalTicketStatus::InProgress)
            ->get();
    }

    /**
     * @return Builder<InternalTicket>
     */
    private function forReader(User $reader): Builder
    {
        return InternalTicket::query()
            ->with(self::RELATIONS)
            ->withCount(['messages as unread_count' => fn (Builder $messages) => $this->unreadBy($messages, $reader)]);
    }

    /**
     * @param  Builder<InternalTicket>  $query
     */
    private function applyFilters(Builder $query, User $reader, InternalTicketFilters $filters): void
    {
        // التضييقُ أولاً، لأنه ليس فلتراً.
        if (! $filters->allTickets) {
            $this->whereParty($query, (int) $reader->getKey());
        }

        if ($filters->status !== null) {
            $query->where('status', $filters->status);
        }

        if ($filters->categoryId !== null) {
            $query->where('category_id', $filters->categoryId);
        }

        if ($filters->userId !== null) {
            $this->whereParty($query, $filters->userId);
        }

        if ($filters->orderId !== null) {
            $query->where('order_id', $filters->orderId);
        }

        if ($filters->customerId !== null) {
            $query->where('customer_id', $filters->customerId);
        }

        if ($filters->unreadOnly) {
            $query->whereHas('messages', fn (Builder $messages) => $this->unreadBy($messages, $reader));
        }

        if ($filters->search !== null) {
            $term = $filters->search;

            $query->where(function (Builder $matches) use ($term): void {
                // `ILIKE`: Postgres يفرّق بين الحروف، ومن يكتب «tr-12» لا يعرف كيف كُتب الكود.
                $matches->where('internal_tickets.code', 'ILIKE', $term.'%')
                    ->orWhere('internal_tickets.title', 'ILIKE', '%'.$term.'%')
                    ->orWhereHas('opener', fn (Builder $user) => $user->where('name', 'ILIKE', '%'.$term.'%'))
                    ->orWhereHas('assignee', fn (Builder $user) => $user->where('name', 'ILIKE', '%'.$term.'%'));
            });
        }
    }

    /**
     * @param  Builder<InternalTicket>  $query
     */
    private function whereParty(Builder $query, int $userId): void
    {
        $query->where(fn (Builder $party) => $party
            ->where('internal_tickets.opened_by', $userId)
            ->orWhere('internal_tickets.assignee_id', $userId));
    }

    /**
     * رسائلُ لم يرها هذا القارئ — والقارئُ الذي ليس طرفاً لا غير مقروءٍ عنده.
     *
     * @param  Builder<InternalTicketMessage>  $messages
     */
    private function unreadBy(Builder $messages, User $reader): void
    {
        $id = (int) $reader->getKey();

        $messages
            ->where('internal_ticket_messages.user_id', '!=', $id)
            ->whereNull('internal_ticket_messages.retracted_at')
            ->whereRaw('? in (internal_tickets.opened_by, internal_tickets.assignee_id)', [$id])
            ->whereRaw(
                'internal_ticket_messages.id > COALESCE(CASE'
                .' WHEN internal_tickets.opened_by = ? THEN internal_tickets.opener_read_message_id'
                .' WHEN internal_tickets.assignee_id = ? THEN internal_tickets.assignee_read_message_id'
                .' END, 0)',
                [$id, $id],
            );
    }
}
