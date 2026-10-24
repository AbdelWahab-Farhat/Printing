<?php

declare(strict_types=1);

namespace App\Domain\DesignTicket\Events;

use App\Domain\DesignTicket\Enums\DesignConversationChange;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * تغيّرت محادثةُ تذكرة تصميم.
 *
 * كنظيره في التذاكر الداخلية: حدثٌ واحد لكل تغيير، والسياقُ لا يعرف مَن يستمع — البثُّ الحيّ
 * والجرسُ يقرّران ما يعنيهما. **وبعد الالتزام**: رسالةٌ تُبثّ ثم تتراجع معاملتها رآها الطرفُ الآخر
 * ولم تُكتب قط.
 *
 * يحمل أرقاماً لا نماذج: المستمع يقرأ التذكرة كما استقرّت.
 */
final readonly class DesignConversationChanged implements ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(
        public int $ticketId,
        public DesignConversationChange $change,
        /** الرسالة التي قيلت أو عُدّلت أو سُحبت، حين يكون التغيير عن رسالة. */
        public ?int $messageId = null,
    ) {}
}
