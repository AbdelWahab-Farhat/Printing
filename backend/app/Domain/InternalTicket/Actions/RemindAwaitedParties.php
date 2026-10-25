<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketStatus;
use App\Domain\InternalTicket\Events\InternalTicketReplyOverdue;
use App\Domain\InternalTicket\Models\InternalTicket;
use Illuminate\Support\Facades\DB;

/**
 * يذكّر كلَّ مَن تأخّر ردّه في تذكرةٍ داخلية مفتوحة — يستدعيه المجدوِل مرّةً في اليوم.
 *
 * **مَن يُنتظر** هو {@see InternalTicket::awaitsReplyOnHomeFrom()} نفسه، فلا تختلف البطاقةُ والتذكير:
 * مَن علّمها «قرأتُها» لا يُذكَّر بها حتى يكتب زميلُه من جديد (قرارُ المالك ٢٠٢٦-١٠-٢٥).
 * **ومتى**: مرّت `after_minutes` على آخر كلامٍ حيٍّ من الطرف الآخر، ولم تُذكَّر التذكرةُ في يومها —
 * يومِ طرابلس لا يومِ UTC — وعددُ التذكيرات دون `max`. فنداءٌ ثانٍ في اليوم نفسه لا يكتب شيئاً،
 * أيّاً كان مَن شغّله.
 *
 * **حسابٌ معطّل لا يُذكَّر**: لن يقرأ، والتذكيرُ ينفق عليه ميزانيته كلّها.
 *
 * والمجموعةُ تذاكرُ مفتوحة — عشرات لا آلاف — فتُقرأ مرّةً ويُحكم عليها في PHP، كبطاقة الرئيسية.
 */
final class RemindAwaitedParties
{
    /** @return int كم تذكيراً أُرسل */
    public function __invoke(): int
    {
        $max = (int) config('internal_tickets.reminder.max');

        if ($max <= 0) {
            return 0;
        }

        $dueBefore = now()->subMinutes((int) config('internal_tickets.reminder.after_minutes'));
        $zone = (string) config('app.business_timezone', 'Africa/Tripoli');
        $today = now($zone)->toDateString();

        $sent = 0;

        InternalTicket::query()
            ->with(['latestLiveMessage', 'opener', 'assignee'])
            ->where('status', InternalTicketStatus::InProgress)
            ->where('reminder_count', '<', $max)
            ->each(function (InternalTicket $ticket) use ($dueBefore, $zone, $today, &$sent): void {
                $awaited = $this->awaitedParty($ticket);

                if ($awaited === null || ! $awaited->is_active || $awaited->trashed()) {
                    return;
                }

                $lastWord = $ticket->latestLiveMessage?->created_at ?? $ticket->created_at;

                if ($lastWord === null || $lastWord->greaterThan($dueBefore)) {
                    return;
                }

                if ($ticket->last_reminder_at?->copy()->setTimezone($zone)->toDateString() === $today) {
                    return;
                }

                DB::transaction(function () use ($ticket, $awaited): void {
                    $ticket->reminder_count++;
                    $ticket->last_reminder_at = now();
                    $ticket->save();

                    InternalTicketReplyOverdue::dispatch(
                        (int) $ticket->getKey(),
                        (int) $awaited->getKey(),
                        (int) $ticket->counterpartIdOf($awaited),
                    );
                });

                $sent++;
            });

        return $sent;
    }

    private function awaitedParty(InternalTicket $ticket): ?User
    {
        foreach ([$ticket->assignee, $ticket->opener] as $party) {
            if ($party !== null && $ticket->awaitsReplyOnHomeFrom($party)) {
                return $party;
            }
        }

        return null;
    }
}
