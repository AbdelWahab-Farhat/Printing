<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Actions;

use App\Domain\Identity\Models\User;
use App\Domain\InternalTicket\Enums\InternalTicketChange;
use App\Domain\InternalTicket\Events\InternalTicketChanged;
use App\Domain\InternalTicket\Exceptions\InternalMessageCannotChange;
use App\Domain\InternalTicket\Models\InternalTicketMessage;
use Illuminate\Support\Facades\DB;

/**
 * صاحبُ الرسالة يسحبها: تبقى مكانها وتقول «تم حذف هذه الرسالة»، كواتساب وكبريمولا.
 *
 * **سحبٌ لا حذف.** `deleted_at` لا يُلمس — الرسالةُ وملفّاتها باقيةٌ للتدقيق، والموردُ يفرّغها عند
 * العرض. وبالشروط نفسها التي للتعديل: له، وخلال المهلة، والتذكرةُ مفتوحة.
 *
 * **وسحبُ ما سُحب لا يُعدّ خطأً**: ضغطتان على «حذف» من شاشتين نتيجتُهما واحدة.
 */
final class RetractInternalMessage
{
    public function __invoke(InternalTicketMessage $message, User $author): InternalTicketMessage
    {
        return DB::transaction(function () use ($message, $author): InternalTicketMessage {
            $locked = InternalTicketMessage::query()
                ->with('ticket')
                ->whereKey($message->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if ($locked->isRetracted() && $locked->user_id === (int) $author->getKey()) {
                return $locked;
            }

            $reason = $locked->mutationBlockReason($author);

            if ($reason !== null) {
                throw InternalMessageCannotChange::because($reason);
            }

            $locked->retracted_at = now();
            $locked->save();

            InternalTicketChanged::dispatch(
                (int) $locked->internal_ticket_id,
                InternalTicketChange::MessageRetracted,
                (int) $locked->getKey(),
            );

            return $locked;
        });
    }
}
