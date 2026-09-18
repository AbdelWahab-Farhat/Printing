<?php

declare(strict_types=1);

namespace App\Domain\Comment\Events;

use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\DesignTicket\Events\DesignTicketProgressed;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * كتب أحدهم ملاحظةً على سجلّ.
 *
 * **حدثٌ واحد لكلِّ ما يُعلَّق عليه، لا حدثٌ لكلِّ نوع.** العميلُ والمورّدُ وتذكرةُ التصميم تشترك
 * في الفعل نفسه — أحدهم كتب شيئاً — وما يختلف هو مَن يعني ذلك، وهذا سؤالُ المستمِع لا سؤالُ
 * الحدث. ولهذا يسافر `commentableType` في الحمولة: المستمِعُ يقرؤه ويصرف عنه ما لا يخصّه، كما
 * يحمل `NotifyWhenOrderStatusChanges` رأيَه في أيِّ الحالات تستحقّ جرساً بدل أن تحمله `Orders`.
 * والملاحظةُ على عميل لا تُنبّه أحداً اليوم، وحين تُنبّه فهي مستمِعٌ ثانٍ لا حدثٌ ثانٍ.
 *
 * **معرِّفات لا نماذج**، مثل {@see DesignTicketProgressed}: المستمِع مُدرَجٌ في الطابور، والنموذجُ
 * المُسلسَل في حمولة مهمّةٍ صورةٌ تَبلى قبل أن تُقرأ.
 *
 * و`commentableType` **اسمٌ مستعار** — `design_ticket` — لا اسمُ صنف، لأنه ما كُتب في العمود
 * أصلاً؛ انظر {@see AuditSubject}.
 */
final readonly class CommentPosted
{
    use Dispatchable;

    public function __construct(
        public int $commentId,
        public string $commentableType,
        public int $commentableId,
        public int $authorId,
    ) {}
}
