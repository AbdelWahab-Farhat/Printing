<?php

declare(strict_types=1);

namespace App\Domain\Comment\Concerns;

use App\Domain\Comment\Contracts\Commentable;
use App\Domain\Comment\Models\Comment;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\MorphMany;

/**
 * A record staff may leave notes on.
 *
 * One line on a model is the whole cost of joining in — which is the point of having generalised
 * the table at all. Today: the customer, the supplier and the design ticket. An order or a
 * purchase order is a `use` and two routes away, and deliberately not added before a screen
 * wants it.
 *
 * **What it provides is the open answer to all three of {@see Commentable}'s questions**, because
 * that is what most records are: a customer is never finished, so their notes never are either. A
 * record that ends overrides {@see acceptsComments()} and says why — see `DesignTicket`.
 *
 * @phpstan-require-extends Model
 *
 * @phpstan-require-implements Commentable
 */
trait HasComments
{
    /**
     * What staff have written to each other about this record.
     *
     * Newest first, and by `id` rather than `created_at`: two notes typed in the same second
     * would otherwise come back in whichever order the database felt like, and the list is read
     * top-down as a conversation.
     *
     * @return MorphMany<Comment, $this>
     */
    public function comments(): MorphMany
    {
        return $this->morphMany(Comment::class, 'commentable')->latest('id');
    }

    /**
     * Open, which is the answer for every record that does not end.
     *
     * Overriding this is what closes a thread: the controller refuses every write against it and
     * the resource stops drawing the buttons, without either of them naming a kind of record.
     */
    public function acceptsComments(): bool
    {
        return true;
    }

    public function commentsClosedNote(): ?string
    {
        return null;
    }
}
