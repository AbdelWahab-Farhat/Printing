<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Controllers;

use App\Application\Api\V1\Controllers\Concerns\ReadsAuditTrail;
use App\Application\Api\V1\Requests\Audit\ActivityLogFilterRequest;
use App\Application\Api\V1\Requests\Comment\StoreCommentRequest;
use App\Application\Api\V1\Requests\Comment\UpdateCommentRequest;
use App\Application\Api\V1\Resources\CommentResource;
use App\Application\Controller;
use App\Domain\Audit\AuditService;
use App\Domain\Comment\Contracts\Commentable;
use App\Domain\Comment\Exceptions\CommentBelongsToSomebodyElse;
use App\Domain\Comment\Exceptions\CommentThreadIsClosed;
use App\Domain\Comment\Models\Comment;
use App\Support\ResponseTrait;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The four things done to a note, written once for every kind of record that has them.
 *
 * **Abstract, with a thin subclass per owner, rather than one controller reading the parent out
 * of the route.** Laravel binds a route's parent by its type in the method signature, and that
 * binding is what makes another customer's comment id a 404 by construction. A single controller
 * would have to resolve the owner itself and re-check the pairing by hand — twenty lines saved
 * in exchange for the one guarantee this shape is for.
 *
 * What a subclass says is which model it is about, and nothing else. See
 * {@see CustomerCommentController}, {@see VendorCommentController} and GENERAL-COMMENTS.md.
 */
abstract class CommentController extends Controller
{
    use ReadsAuditTrail, ResponseTrait;

    /**
     * List a record's comments
     *
     * Newest first — a note is read to catch up, so the last thing said is the first thing
     * shown. Not paginated: notes accumulate at the speed of conversation, and the day one
     * record has hundreds is the day this grows a cursor.
     */
    protected function listFor(Commentable $owner): JsonResponse
    {
        $comments = $owner->comments()->with('author')->get();

        // **The owner handed to every row it owns.** Each note's `can_edit` asks its record
        // whether the conversation is still open, and a lazy `->commentable` would ask the
        // database that question once per note for an answer already in hand.
        $comments->each->setRelation('commentable', $owner);

        return $this->successWithMeta(
            CommentResource::collection($comments),
            [
                // **Said once, about the thread rather than about a note.** An empty closed
                // conversation has no row to carry the fact, and the box under the list is
                // exactly what has to know it. `closed_note` is the record's own sentence, so
                // the app prints why instead of inventing a reason.
                'can_comment' => $owner->acceptsComments(),
                'closed_note' => $owner->commentsClosedNote(),
            ],
        );
    }

    /**
     * Leave a comment
     *
     * The author is the signed-in user and is never read from the body: a note is attributed,
     * and attribution nobody can set is attribution nobody can forge.
     */
    protected function storeFor(StoreCommentRequest $request, Commentable $owner): JsonResponse
    {
        $this->refuseUnlessOpen($owner);

        $comment = new Comment($request->validated());
        $comment->commentable()->associate($owner);
        $comment->author()->associate($request->user());
        $comment->save();

        return $this->created(
            new CommentResource($comment->load('author')),
            'تمت إضافة الملاحظة',
        );
    }

    /**
     * Rewrite a comment
     *
     * Its author, or somebody holding `comments.moderate`. Anyone else is refused with 403.
     * Stamps `edited_at`, so a note that changed says so — a sentence that quietly becomes a
     * different sentence is worse than no note at all.
     */
    protected function updateFor(UpdateCommentRequest $request, Comment $comment): JsonResponse
    {
        $this->refuseUnlessOpen($comment->commentable);
        $this->refuseUnlessChangeable($request, $comment);

        $comment->fill($request->validated());

        // Only when the text actually moved. Re-sending the same sentence is not an edit, and
        // stamping it would put «عُدّلت» under a note nobody changed.
        if ($comment->isDirty('body')) {
            $comment->edited_at = now();
        }

        $comment->save();

        return $this->success(
            new CommentResource($comment->load('author')),
            'تم تعديل الملاحظة',
        );
    }

    /**
     * Remove a comment
     *
     * Soft — the row leaves the list and stays in the history, which is what makes «من حذف
     * الملاحظة؟» answerable at all.
     */
    protected function destroyFor(Request $request, Comment $comment): JsonResponse
    {
        $this->refuseUnlessOpen($comment->commentable);
        $this->refuseUnlessChangeable($request, $comment);

        $comment->delete();

        return $this->successMessage('تم حذف الملاحظة');
    }

    /**
     * A comment's history
     *
     * Behind `logs.view` like every other history: reading one shows what everybody has done,
     * which is a different decision from being allowed to read the record.
     */
    protected function logsFor(
        ActivityLogFilterRequest $request,
        Comment $comment,
        AuditService $audit,
    ): JsonResponse {
        return $this->auditTrailResponse($request, $comment, $audit);
    }

    /**
     * The one authorization rule, asked in the one place both write endpoints pass through.
     *
     * The rule itself lives on the model — the resource asks it too, to fill `can_edit` — so
     * there is exactly one sentence in the codebase saying who may change a note.
     */
    private function refuseUnlessChangeable(Request $request, Comment $comment): void
    {
        if (! $comment->isChangeableBy($request->user())) {
            throw CommentBelongsToSomebodyElse::make();
        }
    }

    /**
     * The other rule, and the one that is about the record rather than about the reader.
     *
     * **Asked before who-may-change, on purpose.** A designer rewriting their own sentence under
     * an approved design would otherwise be told they may — and refused for a reason that never
     * applied to them. «انتهت التذكرة» is the true answer, and it is the same answer for
     * everybody, moderator included.
     *
     * A note whose record could not be loaded is left alone: a missing owner is a broken row, and
     * refusing every write on it would make it unfixable.
     */
    private function refuseUnlessOpen(?Model $owner): void
    {
        if ($owner instanceof Commentable && ! $owner->acceptsComments()) {
            throw CommentThreadIsClosed::make($owner->commentsClosedNote());
        }
    }
}
