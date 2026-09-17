<?php

declare(strict_types=1);

namespace App\Application\Api\V1\Resources;

use App\Domain\Comment\Contracts\Commentable;
use App\Domain\Comment\Models\Comment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Comment
 */
class CommentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,

            // What it is about, as the short morph name — `customer`, `vendor`. Kept even though
            // every route that serves a note is already nested under its owner: a list handed
            // around without its URL is a list that cannot say what it belongs to.
            'commentable_type' => $this->commentable_type,
            'commentable_id' => $this->commentable_id,

            'body' => $this->body,

            // Who said it, always — a note nobody can be asked about is a rumour. The name is
            // sent alongside the id because every screen showing a note shows the name, and an
            // app that has to look one up per row is an app making N requests to render a list.
            'author' => [
                'id' => $this->user_id,
                'name' => $this->author?->name,
            ],

            'created_at' => $this->created_at?->toIso8601String(),

            // Null means «as it was written». What the app puts «عُدّلت» under.
            'edited_at' => $this->edited_at?->toIso8601String(),

            // **The authorization rule, decided here and read there.** «صاحبه أو مشرف» is
            // computed per reader and travels with the row, so the app draws the buttons without
            // holding a second copy of a rule that would drift the day it changes. Presentation
            // only: the endpoints refuse the request on their own — see CommentController.
            //
            // **And the record's own state, which outranks it.** A note on a signed-off design
            // ticket is frozen for its author and for a moderator alike, so both flags go false
            // together the moment the conversation ends.
            'can_edit' => $this->isChangeable($request),
            'can_delete' => $this->isChangeable($request),
        ];
    }

    /**
     * Whether this reader may still touch this note.
     *
     * The thread first: a closed conversation answers no to everybody, which is what stops the
     * app drawing a button that can only ever meet {@see CommentThreadIsClosed}. The owner is
     * already loaded by the list — see `CommentController::listFor()` — so this costs no query.
     */
    private function isChangeable(Request $request): bool
    {
        $owner = $this->resource->commentable;

        if ($owner instanceof Commentable && ! $owner->acceptsComments()) {
            return false;
        }

        return $this->resource->isChangeableBy($request->user());
    }
}
