<?php

declare(strict_types=1);

namespace App\Domain\Comment\Exceptions;

use App\Domain\Comment\Contracts\Commentable;
use App\Support\Exceptions\DomainException;

/**
 * كُتب شيءٌ على محادثةٍ انتهت.
 *
 * **والسجلّ هو الذي يقول لماذا، لا هذا الصنف.** «مغلقة» وحدها تترك المصمّم يتساءل هل وصلت رسالته
 * الأخيرة؛ و«اعتُمد التصميم وأُغلقت المحادثة» تقول ما حدث وأنّ شيئاً لم يضع. والجملة تأتي من
 * {@see Commentable::commentsClosedNote()}، فنوعٌ ثانٍ من السجلات ينتهي يجلب كلماته بدل أن يرث
 * كلمات التذكرة.
 *
 * و422 لا 403: لم يُرفض أحدٌ لِمن هو. والمشرفُ الذي يملك كلّ صلاحيةٍ في النظام يلقى هذه أيضاً —
 * فالمُعلَن هنا حالُ السجلّ.
 */
final class CommentThreadIsClosed extends DomainException
{
    public static function make(?string $because): self
    {
        return new self($because ?? 'أُغلقت المحادثة على هذا السجل');
    }
}
