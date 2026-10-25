<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Events\InternalTicketClosedForSilence;
use App\Domain\InternalTicket\Models\InternalTicket;
use Illuminate\Support\Facades\DB;

/**
 * يُغلق كلَّ تذكرةٍ مفتوحة لم يكتب فيها أحدُ الطرفين منذ `close_after_silence.days` — ثلاثة أيام،
 * طلبُ المالك ٢٠٢٦-١٠-٢٥. يستدعيه المجدوِل كل ساعة.
 *
 * - **العدُّ من آخر كلامٍ حيّ**، كـ{@see InternalTicket::awaitsReplyFrom()}: رسالةٌ سُحبت ليست
 *   كلاماً، وتذكرةٌ لا كلام فيها تعدّ من فتحها. وعلامةُ «قرأتُها» لا تعيد العدّ.
 * - **بلا اسمٍ عليها** (`closed_by` فارغ) — ما يقرؤه {@see InternalTicket::closedForSilence()}.
 *   وسجلُّ التدقيق يكتبه بلا فاعل، فيقرؤه المدير «النظام».
 * - **ويصل الخبرُ إلى الطرفين** (قرارُ المالك): {@see InternalTicketClosedForSilence}. والبثُّ الحيّ
 *   يسمع «أُغلقت» كأيّ إغلاق.
 * - **القديمةُ تُغلق أوّلَ مرة** (قرارُ المالك): تذكرةٌ صامتةٌ منذ أسابيع قبل النشر تُغلق في أوّل ساعة.
 *
 * **ردٌّ يصل في اللحظة نفسها يغلب**: كلُّ تذكرةٍ تُقفل وتُسأل ثانيةً داخل معاملتها — كما يقفلها
 * PostInternalMessage — فلا تُغلق على رسالةٍ كُتبت بين القراءة والإغلاق. ونداءٌ ثانٍ لا يجد ما يغلقه.
 */
final class CloseSilentInternalTickets
{
    /** @return int كم تذكرةً أُغلقت */
    public function __invoke(): int
    {
        $days = (int) config('internal_tickets.close_after_silence.days');

        if ($days <= 0) {
            return 0;
        }

        $silentSince = now()->subDays($days);
        $closed = 0;

        // `lazyById` لا `each`: الإغلاقُ يُخرج الصفَّ من الاستعلام، والتصفّحُ بالإزاحة يقفز فوق ما بعده.
        InternalTicket::query()
            ->with('latestLiveMessage')
            ->where('status', InternalTicketStatus::InProgress)
            ->lazyById()
            ->each(function (InternalTicket $ticket) use ($silentSince, &$closed): void {
                if (! $this->isSilentSince($ticket, $silentSince)) {
                    return;
                }

                $closedNow = DB::transaction(function () use ($ticket, $silentSince): bool {
                    $locked = InternalTicket::query()->with('latestLiveMessage')->lockForUpdate()->find($ticket->getKey());

                    if ($locked === null || ! $locked->status->isOpen() || ! $this->isSilentSince($locked, $silentSince)) {
                        return false;
                    }

                    $locked->status = InternalTicketStatus::Closed;
                    $locked->closed_at = now();
                    $locked->closed_by = null;
                    $locked->save();

                    InternalTicketChanged::dispatch((int) $locked->getKey(), InternalTicketChange::Closed);
                    InternalTicketClosedForSilence::dispatch((int) $locked->getKey());

                    return true;
                });

                if ($closedNow) {
                    $closed++;
                }
            });

        return $closed;
    }

    private function isSilentSince(InternalTicket $ticket, \DateTimeInterface $silentSince): bool
    {
        $lastWord = $ticket->latestLiveMessage?->created_at ?? $ticket->created_at;

        return $lastWord !== null && $lastWord->lessThanOrEqualTo($silentSince);
    }
}
