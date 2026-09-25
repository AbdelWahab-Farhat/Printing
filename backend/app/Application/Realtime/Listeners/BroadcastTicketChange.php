<?php

declare(strict_types=1);

namespace App\Application\Realtime\Listeners;

use App\Application\Realtime\Events\CustomerTicketChanged;
use App\Application\Realtime\Events\DeskTicketChanged;
use App\Domain\Support\Enums\TicketChange;
use App\Domain\Support\Events\TicketChanged;
use App\Domain\Support\SupportService;

use function Illuminate\Support\defer;

/**
 * ينقل تغيّرَ التذكرة إلى من يعنيه، ساعةَ يقع.
 *
 * ### بعد إرسال الرد، لا قبله ولا عبر الطوابير
 *
 * - **`defer`**: الرسالةُ تُكتب ويعود جوابها لمن كتبها، ثم يُبثّ الحدث. خادمُ بثٍّ بطيء لا يُبطئ
 *   زرَّ «إرسال» في يد أحد.
 * - **لا `ShouldQueue`**: الطابور يعمل على قاعدة البيانات، وعاملُه ينام ثلاث ثوانٍ بين كل نظرتين —
 *   والعاملُ نفسه لم يُتحقَّق من وجوده على أي خادم بعد. ردٌّ يصل بعد دقيقة ليس حيّاً.
 * - **لا يُسقط أحداً**: الحدثان `ShouldRescue`، فإن كان Reverb نائماً سُجّل الفشل في السجل ومضى
 *   كلُّ شيء. البثُّ زينةٌ فوق محادثةٍ محفوظة، والشاشةُ تُحدَّث بالسحب كما كانت.
 *
 * ### لمن
 *
 * المكتبُ يسمع كل تغيير. العميلُ يسمع ما يراه في تطبيقه فقط — {@see TicketChange::reachesCustomer()}.
 */
final class BroadcastTicketChange
{
    public function __construct(private readonly SupportService $support) {}

    public function handle(TicketChanged $event): void
    {
        defer(fn () => $this->broadcast($event));
    }

    private function broadcast(TicketChanged $event): void
    {
        // تُقرأ ساعةَ البثّ لا ساعةَ الحدث: ما يُرسَل هو ما استقرّ بعد الالتزام، لا ما كان في
        // منتصف المعاملة.
        $ticket = $this->support->findForBroadcast($event->ticketId);

        // حُذفت بين الالتزام وهذا السطر — لا شيء يقال عن تذكرةٍ لم تعد موجودة.
        if ($ticket === null) {
            return;
        }

        $message = $event->messageId === null ? null : $this->support->findMessage($event->messageId);

        event(new DeskTicketChanged($ticket, $message));

        if ($event->change->reachesCustomer()) {
            event(new CustomerTicketChanged($ticket, $message));
        }
    }
}
