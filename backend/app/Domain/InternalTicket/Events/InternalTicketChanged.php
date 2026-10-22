<?php

declare(strict_types=1);

namespace App\Domain\InternalTicket\Events;

use App\Domain\InternalTicket\Enums\InternalTicketChange;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * تغيّرت تذكرةٌ داخلية.
 *
 * كنظيره في الدعم: حدثٌ واحد لكل تغيير، والسياقُ لا يعرف مَن يستمع — البثُّ الحيّ والجرسُ
 * والتذكير يقرّرون ما يعنيهم. **وبعد الالتزام**: رسالةٌ تُبثّ ثم تتراجع معاملتها رآها الطرفُ الآخر
 * ولم تُكتب قط.
 *
 * يحمل أرقاماً لا نماذج: المستمع يقرأ التذكرة كما استقرّت.
 */
final readonly class InternalTicketChanged implements ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(
        public int $ticketId,
        public InternalTicketChange $change,
        /** الرسالة التي قيلت أو عُدّلت أو سُحبت، حين يكون التغيير عن رسالة. */
        public ?int $messageId = null,
        /**
         * صاحبُها قبل التحويل: يخرج من التذكرة ولا يبقى في صفّها ما يُنبئه — فمَن يستمع يحتاج أن
         * يعرف مَن كان، ليُخرجها من بطاقته.
         */
        public ?int $formerOwnerId = null,
    ) {}
}
