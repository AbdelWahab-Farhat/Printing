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
 * صاحبُ الرسالة يغيّر نصّها، خلال عشرين دقيقة، والتذكرةُ مفتوحة — كبريمولا.
 *
 * - **النصُّ وحده**: المرفقاتُ لا تُبدَّل، والمقتبَسُ لا يتغيّر.
 * - **«معدّلة»** بـ`edited_at`، لا بـ`updated_at` الذي يتحرّك مع أيّ كتابة.
 * - **النصُّ الأول يُحفظ مرّةً واحدة** في `original_body` عند أوّل تعديلٍ حقيقيّ، ولا تلمسه
 *   التعديلات بعده — فيبقى ما أُرسل أوّل مرّة.
 * - **إعادةُ النصّ نفسه ليست تعديلاً**: لا علامة، ولا نسخة، ولا بثّ.
 *
 * والرسالةُ تُقرأ من جديد بقفل صفّ: سُحبت بين ربط المسار وهذه الكتابة، فلا يُعدَّل ما سُحب.
 */
final class EditInternalMessage
{
    public function __invoke(InternalTicketMessage $message, User $editor, string $body): InternalTicketMessage
    {
        return DB::transaction(function () use ($message, $editor, $body): InternalTicketMessage {
            $locked = InternalTicketMessage::query()
                ->with('ticket')
                ->whereKey($message->getKey())
                ->lockForUpdate()
                ->firstOrFail();

            $reason = $locked->mutationBlockReason($editor);

            if ($reason !== null) {
                throw InternalMessageCannotChange::because($reason);
            }

            $body = trim($body);

            if ($locked->body === $body) {
                return $locked;
            }

            $locked->original_body ??= $locked->body;
            $locked->body = $body;
            $locked->edited_at = now();
            $locked->save();

            InternalTicketChanged::dispatch(
                (int) $locked->internal_ticket_id,
                InternalTicketChange::MessageEdited,
                (int) $locked->getKey(),
            );

            return $locked;
        });
    }
}
