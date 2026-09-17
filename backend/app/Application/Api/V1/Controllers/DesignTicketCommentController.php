<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\NarrowsDesignTickets;
use App\Application\Api\V1\Requests\Comment\StoreCommentRequest;
use App\Application\Api\V1\Requests\Comment\UpdateCommentRequest;
use App\Domain\Comment\Models\Comment;
use App\Domain\DesignTicket\Models\DesignTicket;
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
}
