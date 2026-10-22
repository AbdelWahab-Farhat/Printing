<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Queries;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Models\InternalTicket;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

/**
 * ورقةُ «مع مَن؟»: الزملاء الذين يُفتح معهم تذكرة، كبريمولا.
 *
 * - **النشطون وحدهم**: تذكرةٌ إلى حسابٍ معطّل رسالةٌ لن يقرأها أحد، ويُنفق التذكيرُ كل ساعةٍ عليها
 *   أربعاً وعشرين مرّة.
 * - **مرتّبون بعدد التذاكر المفتوحة بيني وبينه**، ثم أبجدياً: مَن أكلّمه كل يوم في أول الورقة.
 *
 * العددُ استعلامٌ فرعيٌّ لا علاقة على `User`: سياقُ الهوية لا يعرف التذاكر الداخلية، ولا يُضاف
 * إليه ما يربطه بها.
 */
final class InternalTicketColleaguesQuery
{
    /**
     * @return Collection<int, User>
     */
    public function for(User $reader): Collection
    {
        $me = (int) $reader->getKey();

        $sharedOpen = InternalTicket::query()
            ->selectRaw('count(*)')
            ->where('status', InternalTicketStatus::InProgress)
            ->where(fn (Builder $pair) => $pair
                ->where(fn (Builder $mine) => $mine
                    ->where('internal_tickets.opened_by', $me)
                    ->whereColumn('internal_tickets.assignee_id', 'users.id'))
                ->orWhere(fn (Builder $theirs) => $theirs
                    ->where('internal_tickets.assignee_id', $me)
                    ->whereColumn('internal_tickets.opened_by', 'users.id')));

        return User::query()
            ->with('roles')
            ->where('is_active', true)
            ->whereKeyNot($me)
            ->select('users.*')
            ->selectSub($sharedOpen, 'open_tickets_with_me')
            ->orderByDesc('open_tickets_with_me')
            ->orderBy('name')
            ->get();
    }
}
