<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Actions;

use App\Domain\DesignTicket\Enums\DesignConversationChange;
use App\Domain\DesignTicket\Events\DesignConversationChanged;
use App\Domain\DesignTicket\Exceptions\DesignConversationIsClosed;
use App\Domain\DesignTicket\Exceptions\DesignTicketMessageCannotChange;
use App\Domain\DesignTicket\Models\DesignTicketMessage;
use App\Domain\Identity\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * صاحبُ الرسالة يغيّر نصّها، خلال عشرين دقيقة، والتذكرةُ مفتوحة — كـ`EditInternalMessage`.
 *
 * - **النصُّ وحده**: المرفقاتُ لا تُبدَّل، والمقتبَسُ لا يتغيّر.
 * - **«معدّلة»** بـ`edited_at`، لا بـ`updated_at` الذي يتحرّك مع أيّ كتابة.
 * - **النصُّ الأول يُحفظ مرّةً واحدة** في `original_body` عند أوّل تعديلٍ حقيقيّ.
 * - **إعادةُ النصّ نفسه ليست تعديلاً**: لا علامة، ولا نسخة، ولا بثّ.
 *
 * والرسالةُ تُقرأ من جديد بقفل صفّ: سُحبت بين ربط المسار وهذه الكتابة، فلا يُعدَّل ما سُحب.
 */
final class EditDesignTicketMessage
{
    public function __invoke(DesignTicketMessage $message, User $editor, string $body): DesignTicketMessage
    {
        return DB::transaction(function () use ($message, $editor, $body): DesignTicketMessage {
            $locked = DesignTicketMessage::query()
                ->with('ticket')
                ->whereKey($message->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            self::refuseUnlessChangeableBy($locked, $editor);

            $body = trim($body);

            if ($locked->body === $body) {
                return $locked;
            }

            $locked->original_body ??= $locked->body;
            $locked->body = $body;
            $locked->edited_at = now();
            $locked->save();

            DesignConversationChanged::dispatch(
                $locked->design_ticket_id,
                DesignConversationChange::MessageEdited,
                (int) $locked->getKey(),
            );

            return $locked;
        });
    }

    /**
     * التذكرةُ المغلقة ٤٢٢ بجملتها، وما سواها ٤٠٣ — {@see DesignConversationIsClosed}.
     */
    public static function refuseUnlessChangeableBy(DesignTicketMessage $message, User $user): void
    {
        if (! $message->ticket->acceptsMessages()) {
            throw DesignConversationIsClosed::make($message->ticket);
        }

        $reason = $message->mutationBlockReason($user);

        if ($reason !== null) {
            throw DesignTicketMessageCannotChange::because($reason);
        }
    }
}
