<?php

declare(strict_types=1);

namespace App\Domain\Notification\Audience;

/**
 * The shapes {@see NotificationAudience} comes in.
 *
 * Its own enum rather than class constants, so {@see ResolveRecipients} can `match` on it and
 * the compiler complains the day a shape is added and left unresolved — which is exactly what
 * should happen when `InvestorFor` eventually lands.
 *
 * Not persisted anywhere: an audience is resolved at publish time and only its *result* is
 * stored, as rows in `notification_recipients`. So these values are free to change.
 */
enum AudienceKind
{
    case Permission;
    case User;

    /**
     * أكثرُ من شخصٍ بأعيانهم، لا صفةٌ تجمعهم.
     *
     * **ليست `User` مكرّرةً مرّتين.** الطرفان في محادثةٍ واحدة خبرٌ واحد، وصفُّ بريدٍ لكلِّ طرف
     * يعني صفَّين في `notifications` عن تعليقٍ واحد — ومفتاحَي منعِ تكرارٍ لا يمنعان شيئاً.
     * انظر `DesignTicketCommentPosted`.
     */
    case Users;
    case Role;
    case Everyone;
}
