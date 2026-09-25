<?php

declare(strict_types=1);

namespace App\Domain\Support\Events;

use App\Domain\Support\Enums\TicketChange;
use Illuminate\Contracts\Events\ShouldDispatchAfterCommit;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * تغيّرت تذكرة.
 *
 * **حدثٌ واحد لكل تغيير، والبثُّ الحيّ مستمعه اليوم.** سياقُ Support لا يعرف أن هناك مقابس ولا
 * تطبيقين: يقول ما حدث، وطبقةُ النقل تقرّر من يسمع وبأيّ شكل. استيرادُ البثّ من هنا كان سيجعل
 * المجالَ يعرف طبقةَ النقل — الاتجاه الذي تمنعه RULES.md §٣.
 *
 * **بعد الالتزام، لا داخل المعاملة.** رسالةٌ تُبثّ ثم تتراجع معاملتها رسالةٌ رآها الطرفُ الآخر ولم
 * تُكتب قط، ولا سبيل إلى سحبها من شاشته.
 *
 * يحمل أرقاماً لا نماذج: المستمع يقرأ التذكرة كما هي ساعةَ يبثّ، بعد أن استقرّت.
 */
final readonly class TicketChanged implements ShouldDispatchAfterCommit
{
    use Dispatchable;

    public function __construct(
        public int $ticketId,
        public TicketChange $change,
        /** الرسالة التي قيلت، حين يكون التغيير رسالة. */
        public ?int $messageId = null,
    ) {}
}
