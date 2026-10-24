<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Events\DesignConversationChanged;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * صاحبُ الرسالة يسحبها: تبقى مكانها وتقول «تم حذف هذه الرسالة» — كـ`RetractInternalMessage`.
 *
 * **سحبٌ لا حذف.** `deleted_at` لا يُلمس — الرسالةُ وملفّها باقيان للتدقيق، والموردُ يفرّغها عند
 * العرض. وبالشروط نفسها التي للتعديل: له، وخلال المهلة، والتذكرةُ مفتوحة.
 *
 * **وسحبُ ما سُحب لا يُعدّ خطأً**: ضغطتان على «حذف» من شاشتين نتيجتُهما واحدة.
 */
final class RetractDesignTicketMessage
{
    public function __invoke(DesignTicketMessage $message, User $author): DesignTicketMessage
    {
        return DB::transaction(function () use ($message, $author): DesignTicketMessage {
            $locked = DesignTicketMessage::query()
                ->with('ticket')
                ->whereKey($message->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            if ($locked->isRetracted() && $locked->user_id === (int) $author->getKey()) {
                return $locked;
            }

            EditDesignTicketMessage::refuseUnlessChangeableBy($locked, $author);

            $locked->retracted_at = now();
            $locked->save();

            DesignConversationChanged::dispatch(
                $locked->design_ticket_id,
                DesignConversationChange::MessageRetracted,
                (int) $locked->getKey(),
            );

            return $locked;
        });
    }
}
