<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\NarrowsDesignTickets;
use App\Application\Api\V1\Requests\Comment\StoreCommentRequest;
use App\Application\Api\V1\Requests\Comment\UpdateCommentRequest;
use App\Domain\Audit\Enums\AuditSubject;
use App\Domain\Comment\Models\Comment;
use App\Domain\DesignTicket\Models\DesignTicket;
use App\Domain\Notification\Enums\NotificationType;
use App\Domain\Notification\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Design ticket comments
 *
 * «الرد داخل التذكرة» — the conversation between the employee who asked and the designer doing
 * the work, kept beside the versions rather than in WhatsApp where nobody can find it afterwards.
 *
 * The whole implementation is the parent's, and this class names the model it is about. That is
 * the third owner {@see CommentController} has taken without a line of its own logic — which is
 * what generalising `commentable_type` bought.
 *
 * **Anybody who may read a ticket may write on it**, and may edit their own words; rewriting
 * somebody else's needs `comments.moderate`, one permission for every kind of note in the system.
 *
 * The route binds `{ticket}` by type, so a comment id belonging to another ticket is a 404 by
 * construction rather than by a check somebody has to remember — the reason this controller is
 * shaped as a thin subclass instead of one class reading its parent out of the route.
 *
 * **Every method narrows to the ticket first, and that is not optional here.** The route's own
 * `can:design_tickets.view` is a grant, not a scope: without the second check a designer holding
 * it could read the conversation on a colleague's ticket by guessing an id, which is the same
 * back door the ticket's own detail route closes with a 404. This is the one owner of
 * {@see CommentController} whose parent is not visible to everybody who may read *some* of them,
 * so it is the one that has to say so.
 */
class DesignTicketCommentController extends CommentController
{
    use NarrowsDesignTickets;

    public function index(Request $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        return $this->listFor($ticket);
    }

    public function store(StoreCommentRequest $request, DesignTicket $ticket): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        return $this->storeFor($request, $ticket);
    }

    public function update(
        UpdateCommentRequest $request,
        DesignTicket $ticket,
        Comment $comment,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        return $this->updateFor($request, $comment);
    }

    public function destroy(Request $request, DesignTicket $ticket, Comment $comment): JsonResponse
    {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        return $this->destroyFor($request, $comment);
    }

    /**
     * Mark this conversation as read
     *
     * Called when the app opens the thread. Clears this reader's unread badge on the ticket —
     * and, because they are the same rows, the matching entries behind the bell.
     *
     * Idempotent, and an empty conversation answers the same as a full one.
     *
     * **مَن قرأ الردودَ في مكانها قرأها.** والشارةُ وصفوفُ الجرس شيءٌ واحد — كلُّ تعليقٍ صفُّ
     * إشعارٍ واحد، و`read_at` فيه لكلِّ شخصٍ على حدة — فإبقاءُ الخبر في الجرس بعد قراءة المحادثة
     * يجعل الرقمَ فوق الجرس كذبةً صغيرةً تتكرّر.
     *
     * **يُحقن `NotificationService` في التابع لا في الباني**، لأن هذا التابع وحده يحتاجه من بين
     * الخمسة: وباني الأب يخدم ثلاثة متحكّمات لا شأن لاثنين منها بالإشعارات.
     *
     * ويُعاد العدُّ الكلّيّ للجرس مع الجواب، فيصحّح التطبيق الشارتين بذهابٍ واحد بدل أن يسأل
     * `notifications/unread-count` مرّةً ثانية بعد كلِّ فتحِ محادثة.
     */
    public function markThreadAsRead(
        Request $request,
        DesignTicket $ticket,
        NotificationService $notifications,
    ): JsonResponse {
        $this->refuseUnlessVisibleTicket($request, $ticket);

        $readerId = (int) $request->user()->getKey();

        $notifications->markSubjectAsRead(
            AuditSubject::DesignTicket->value,
            (int) $ticket->getKey(),
            $readerId,
            NotificationType::DesignTicketComment,
        );

        return $this->success([
            'unread_comments_count' => 0,
            'unread_total' => $notifications->unreadCountFor($readerId),
        ]);
    }
}
